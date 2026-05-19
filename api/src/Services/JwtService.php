<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

final class JwtService
{
    public function issue(array $payload): string
    {
        $ttl = (int) ($_ENV['JWT_TTL'] ?? 86400);
        $payload['iat'] = time();
        $payload['exp'] = time() + $ttl;
        return JWT::encode($payload, $this->secret(), 'HS256');
    }

    public function decode(string $token): array
    {
        $decoded = JWT::decode($token, new Key($this->secret(), 'HS256'));
        return (array) $decoded;
    }

    private function secret(): string
    {
        $secret = $_ENV['JWT_SECRET'] ?? '';
        if (strlen($secret) < 16) {
            throw new \RuntimeException('JWT_SECRET invalide');
        }
        return $secret;
    }
}
