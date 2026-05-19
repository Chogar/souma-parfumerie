<?php

declare(strict_types=1);

namespace Souma\Api\Middleware;

use Souma\Api\Core\Request;
use Souma\Api\Core\Response;

final class CorsMiddleware
{
    public function handle(Request $request, callable $next): Response
    {
        $response = $next($request);
        return $this->apply($response);
    }

    public function apply(Response $response): Response
    {
        $origin = $_ENV['CORS_ORIGIN'] ?? '*';
        return $response
            ->withHeader('Access-Control-Allow-Origin', $origin)
            ->withHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
            ->withHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    }

    public function preflight(): Response
    {
        return $this->apply(Response::json(['success' => true]));
    }
}
