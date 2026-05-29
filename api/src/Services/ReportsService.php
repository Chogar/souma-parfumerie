<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;
use PDO;

final class ReportsService
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::connection();
    }

    /**
     * @return array{from: string, to_end: string, to_day: string}
     */
    public function dateRange(string $from, string $to): array
    {
        $fromDt = new \DateTimeImmutable($from);
        $toDt = new \DateTimeImmutable($to);

        return [
            'from' => $fromDt->format('Y-m-d 00:00:00'),
            'to_end' => $toDt->modify('+1 day')->format('Y-m-d 00:00:00'),
            'to_day' => $toDt->format('Y-m-d'),
        ];
    }

    /** @return array<string, mixed> */
    public function fullReport(string $from, string $to): array
    {
        $range = $this->dateRange($from, $to);

        return [
            'period' => ['from' => $from, 'to' => $to],
            'summary' => $this->periodSummary($range),
            'profit' => $this->estimatedProfit($range),
            'comparison' => $this->previousPeriodComparison($from, $to),
            'top_products' => $this->topProducts($range, 10),
            'revenue_by_day' => $this->revenueByDay($range),
            'sales_by_category' => $this->salesByCategory($range),
            'sales_by_cashier' => $this->salesByCashier($range),
            'payment_breakdown' => $this->paymentBreakdown($range),
            'monthly_revenue' => $this->monthlyRevenue(12),
            'expenses' => $this->expensesPeriod($range),
            'returns' => $this->returnPeriodSummary($range),
        ];
    }

    /** @return array<string, mixed> */
    public function yearlyReport(int $year): array
    {
        $from = sprintf('%d-01-01', $year);
        $to = sprintf('%d-12-31', $year);
        $range = $this->dateRange($from, $to);

        return [
            'year' => $year,
            'summary' => $this->yearSummary($year),
            'comparison' => $this->yearOverYearComparison($year),
            'monthly_breakdown' => $this->monthlyBreakdownForYear($year),
            'top_products' => $this->topProducts($range, 15),
            'profit' => $this->estimatedProfit($range),
            'expenses' => $this->expensesPeriod($range),
            'payment_breakdown' => $this->paymentBreakdown($range),
        ];
    }

    /** @param array{from: string, to_end: string} $range
     *  @return array<string, mixed> */
    private function periodSummary(array $range): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM(total), 0) AS revenue,
                    COUNT(*) AS transactions,
                    COALESCE(AVG(total), 0) AS avg_basket,
                    COALESCE(SUM(discount_amount), 0) AS total_discounts
             FROM sales s
             WHERE status = \'completed\'
               AND sold_at >= :from
               AND sold_at < :to_end'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);

        return $stmt->fetch() ?: [];
    }

    /** @param array{from: string, to_end: string} $range */
    private function estimatedProfit(array $range): float
    {
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM((sl.unit_price - p.purchase_price) * sl.quantity), 0) AS profit
             FROM sale_lines sl
             JOIN sales s ON s.id = sl.sale_id
             JOIN products p ON p.id = sl.product_id
             WHERE s.status = \'completed\'
               AND s.sold_at >= :from
               AND s.sold_at < :to_end'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);
        $row = $stmt->fetch();

        return (float) ($row['profit'] ?? 0);
    }

    /** @return array<string, mixed> */
    private function previousPeriodComparison(string $from, string $to): array
    {
        $fromDt = new \DateTimeImmutable($from);
        $toDt = new \DateTimeImmutable($to);
        $days = $toDt->diff($fromDt)->days + 1;
        $prevTo = $fromDt->modify('-1 day');
        $prevFrom = $prevTo->modify('-' . ($days - 1) . ' days');

        $currentRange = $this->dateRange($from, $to);
        $prevRange = $this->dateRange(
            $prevFrom->format('Y-m-d'),
            $prevTo->format('Y-m-d')
        );

        return [
            'current' => $this->periodSummary($currentRange),
            'previous' => $this->periodSummary($prevRange),
            'days' => $days,
        ];
    }

    /** @param array{from: string, to_end: string} $range
     *  @return list<array<string, mixed>> */
    private function topProducts(array $range, int $limit): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT p.name_fr, p.name_ar, p.barcode,
                    c.name_fr AS category_fr, c.name_ar AS category_ar,
                    SUM(sl.quantity) AS qty_sold,
                    SUM(sl.line_total) AS revenue,
                    COUNT(DISTINCT s.id) AS sale_count
             FROM sale_lines sl
             JOIN sales s ON s.id = sl.sale_id
             JOIN products p ON p.id = sl.product_id
             JOIN categories c ON c.id = p.category_id
             WHERE s.status = \'completed\'
               AND s.sold_at >= :from
               AND s.sold_at < :to_end
             GROUP BY p.id, p.name_fr, p.name_ar, p.barcode, c.name_fr, c.name_ar
             ORDER BY qty_sold DESC
             LIMIT :limit'
        );
        $stmt->bindValue('from', $range['from']);
        $stmt->bindValue('to_end', $range['to_end']);
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /** @param array{from: string, to_end: string} $range
     *  @return list<array<string, mixed>> */
    private function revenueByDay(array $range): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT sold_at::date AS day,
                    SUM(total) AS revenue,
                    COUNT(*) AS transactions
             FROM sales s
             WHERE status = \'completed\'
               AND sold_at >= :from
               AND sold_at < :to_end
             GROUP BY 1
             ORDER BY 1 ASC'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);

        return $stmt->fetchAll();
    }

    /** @param array{from: string, to_end: string} $range
     *  @return list<array<string, mixed>> */
    private function salesByCategory(array $range): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT c.name_fr, c.name_ar,
                    SUM(sl.line_total) AS revenue,
                    SUM(sl.quantity) AS qty
             FROM sale_lines sl
             JOIN sales s ON s.id = sl.sale_id
             JOIN products p ON p.id = sl.product_id
             JOIN categories c ON c.id = p.category_id
             WHERE s.status = \'completed\'
               AND s.sold_at >= :from
               AND s.sold_at < :to_end
             GROUP BY c.id, c.name_fr, c.name_ar
             ORDER BY revenue DESC'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);

        return $stmt->fetchAll();
    }

    /** @param array{from: string, to_end: string} $range
     *  @return list<array<string, mixed>> */
    private function salesByCashier(array $range): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT u.full_name AS cashier_name,
                    COUNT(*) AS transactions,
                    COALESCE(SUM(s.total), 0) AS revenue
             FROM sales s
             JOIN users u ON u.id = s.user_id
             WHERE s.status = \'completed\'
               AND s.sold_at >= :from
               AND s.sold_at < :to_end
             GROUP BY u.id, u.full_name
             ORDER BY revenue DESC'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);

        return $stmt->fetchAll();
    }

    /** @param array{from: string, to_end: string} $range
     *  @return list<array<string, mixed>> */
    private function paymentBreakdown(array $range): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT payment_method,
                    COUNT(*) AS transactions,
                    COALESCE(SUM(total), 0) AS total
             FROM sales s
             WHERE status = \'completed\'
               AND sold_at >= :from
               AND sold_at < :to_end
             GROUP BY payment_method
             ORDER BY total DESC'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);

        return $stmt->fetchAll();
    }

    /** @return list<array<string, mixed>> */
    private function monthlyRevenue(int $months): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT DATE_TRUNC(\'month\', sold_at) AS month,
                    SUM(total) AS revenue,
                    COUNT(*) AS transactions
             FROM sales s
             WHERE status = \'completed\'
               AND sold_at >= DATE_TRUNC(\'month\', CURRENT_DATE)
                   - (:months || \' months\')::interval
             GROUP BY 1
             ORDER BY 1 ASC'
        );
        $stmt->bindValue('months', $months, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /** @param array{from: string, to_end: string, to_day: string} $range
     *  @return array<string, mixed> */
    private function expensesPeriod(array $range): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT COALESCE(SUM(amount), 0) AS total, COUNT(*) AS count
             FROM expenses
             WHERE expense_date >= :from::date
               AND expense_date <= :to_day::date'
        );
        $stmt->execute(['from' => $range['from'], 'to_day' => $range['to_day']]);
        $row = $stmt->fetch();

        return $row ?: ['total' => 0, 'count' => 0];
    }

    /** @param array{from: string, to_end: string} $range
     *  @return array<string, mixed> */
    private function returnPeriodSummary(array $range): array
    {
        if (!$this->returnColumnsReady()) {
            return [
                'requested' => 0,
                'pending' => 0,
                'approved' => 0,
                'rejected' => 0,
                'approved_amount' => 0,
            ];
        }

        $stmt = $this->pdo->prepare(
            'SELECT
               COUNT(*) FILTER (WHERE return_status IS NOT NULL
                 AND return_requested_at >= :from
                 AND return_requested_at < :to_end)::int AS requested,
               COUNT(*) FILTER (WHERE return_status = \'pending\'
                 AND return_requested_at >= :from
                 AND return_requested_at < :to_end)::int AS pending,
               COUNT(*) FILTER (WHERE return_status = \'approved\'
                 AND return_approved_at >= :from
                 AND return_approved_at < :to_end)::int AS approved,
               COUNT(*) FILTER (WHERE return_status = \'rejected\'
                 AND return_approved_at >= :from
                 AND return_approved_at < :to_end)::int AS rejected,
               COALESCE(SUM(total) FILTER (WHERE return_status = \'approved\'
                 AND return_approved_at >= :from
                 AND return_approved_at < :to_end), 0) AS approved_amount
             FROM sales s
             WHERE return_status IS NOT NULL'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);
        $row = $stmt->fetch();

        return $row ?: [
            'requested' => 0,
            'pending' => 0,
            'approved' => 0,
            'rejected' => 0,
            'approved_amount' => 0,
        ];
    }

    /** @return list<array<string, mixed>> */
    private function monthlyBreakdownForYear(int $year): array
    {
        $range = $this->dateRange(sprintf('%d-01-01', $year), sprintf('%d-12-31', $year));
        $stmt = $this->pdo->prepare(
            'SELECT DATE_TRUNC(\'month\', sold_at) AS month,
                    COALESCE(SUM(total), 0) AS revenue,
                    COUNT(*) AS transactions,
                    COALESCE(AVG(total), 0) AS avg_basket,
                    COALESCE(SUM(discount_amount), 0) AS total_discounts
             FROM sales s
             WHERE status = \'completed\'
               AND sold_at >= :from
               AND sold_at < :to_end
             GROUP BY 1
             ORDER BY 1 ASC'
        );
        $stmt->execute(['from' => $range['from'], 'to_end' => $range['to_end']]);

        return $stmt->fetchAll();
    }

    /** @return array<string, mixed> */
    private function yearSummary(int $year): array
    {
        return $this->periodSummary(
            $this->dateRange(sprintf('%d-01-01', $year), sprintf('%d-12-31', $year))
        );
    }

    /** @return array<string, mixed> */
    private function yearOverYearComparison(int $year): array
    {
        return [
            'current' => $this->yearSummary($year),
            'previous' => $this->yearSummary($year - 1),
            'year' => $year,
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

    /** @return list<array<string, mixed>> */
    public function lowStock(int $limit = 20): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT p.id, p.barcode, p.name_fr, p.name_ar, p.min_stock_level,
                    COALESCE(sl.quantity, 0) AS quantity,
                    sup.name AS supplier_name
             FROM products p
             LEFT JOIN stock_levels sl ON sl.product_id = p.id
             LEFT JOIN suppliers sup ON sup.id = p.supplier_id
             WHERE p.is_active = TRUE
               AND COALESCE(sl.quantity, 0) <= p.min_stock_level
             ORDER BY quantity ASC, p.name_fr ASC
             LIMIT :limit'
        );
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }
}
