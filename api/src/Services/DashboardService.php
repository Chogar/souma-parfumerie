<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;
use PDO;

final class DashboardService
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::connection();
    }

    /** @return array<string, mixed> */
    public function todayStats(): array
    {
        $row = $this->fetchOne(
            'SELECT COUNT(*) AS transactions,
                    COALESCE(SUM(sl.quantity), 0) AS items_sold
             FROM sales s
             LEFT JOIN sale_lines sl ON sl.sale_id = s.id
             WHERE s.status = \'completed\' AND s.sold_at::date = CURRENT_DATE'
        );

        $fin = $this->fetchOne(
            'SELECT COALESCE(SUM(total), 0) AS revenue,
                    COALESCE(AVG(total), 0) AS avg_basket
             FROM sales s
             WHERE status = \'completed\' AND sold_at::date = CURRENT_DATE'
        );

        return array_merge($row ?? [], $fin ?? []);
    }

    public function lowStockCount(): int
    {
        $row = $this->fetchOne(
            'SELECT COUNT(*) AS c
             FROM products p
             JOIN stock_levels s ON s.product_id = p.id
             WHERE p.is_active = TRUE AND s.quantity <= p.min_stock_level'
        );

        return (int) ($row['c'] ?? 0);
    }

    /** @return list<array<string, mixed>> */
    public function recentSales(int $limit = 10, bool $todayOnly = false): array
    {
        $dayClause = $todayOnly ? ' AND s.sold_at::date = CURRENT_DATE' : '';

        $stmt = $this->pdo->prepare(
            "SELECT s.id, s.invoice_number, s.total, s.sold_at, s.payment_method, u.full_name
             FROM sales s
             JOIN users u ON u.id = s.user_id
             WHERE s.status = 'completed'
             {$dayClause}
             ORDER BY s.sold_at DESC
             LIMIT :limit"
        );
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    public function pendingReturnsCount(): int
    {
        if (!$this->returnColumnsReady()) {
            return 0;
        }

        $row = $this->fetchOne(
            'SELECT COUNT(*)::int AS c FROM sales WHERE return_status = \'pending\''
        );

        return (int) ($row['c'] ?? 0);
    }

    /** @return array<string, mixed> */
    public function returnDailySummary(): array
    {
        if (!$this->returnColumnsReady()) {
            return ['returns_today' => 0, 'approved_today' => 0, 'rejected_today' => 0];
        }

        $row = $this->fetchOne(
            'SELECT
               COUNT(*) FILTER (WHERE return_requested_at::date = CURRENT_DATE)::int AS returns_today,
               COUNT(*) FILTER (WHERE return_status = \'approved\'
                 AND return_approved_at::date = CURRENT_DATE)::int AS approved_today,
               COUNT(*) FILTER (WHERE return_status = \'rejected\'
                 AND return_approved_at::date = CURRENT_DATE)::int AS rejected_today
             FROM sales s
             WHERE return_status IS NOT NULL'
        );

        return $row ?? ['returns_today' => 0, 'approved_today' => 0, 'rejected_today' => 0];
    }

    private function returnColumnsReady(): bool
    {
        $row = $this->fetchOne(
            "SELECT 1 FROM information_schema.columns
             WHERE table_name = 'sales' AND column_name = 'return_status'
             LIMIT 1"
        );

        return $row !== null;
    }

    /** @return array<string, mixed>|null */
    private function fetchOne(string $sql, array $params = []): ?array
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }
}
