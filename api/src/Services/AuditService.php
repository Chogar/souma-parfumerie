<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;

final class AuditService
{
    public static function log(
        ?string $userId,
        string $action,
        ?string $entity = null,
        ?string $entityId = null,
        ?array $details = null
    ): void {
        try {
            $pdo = Database::connection();
            $stmt = $pdo->prepare(
                'INSERT INTO audit_logs (user_id, action, entity, entity_id, details, ip_address)
                 VALUES (:user_id, :action, :entity, :entity_id, :details::jsonb, :ip)'
            );
            $stmt->execute([
                'user_id' => $userId,
                'action' => $action,
                'entity' => $entity,
                'entity_id' => $entityId,
                'details' => $details ? json_encode($details) : null,
                'ip' => $_SERVER['REMOTE_ADDR'] ?? null,
            ]);
        } catch (\Throwable) {
            // Ne pas bloquer le flux métier
        }
    }
}
