<?php

declare(strict_types=1);

namespace Souma\Api\Core;

use Dotenv\Dotenv;
use Souma\Api\Controllers\AuthController;
use Souma\Api\Controllers\HealthController;
use Souma\Api\Controllers\ManagerController;
use Souma\Api\Controllers\SyncController;
use Souma\Api\Middleware\AuthMiddleware;
use Souma\Api\Middleware\CorsMiddleware;
use Souma\Api\Middleware\ManagerMiddleware;

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
        $manager = new ManagerController();
        $authMw = new AuthMiddleware();
        $managerMw = new ManagerMiddleware();
        $managerAuth = [$authMw, $managerMw];

        $this->router->get('/api/health', fn (Request $r) => $health->index($r));
        $this->router->post('/api/auth/login', fn (Request $r) => $auth->login($r));

        $this->router->get('/api/sync/pull', fn (Request $r) => $sync->pull($r), [$authMw]);
        $this->router->post('/api/sync/push', fn (Request $r) => $sync->push($r), [$authMw]);
        $this->router->post('/api/sync/ack', fn (Request $r) => $sync->ack($r), [$authMw]);

        $this->router->get('/api/manager/dashboard', fn (Request $r) => $manager->dashboard($r), $managerAuth);
        $this->router->get('/api/manager/sales', fn (Request $r) => $manager->sales($r), $managerAuth);
        $this->router->get('/api/manager/sale', fn (Request $r) => $manager->saleDetail($r), $managerAuth);
        $this->router->get('/api/manager/returns', fn (Request $r) => $manager->pendingReturns($r), $managerAuth);
        $this->router->get('/api/manager/return', fn (Request $r) => $manager->returnDetail($r), $managerAuth);
        $this->router->post('/api/manager/returns/approve', fn (Request $r) => $manager->approveReturn($r), $managerAuth);
        $this->router->post('/api/manager/returns/reject', fn (Request $r) => $manager->rejectReturn($r), $managerAuth);
        $this->router->get('/api/manager/reports', fn (Request $r) => $manager->reports($r), $managerAuth);
        $this->router->get('/api/manager/reports/yearly', fn (Request $r) => $manager->reportsYearly($r), $managerAuth);
        $this->router->get('/api/manager/alerts/low-stock', fn (Request $r) => $manager->lowStock($r), $managerAuth);
        $this->router->get('/api/manager/alerts', fn (Request $r) => $manager->alerts($r), $managerAuth);
        $this->router->get('/api/manager/menu', fn (Request $r) => $manager->menu($r), $managerAuth);
        $this->router->get('/api/manager/clients', fn (Request $r) => $manager->clients($r), $managerAuth);
        $this->router->get('/api/manager/client', fn (Request $r) => $manager->clientDetail($r), $managerAuth);
        $this->router->post('/api/manager/clients', fn (Request $r) => $manager->saveClient($r), $managerAuth);
        $this->router->post('/api/manager/clients/redeem-gift', fn (Request $r) => $manager->redeemGift($r), $managerAuth);
        $this->router->get('/api/manager/products', fn (Request $r) => $manager->products($r), $managerAuth);
        $this->router->post('/api/manager/products', fn (Request $r) => $manager->saveProduct($r), $managerAuth);
        $this->router->post('/api/manager/products/deactivate', fn (Request $r) => $manager->deactivateProduct($r), $managerAuth);
        $this->router->get('/api/manager/categories', fn (Request $r) => $manager->categories($r), $managerAuth);
        $this->router->post('/api/manager/categories', fn (Request $r) => $manager->saveCategory($r), $managerAuth);
        $this->router->get('/api/manager/suppliers', fn (Request $r) => $manager->suppliers($r), $managerAuth);
        $this->router->post('/api/manager/suppliers', fn (Request $r) => $manager->saveSupplier($r), $managerAuth);
        $this->router->get('/api/manager/users', fn (Request $r) => $manager->users($r), $managerAuth);
        $this->router->get('/api/manager/roles', fn (Request $r) => $manager->roles($r), $managerAuth);
        $this->router->post('/api/manager/users', fn (Request $r) => $manager->saveUser($r), $managerAuth);
        $this->router->get('/api/manager/expenses', fn (Request $r) => $manager->expenses($r), $managerAuth);
        $this->router->post('/api/manager/expenses', fn (Request $r) => $manager->saveExpense($r), $managerAuth);
        $this->router->post('/api/manager/expenses/delete', fn (Request $r) => $manager->deleteExpense($r), $managerAuth);
        $this->router->get('/api/manager/settings', fn (Request $r) => $manager->storeSettings($r), $managerAuth);
        $this->router->post('/api/manager/settings', fn (Request $r) => $manager->saveStoreSettings($r), $managerAuth);
        $this->router->get('/api/manager/returns/history', fn (Request $r) => $manager->returnsHistory($r), $managerAuth);
        $this->router->get('/api/manager/pos/products', fn (Request $r) => $manager->posProducts($r), $managerAuth);
        $this->router->post('/api/manager/pos/sale', fn (Request $r) => $manager->posSale($r), $managerAuth);
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
