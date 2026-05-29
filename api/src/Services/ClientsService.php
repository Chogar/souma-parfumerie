<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;
use PDO;

final class ClientsService
{
    private const GIFT_THRESHOLD = 10;

    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::connection();
    }

    /** @return list<array<string, mixed>> */
    public function list(?string $search = null, int $limit = 200): array
    {
        $sql = 'SELECT * FROM clients WHERE 1=1';
        $params = [];

        if ($search !== null && trim($search) !== '') {
            $sql .= ' AND (phone ILIKE :q OR name ILIKE :q)';
            $params['q'] = '%' . trim($search) . '%';
        }

        $sql .= ' ORDER BY loyalty_points DESC, updated_at DESC LIMIT :limit';

        $stmt = $this->pdo->prepare($sql);
        foreach ($params as $key => $value) {
            $stmt->bindValue($key, $value);
        }
        $stmt->bindValue('limit', $limit, PDO::PARAM_INT);
        $stmt->execute();

        $rows = $stmt->fetchAll();
        foreach ($rows as &$row) {
            $row['gift_threshold'] = self::GIFT_THRESHOLD;
            $row['gift_eligible'] = ((int) ($row['loyalty_points'] ?? 0)) >= self::GIFT_THRESHOLD;
        }

        return $rows;
    }

    /** @return array<string, mixed>|null */
    public function detail(string $clientId): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM clients WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => $clientId]);
        $client = $stmt->fetch();

        if ($client === false) {
            return null;
        }

        $client['gift_threshold'] = self::GIFT_THRESHOLD;
        $client['gift_eligible'] = ((int) ($client['loyalty_points'] ?? 0)) >= self::GIFT_THRESHOLD;

        $salesStmt = $this->pdo->prepare(
            'SELECT s.id, s.invoice_number, s.total, s.sold_at, s.payment_method
             FROM sales s
             WHERE s.client_id = :id AND s.status = \'completed\'
             ORDER BY s.sold_at DESC
             LIMIT 20'
        );
        $salesStmt->execute(['id' => $clientId]);

        return [
            'client' => $client,
            'recent_sales' => $salesStmt->fetchAll(),
        ];
    }
}
