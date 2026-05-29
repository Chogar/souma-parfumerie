<?php

declare(strict_types=1);

namespace Souma\Api\Controllers;

use Souma\Api\Core\Database;
use Souma\Api\Core\Request;
use Souma\Api\Core\Response;
use Souma\Api\Services\AuditService;

final class SyncController
{
    /** Tables cloud → local (priorité cloud) */
    private const PULL_TABLES = ['categories', 'products', 'roles', 'app_settings'];

    /** Tables local → cloud (priorité local) */
    private const PUSH_TABLES = ['sales', 'sale_lines', 'stock_movements', 'clients', 'audit_logs'];

    public function pull(Request $request): Response
    {
        $since = $request->query['since'] ?? null;
        $pdo = Database::connection();
        $data = [];

        foreach (self::PULL_TABLES as $table) {
            $sql = "SELECT * FROM {$table}";
            $params = [];
            if ($since) {
                $sql .= ' WHERE updated_at > :since';
                $params['since'] = $since;
            }
            $sql .= ' ORDER BY updated_at ASC LIMIT 5000';
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);
            $data[$table] = $stmt->fetchAll();
        }

        AuditService::log($request->user['sub'] ?? null, 'sync_pull', 'sync', null, [
            'since' => $since,
            'counts' => array_map('count', $data),
        ]);

        return Response::json([
            'success' => true,
            'pulled_at' => date('c'),
            'data' => $data,
        ]);
    }

    public function push(Request $request): Response
    {
        $payload = $request->body['data'] ?? [];
        if (!is_array($payload)) {
            return Response::json(['success' => false, 'message' => 'Payload invalide'], 422);
        }

        $pdo = Database::connection();
        $pdo->beginTransaction();
        $inserted = [];

        try {
            foreach (self::PUSH_TABLES as $table) {
                $rows = $payload[$table] ?? [];
                if (!is_array($rows)) {
                    continue;
                }
                $count = 0;
                foreach ($rows as $row) {
                    if (!isset($row['id'])) {
                        continue;
                    }
                    $this->upsertRow($pdo, $table, $row);
                    $count++;
                }
                $inserted[$table] = $count;
            }

            if (!empty($payload['stock_movements']) && is_array($payload['stock_movements'])) {
                $this->applyStockDeltas($pdo, $payload['stock_movements']);
            }

            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            return Response::json(['success' => false, 'message' => $e->getMessage()], 500);
        }

        AuditService::log($request->user['sub'] ?? null, 'sync_push', 'sync', null, [
            'inserted' => $inserted,
        ]);

        return Response::json([
            'success' => true,
            'pushed_at' => date('c'),
            'inserted' => $inserted,
        ]);
    }

    public function ack(Request $request): Response
    {
        $ids = $request->body['ids'] ?? [];
        $table = $request->body['table'] ?? '';
        if (!is_array($ids) || $table === '' || !preg_match('/^[a-z_]+$/', $table)) {
            return Response::json(['success' => false, 'message' => 'Paramètres invalides'], 422);
        }

        $pdo = Database::connection();
        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        if ($placeholders === '') {
            return Response::json(['success' => true, 'updated' => 0]);
        }

        $sql = "UPDATE {$table} SET is_synced = TRUE WHERE id IN ($placeholders)";
        $stmt = $pdo->prepare($sql);
        $stmt->execute(array_values($ids));

        return Response::json(['success' => true, 'updated' => $stmt->rowCount()]);
    }

    private function upsertRow(\PDO $pdo, string $table, array $row): void
    {
        $id = $row['id'];
        unset($row['is_synced']);
        $row['is_synced'] = true;

        $check = $pdo->prepare("SELECT id FROM {$table} WHERE id = :id");
        $check->execute(['id' => $id]);
        if ($check->fetch()) {
            if (in_array($table, ['sales', 'sale_lines', 'stock_movements'], true)) {
                return;
            }
        }

        $columns = array_keys($row);
        $cols = implode(', ', $columns);
        $params = ':' . implode(', :', $columns);
        $sql = "INSERT INTO {$table} ({$cols}) VALUES ({$params})
                ON CONFLICT (id) DO NOTHING";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($row);
    }

    /** Sync stock par mouvements différentiels (+X / -X) */
    private function applyStockDeltas(\PDO $pdo, array $movements): void
    {
        foreach ($movements as $m) {
            if (!isset($m['product_id'], $m['quantity_delta'])) {
                continue;
            }
            $pdo->prepare(
                'INSERT INTO stock_levels (id, product_id, quantity, is_synced)
                 VALUES (uuid_generate_v4(), :pid, :qty, TRUE)
                 ON CONFLICT (product_id)
                 DO UPDATE SET
                   quantity = stock_levels.quantity + :qty2,
                   updated_at = NOW(),
                   is_synced = TRUE'
            )->execute([
                'pid' => $m['product_id'],
                'qty' => $m['quantity_delta'],
                'qty2' => $m['quantity_delta'],
            ]);
        }
    }
}
