<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;
use PDO;
use PDOException;

final class ReturnsService
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::connection();
    }

    /** @return list<array<string, mixed>> */
    public function listPending(): array
    {
        $this->ensureColumns();

        $stmt = $this->pdo->query(
            'SELECT s.*, u.full_name AS cashier_name,
                    ru.full_name AS return_requester_name,
                    c.phone AS client_phone, c.name AS client_name
             FROM sales s
             JOIN users u ON u.id = s.user_id
             LEFT JOIN users ru ON ru.id = s.return_requested_by
             LEFT JOIN clients c ON c.id = s.client_id
             WHERE s.return_status = \'pending\'
             ORDER BY s.return_requested_at ASC'
        );

        return $stmt ? $stmt->fetchAll() : [];
    }

    /** @return array<string, mixed>|null */
    public function getDetail(string $saleId): ?array
    {
        $this->ensureColumns();

        $stmt = $this->pdo->prepare(
            'SELECT s.*, u.full_name AS cashier_name,
                    ru.full_name AS return_requester_name,
                    c.phone AS client_phone, c.name AS client_name
             FROM sales s
             JOIN users u ON u.id = s.user_id
             LEFT JOIN users ru ON ru.id = s.return_requested_by
             LEFT JOIN clients c ON c.id = s.client_id
             WHERE s.id = :id AND s.return_status IS NOT NULL
             LIMIT 1'
        );
        $stmt->execute(['id' => $saleId]);
        $sale = $stmt->fetch();

        if ($sale === false) {
            return null;
        }

        $returnLines = $this->pendingReturnLineItems($saleId);

        $linesStmt = $this->pdo->prepare(
            'SELECT sl.id, sl.product_id, sl.quantity, sl.unit_price, sl.line_total,
                    p.name_fr, p.name_ar, p.barcode
             FROM sale_lines sl
             JOIN products p ON p.id = sl.product_id
             WHERE sl.sale_id = :id
             ORDER BY sl.id'
        );
        $linesStmt->execute(['id' => $saleId]);

        return [
            'sale' => $sale,
            'return_lines' => $returnLines,
            'all_lines' => $linesStmt->fetchAll(),
        ];
    }

    public function approve(string $saleId, string $managerId): void
    {
        $this->ensureColumns();
        $hasReturnLinesTable = $this->returnLinesTableReady();

        $this->pdo->beginTransaction();

        try {
            $stmt = $this->pdo->prepare(
                'SELECT id, user_id, client_id, invoice_number, return_status, status
                 FROM sales WHERE id = :id FOR UPDATE'
            );
            $stmt->execute(['id' => $saleId]);
            $sale = $stmt->fetch();

            if ($sale === false) {
                throw new \RuntimeException('SALE_NOT_FOUND');
            }
            if ($sale['return_status'] !== 'pending') {
                throw new \RuntimeException('RETURN_NOT_PENDING');
            }

            $returnItems = $this->loadReturnItemsForApproval($saleId, $hasReturnLinesTable);
            $totalReturned = 0;

            foreach ($returnItems as $item) {
                $qty = (int) $item['quantity_to_return'];
                $totalReturned += $qty;
                $productId = $item['product_id'];

                $movementId = UuidHelper::v4();
                $this->pdo->prepare(
                    'INSERT INTO stock_movements (
                        id, product_id, movement_type, quantity_delta,
                        reference_type, reference_id, user_id, note, is_synced
                     ) VALUES (
                        :id, :product_id, \'return\', :delta,
                        \'sale_return\', :sale_id, :user_id, :note, FALSE
                     )'
                )->execute([
                    'id' => $movementId,
                    'product_id' => $productId,
                    'delta' => $qty,
                    'sale_id' => $saleId,
                    'user_id' => $managerId,
                    'note' => 'Retour ' . $sale['invoice_number'],
                ]);

                $updated = $this->pdo->prepare(
                    'UPDATE stock_levels SET
                        quantity = quantity + :add,
                        updated_at = NOW(),
                        is_synced = FALSE
                     WHERE product_id = :product_id'
                );
                $updated->execute(['product_id' => $productId, 'add' => $qty]);

                if ($updated->rowCount() === 0) {
                    $this->pdo->prepare(
                        'INSERT INTO stock_levels (id, product_id, quantity, is_synced)
                         VALUES (:id, :product_id, :qty, FALSE)'
                    )->execute([
                        'id' => UuidHelper::v4(),
                        'product_id' => $productId,
                        'qty' => $qty,
                    ]);
                }
            }

            $lineStmt = $this->pdo->prepare(
                'SELECT quantity FROM sale_lines WHERE sale_id = :id'
            );
            $lineStmt->execute(['id' => $saleId]);
            $saleTotalQty = 0;
            foreach ($lineStmt->fetchAll() as $line) {
                $saleTotalQty += (int) $line['quantity'];
            }
            $fullReturn = $totalReturned >= $saleTotalQty;

            $clientId = $sale['client_id'] ?? null;
            if ($clientId) {
                $this->pdo->prepare(
                    'UPDATE clients SET
                        loyalty_points = GREATEST(0, loyalty_points - 1),
                        updated_at = NOW(),
                        is_synced = FALSE
                     WHERE id = :client_id::uuid AND loyalty_points > 0'
                )->execute(['client_id' => $clientId]);
            }

            $newStatus = $fullReturn ? 'returned' : 'completed';

            $this->pdo->prepare(
                'UPDATE sales SET
                    status = :status,
                    return_status = \'approved\',
                    return_approved_by = :manager,
                    return_approved_at = NOW(),
                    is_synced = FALSE,
                    updated_at = NOW()
                 WHERE id = :id'
            )->execute([
                'id' => $saleId,
                'manager' => $managerId,
                'status' => $newStatus,
            ]);

            $this->pdo->commit();
        } catch (\Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    public function reject(string $saleId, string $managerId): void
    {
        $this->ensureColumns();

        $stmt = $this->pdo->prepare(
            'SELECT return_status FROM sales WHERE id = :id'
        );
        $stmt->execute(['id' => $saleId]);
        $row = $stmt->fetch();

        if ($row === false) {
            throw new \RuntimeException('SALE_NOT_FOUND');
        }
        if ($row['return_status'] !== 'pending') {
            throw new \RuntimeException('RETURN_NOT_PENDING');
        }

        $this->pdo->beginTransaction();

        try {
            if ($this->returnLinesTableReady()) {
                $this->pdo->prepare(
                    'DELETE FROM sale_return_line_items WHERE sale_id = :id'
                )->execute(['id' => $saleId]);
            }

            $this->pdo->prepare(
                'UPDATE sales SET
                    return_status = \'rejected\',
                    return_approved_by = :manager,
                    return_approved_at = NOW(),
                    is_synced = FALSE,
                    updated_at = NOW()
                 WHERE id = :id'
            )->execute(['id' => $saleId, 'manager' => $managerId]);

            $this->pdo->commit();
        } catch (\Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    /** @return list<array<string, mixed>> */
    private function pendingReturnLineItems(string $saleId): array
    {
        if (!$this->returnLinesTableReady()) {
            return [];
        }

        $stmt = $this->pdo->prepare(
            'SELECT sri.*, p.name_fr, p.name_ar
             FROM sale_return_line_items sri
             JOIN products p ON p.id = sri.product_id
             WHERE sri.sale_id = :sale_id
             ORDER BY sri.sale_line_id'
        );
        $stmt->execute(['sale_id' => $saleId]);

        return $stmt->fetchAll();
    }

    /** @return list<array<string, mixed>> */
    private function loadReturnItemsForApproval(string $saleId, bool $hasReturnLinesTable): array
    {
        if ($hasReturnLinesTable) {
            $stmt = $this->pdo->prepare(
                'SELECT product_id, quantity_sold, quantity_to_return
                 FROM sale_return_line_items
                 WHERE sale_id = :id'
            );
            $stmt->execute(['id' => $saleId]);
            $rows = $stmt->fetchAll();

            if ($rows !== []) {
                return array_map(static fn (array $m) => [
                    'product_id' => $m['product_id'],
                    'quantity_sold' => (int) $m['quantity_sold'],
                    'quantity_to_return' => (int) $m['quantity_to_return'],
                ], $rows);
            }
        }

        $stmt = $this->pdo->prepare(
            'SELECT product_id, quantity AS quantity_sold, quantity AS quantity_to_return
             FROM sale_lines WHERE sale_id = :id'
        );
        $stmt->execute(['id' => $saleId]);

        return array_map(static function (array $m) {
            $q = (int) $m['quantity_sold'];

            return [
                'product_id' => $m['product_id'],
                'quantity_sold' => $q,
                'quantity_to_return' => $q,
            ];
        }, $stmt->fetchAll());
    }

    private function ensureColumns(): void
    {
        if (!$this->returnColumnsReady()) {
            throw new PDOException('RETURN_MIGRATION_REQUIRED');
        }
    }

    private function returnColumnsReady(): bool
    {
        $stmt = $this->pdo->query(
            "SELECT 1 FROM information_schema.columns
             WHERE table_name = 'sales' AND column_name = 'return_status'
             LIMIT 1"
        );

        return $stmt !== false && $stmt->fetch() !== false;
    }

    private function returnLinesTableReady(): bool
    {
        $stmt = $this->pdo->query(
            "SELECT 1 FROM information_schema.tables
             WHERE table_name = 'sale_return_line_items'
             LIMIT 1"
        );

        return $stmt !== false && $stmt->fetch() !== false;
    }
}
