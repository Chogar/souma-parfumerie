<?php

declare(strict_types=1);

namespace Souma\Api\Core;

use Dotenv\Dotenv;
use Souma\Api\Controllers\AuthController;
use Souma\Api\Controllers\HealthController;
use Souma\Api\Controllers\SyncController;
use Souma\Api\Middleware\AuthMiddleware;
use Souma\Api\Middleware\CorsMiddleware;

final class Application
{
    private Router $router;

    public function __construct()
    {
        $root = dirname(__DIR__, 2);
        if (file_exists($root . '/.env')) {
            Dotenv::createImmutable($root)->load();
        } elseif (file_exists($root . '/.env.example')) {
            Dotenv::createImmutable($root, '.env.example')->load();
        }

        $this->router = new Router();
        $this->registerRoutes();
    }

    private function registerRoutes(): void
    {
        $health = new HealthController();
        $auth = new AuthController();
        $sync = new SyncController();
        $authMw = new AuthMiddleware();

        $this->router->get('/api/health', fn (Request $r) => $health->index($r));
        $this->router->post('/api/auth/login', fn (Request $r) => $auth->login($r));

        $this->router->get('/api/sync/pull', fn (Request $r) => $sync->pull($r), [$authMw]);
        $this->router->post('/api/sync/push', fn (Request $r) => $sync->push($r), [$authMw]);
        $this->router->post('/api/sync/ack', fn (Request $r) => $sync->ack($r), [$authMw]);
    }

    public function handle(Request $request): Response
    {
        $cors = new CorsMiddleware();
        if ($request->method === 'OPTIONS') {
            return $cors->preflight();
        }

        $response = $this->router->dispatch($request);
        return $cors->apply($response);
    }
}
