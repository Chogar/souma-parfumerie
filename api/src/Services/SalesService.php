<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;
use PDO;

final class SalesService
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::connection();
    }

    /** @return list<array<string, mixed>> */
    public function listSales(?string $from, ?string $to, int $limit = 100): array
    {
        $sql = '
            SELECT s.*, u.full_name AS cashier_name,
                   c.phone AS client_phone, c.name AS client_name
            FROM sales s
            JOIN users u ON u.id = s.user_id
            LEFT JOIN clients c ON c.id = s.client_id
            WHERE s.status = \'completed\'';

        $params = [];

        if ($this->returnColumnsReady()) {
            $sql .= ' AND (s.return_status IS NULL OR s.return_status IN (\'rejected\', \'pending\'))';
        }

        if ($from !== null && $from !== '') {
            $sql .= ' AND s.sold_at >= :from';
            $params['from'] = $from . ' 00:00:00';
        }
        if ($to !== null && $to !== '') {
            $sql .= ' AND s.sold_at <= :to';
            $params['to'] = $to . ' 23:59:59';
        }

        $sql .= ' ORDER BY s.sold_at DESC LIMIT :limit';

        $stmt = $this->pdo->prepare($sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /** @return array<string, mixed>|null */
    public function getSaleDetail(string $saleId): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT s.*, u.full_name AS cashier_name,
                    c.phone AS client_phone, c.name AS client_name,
                    c.loyalty_points AS client_loyalty_points
             FROM sales s
             JOIN users u ON u.id = s.user_id
             LEFT JOIN clients c ON c.id = s.client_id
             WHERE s.id = :id
             LIMIT 1'
        );
        $stmt->execute(['id' => $saleId]);
        $sale = $stmt->fetch();

        if ($sale === false) {
            return null;
        }

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
            'lines' => $linesStmt->fetchAll(),
        ];
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
}
