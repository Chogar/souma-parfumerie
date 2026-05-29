<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;
use PDO;

final class AlertsService
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::connection();
    }

    /** @return list<array<string, mixed>> */
    public function lowStock(int $limit = 100): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT p.id, p.barcode, p.name_fr, p.name_ar, p.min_stock_level,
                    COALESCE(s.quantity, 0) AS quantity,
                    p.expires_at
             FROM products p
             LEFT JOIN stock_levels s ON s.product_id = p.id
             WHERE p.is_active = TRUE
               AND COALESCE(s.quantity, 0) <= p.min_stock_level
             ORDER BY quantity ASC, p.name_fr ASC
             LIMIT :limit'
        );
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /** @return list<array<string, mixed>> */
    public function expiringSoon(int $withinDays = 30): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT p.id, p.barcode, p.name_fr, p.name_ar,
                    COALESCE(s.quantity, 0) AS quantity,
                    p.expires_at,
                    (p.expires_at - CURRENT_DATE) AS days_left
             FROM products p
             LEFT JOIN stock_levels s ON s.product_id = p.id
             WHERE p.is_active = TRUE
               AND p.expires_at IS NOT NULL
               AND p.expires_at <= CURRENT_DATE + :days::int
               AND COALESCE(s.quantity, 0) > 0
             ORDER BY p.expires_at ASC
             LIMIT 100'
        );
        $stmt->bindValue('days', $withinDays, PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /** @return array{low_stock: list<array>, expiring: list<array>, counts: array<string, int>} */
    public function summary(): array
    {
        $low = $this->lowStock(100);
        $exp = $this->expiringSoon(30);

        return [
            'low_stock' => $low,
            'expiring' => $exp,
            'counts' => [
                'low_stock' => count($low),
                'expiring' => count($exp),
            ],
        ];
    }
}
