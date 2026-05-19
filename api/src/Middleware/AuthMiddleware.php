<?php

declare(strict_types=1);

namespace Souma\Api\Middleware;

use Souma\Api\Core\Request;
use Souma\Api\Core\Response;
use Souma\Api\Services\JwtService;

final class AuthMiddleware
{
    public function handle(Request $request, callable $next): Response
    {
        $token = $request->bearerToken();
        if (!$token) {
            return Response::json(['success' => false, 'message' => 'Token manquant'], 401);
        }

        try {
            $payload = (new JwtService())->decode($token);
            return $next($request->withUser($payload));
        } catch (\Throwable) {
            return Response::json(['success' => false, 'message' => 'Token invalide'], 401);
        }
    }
}
