<?php

declare(strict_types=1);

namespace Souma\Api\Middleware;

use Souma\Api\Core\Request;
use Souma\Api\Core\Response;

final class ManagerMiddleware
{
    public function handle(Request $request, callable $next): Response
    {
        $role = $request->user['role'] ?? '';
        if ($role !== 'manager') {
            return Response::json([
                'success' => false,
                'message' => 'Accès réservé au manager',
            ], 403);
        }

        return $next($request);
    }
}
