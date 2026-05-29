<?php

declare(strict_types=1);

namespace Souma\Api\Controllers;

use Souma\Api\Core\Database;
use Souma\Api\Core\Request;
use Souma\Api\Core\Response;
use Souma\Api\Services\AuditService;
use Souma\Api\Services\JwtService;

final class AuthController
{
    public function login(Request $request): Response
    {
        $username = trim($request->body['username'] ?? '');
        $password = $request->body['password'] ?? '';

        if ($username === '' || $password === '') {
            return Response::json(['success' => false, 'message' => 'Identifiants requis'], 422);
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT u.*, r.code AS role_code, r.label_fr, r.label_ar
             FROM users u
             JOIN roles r ON r.id = u.role_id
             WHERE LOWER(u.username) = LOWER(:username) AND u.is_active = TRUE
             LIMIT 1'
        );
        $stmt->execute(['username' => $username]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            AuditService::log(null, 'login_failed', 'users', null, ['username' => $username]);
            return Response::json(['success' => false, 'message' => 'Identifiants incorrects'], 401);
        }

        $pdo->prepare('UPDATE users SET last_login_at = NOW() WHERE id = :id')
            ->execute(['id' => $user['id']]);

        $token = (new JwtService())->issue([
            'sub' => $user['id'],
            'username' => $user['username'],
            'role' => $user['role_code'],
            'full_name' => $user['full_name'],
        ]);

        AuditService::log($user['id'], 'login_success', 'users', $user['id']);

        $permissions = $user['permissions'] ?? '{}';
        if (is_string($permissions)) {
            $permissions = json_decode($permissions, true) ?: [];
        }

        return Response::json([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'username' => $user['username'],
                'full_name' => $user['full_name'],
                'role' => $user['role_code'],
                'role_label_fr' => $user['label_fr'],
                'role_label_ar' => $user['label_ar'],
                'permissions' => $permissions,
            ],
        ]);
    }
}
