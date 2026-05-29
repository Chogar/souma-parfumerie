<?php

declare(strict_types=1);

namespace Souma\Api\Controllers;

use Souma\Api\Core\Request;
use Souma\Api\Core\Response;
use Souma\Api\Services\AlertsService;
use Souma\Api\Services\AuditService;
use Souma\Api\Services\ClientsService;
use Souma\Api\Services\DashboardService;
use Souma\Api\Services\ReportsService;
use Souma\Api\Services\ReturnsService;
use Souma\Api\Services\PortalManagerService;
use Souma\Api\Services\SalesService;

final class ManagerController
{
    private function portal(): PortalManagerService
    {
        return new PortalManagerService();
    }

    public function menu(Request $request): Response
    {
        return Response::json(['success' => true, 'data' => $this->portal()->menuBadges()]);
    }
    public function dashboard(Request $request): Response
    {
        $dashboard = new DashboardService();

        return Response::json([
            'success' => true,
            'data' => [
                'today' => $dashboard->todayStats(),
                'low_stock_count' => $dashboard->lowStockCount(),
                'pending_returns' => $dashboard->pendingReturnsCount(),
                'returns_today' => $dashboard->returnDailySummary(),
                'recent_sales' => $dashboard->recentSales(10, true),
            ],
        ]);
    }

    public function sales(Request $request): Response
    {
        $from = $request->query['from'] ?? null;
        $to = $request->query['to'] ?? null;
        $limit = min(500, max(1, (int) ($request->query['limit'] ?? 100)));

        $service = new SalesService();

        return Response::json([
            'success' => true,
            'data' => $service->listSales(
                is_string($from) ? $from : null,
                is_string($to) ? $to : null,
                $limit
            ),
        ]);
    }

    public function saleDetail(Request $request): Response
    {
        $id = trim($request->query['id'] ?? '');
        if ($id === '') {
            return Response::json(['success' => false, 'message' => 'ID vente requis'], 422);
        }

        $detail = (new SalesService())->getSaleDetail($id);
        if ($detail === null) {
            return Response::json(['success' => false, 'message' => 'Vente introuvable'], 404);
        }

        return Response::json(['success' => true, 'data' => $detail]);
    }

    public function pendingReturns(Request $request): Response
    {
        try {
            return Response::json([
                'success' => true,
                'data' => (new ReturnsService())->listPending(),
            ]);
        } catch (\Throwable $e) {
            return Response::json([
                'success' => false,
                'message' => 'Module retours indisponible',
            ], 503);
        }
    }

    public function returnDetail(Request $request): Response
    {
        $id = trim($request->query['id'] ?? '');
        if ($id === '') {
            return Response::json(['success' => false, 'message' => 'ID vente requis'], 422);
        }

        try {
            $detail = (new ReturnsService())->getDetail($id);
        } catch (\Throwable) {
            return Response::json(['success' => false, 'message' => 'Module retours indisponible'], 503);
        }

        if ($detail === null) {
            return Response::json(['success' => false, 'message' => 'Retour introuvable'], 404);
        }

        return Response::json(['success' => true, 'data' => $detail]);
    }

    public function approveReturn(Request $request): Response
    {
        $saleId = trim($request->body['sale_id'] ?? '');
        if ($saleId === '') {
            return Response::json(['success' => false, 'message' => 'sale_id requis'], 422);
        }

        $managerId = $request->user['sub'] ?? '';

        try {
            (new ReturnsService())->approve($saleId, $managerId);
            AuditService::log($managerId, 'return_approved', 'sales', $saleId);

            return Response::json(['success' => true, 'message' => 'Retour approuvé']);
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage());
        } catch (\Throwable) {
            return Response::json(['success' => false, 'message' => 'Erreur lors de l\'approbation'], 500);
        }
    }

    public function rejectReturn(Request $request): Response
    {
        $saleId = trim($request->body['sale_id'] ?? '');
        if ($saleId === '') {
            return Response::json(['success' => false, 'message' => 'sale_id requis'], 422);
        }

        $managerId = $request->user['sub'] ?? '';

        try {
            (new ReturnsService())->reject($saleId, $managerId);
            AuditService::log($managerId, 'return_rejected', 'sales', $saleId);

            return Response::json(['success' => true, 'message' => 'Retour refusé']);
        } catch (\RuntimeException $e) {
            return $this->returnError($e->getMessage());
        } catch (\Throwable) {
            return Response::json(['success' => false, 'message' => 'Erreur lors du refus'], 500);
        }
    }

    public function reports(Request $request): Response
    {
        $from = $request->query['from'] ?? date('Y-m-d', strtotime('-30 days'));
        $to = $request->query['to'] ?? date('Y-m-d');

        if (!is_string($from) || !is_string($to)) {
            return Response::json(['success' => false, 'message' => 'Dates invalides'], 422);
        }

        return Response::json([
            'success' => true,
            'data' => (new ReportsService())->fullReport($from, $to),
        ]);
    }

    public function reportsYearly(Request $request): Response
    {
        $year = (int) ($request->query['year'] ?? date('Y'));
        if ($year < 2000 || $year > 2100) {
            return Response::json(['success' => false, 'message' => 'Année invalide'], 422);
        }

        return Response::json([
            'success' => true,
            'data' => (new ReportsService())->yearlyReport($year),
        ]);
    }

    public function lowStock(Request $request): Response
    {
        $limit = min(100, max(1, (int) ($request->query['limit'] ?? 20)));

        return Response::json([
            'success' => true,
            'data' => (new ReportsService())->lowStock($limit),
        ]);
    }

    public function alerts(Request $request): Response
    {
        return Response::json([
            'success' => true,
            'data' => (new AlertsService())->summary(),
        ]);
    }

    public function clients(Request $request): Response
    {
        $search = $request->query['search'] ?? null;

        return Response::json([
            'success' => true,
            'data' => (new ClientsService())->list(
                is_string($search) ? $search : null
            ),
        ]);
    }

    public function clientDetail(Request $request): Response
    {
        $id = trim($request->query['id'] ?? '');
        if ($id === '') {
            return Response::json(['success' => false, 'message' => 'ID client requis'], 422);
        }

        $detail = (new ClientsService())->detail($id);
        if ($detail === null) {
            return Response::json(['success' => false, 'message' => 'Client introuvable'], 404);
        }

        return Response::json(['success' => true, 'data' => $detail]);
    }

    public function products(Request $request): Response
    {
        $q = $request->query['search'] ?? null;

        return Response::json([
            'success' => true,
            'data' => $this->portal()->listProducts(is_string($q) ? $q : null),
        ]);
    }

    public function saveProduct(Request $request): Response
    {
        try {
            $id = $this->portal()->saveProduct($request->body);

            return Response::json(['success' => true, 'id' => $id]);
        } catch (\Throwable $e) {
            return Response::json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    }

    public function deactivateProduct(Request $request): Response
    {
        $id = trim($request->body['id'] ?? '');
        if ($id === '') {
            return Response::json(['success' => false, 'message' => 'ID requis'], 422);
        }
        $this->portal()->deactivateProduct($id);

        return Response::json(['success' => true]);
    }

    public function categories(Request $request): Response
    {
        return Response::json(['success' => true, 'data' => $this->portal()->listCategories()]);
    }

    public function saveCategory(Request $request): Response
    {
        $this->portal()->saveCategory($request->body);

        return Response::json(['success' => true]);
    }

    public function suppliers(Request $request): Response
    {
        $q = $request->query['search'] ?? null;

        return Response::json([
            'success' => true,
            'data' => $this->portal()->listSuppliers(is_string($q) ? $q : null),
        ]);
    }

    public function saveSupplier(Request $request): Response
    {
        $this->portal()->saveSupplier($request->body);

        return Response::json(['success' => true]);
    }

    public function users(Request $request): Response
    {
        return Response::json(['success' => true, 'data' => $this->portal()->listUsers()]);
    }

    public function roles(Request $request): Response
    {
        return Response::json(['success' => true, 'data' => $this->portal()->listRoles()]);
    }

    public function saveUser(Request $request): Response
    {
        try {
            $this->portal()->saveUser($request->body);

            return Response::json(['success' => true]);
        } catch (\Throwable $e) {
            return Response::json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    }

    public function expenses(Request $request): Response
    {
        return Response::json([
            'success' => true,
            'data' => $this->portal()->listExpenses(
                $request->query['from'] ?? null,
                $request->query['to'] ?? null,
                $request->query['category'] ?? null,
            ),
        ]);
    }

    public function saveExpense(Request $request): Response
    {
        $userId = $request->user['sub'] ?? '';
        $this->portal()->saveExpense($request->body, $userId);

        return Response::json(['success' => true]);
    }

    public function deleteExpense(Request $request): Response
    {
        $id = trim($request->body['id'] ?? '');
        if ($id === '') {
            return Response::json(['success' => false, 'message' => 'ID requis'], 422);
        }
        $this->portal()->deleteExpense($id);

        return Response::json(['success' => true]);
    }

    public function storeSettings(Request $request): Response
    {
        return Response::json(['success' => true, 'data' => $this->portal()->getStoreSettings()]);
    }

    public function saveStoreSettings(Request $request): Response
    {
        $this->portal()->saveStoreSettings($request->body);

        return Response::json(['success' => true]);
    }

    public function returnsHistory(Request $request): Response
    {
        $status = $request->query['status'] ?? null;

        return Response::json([
            'success' => true,
            'data' => $this->portal()->listReturnHistory(is_string($status) ? $status : null),
        ]);
    }

    public function posProducts(Request $request): Response
    {
        $q = $request->query['q'] ?? $request->query['search'] ?? null;

        return Response::json([
            'success' => true,
            'data' => $this->portal()->posSearchProducts(is_string($q) ? $q : null),
        ]);
    }

    public function posSale(Request $request): Response
    {
        try {
            $userId = $request->user['sub'] ?? '';
            $result = $this->portal()->completeSale($request->body, $userId);
            AuditService::log($userId, 'pos_sale', 'sales', $result['sale_id'] ?? null);

            return Response::json(['success' => true, 'data' => $result]);
        } catch (\Throwable $e) {
            return Response::json(['success' => false, 'message' => $e->getMessage()], 422);
        }
    }

    public function saveClient(Request $request): Response
    {
        $this->portal()->saveClient($request->body);

        return Response::json(['success' => true]);
    }

    public function redeemGift(Request $request): Response
    {
        $id = trim($request->body['client_id'] ?? '');
        if ($id === '') {
            return Response::json(['success' => false, 'message' => 'client_id requis'], 422);
        }
        $ok = $this->portal()->redeemClientGift($id);

        return Response::json(['success' => $ok, 'message' => $ok ? 'Cadeau enregistré' : 'Points insuffisants']);
    }

    private function returnError(string $code): Response
    {
        $messages = [
            'SALE_NOT_FOUND' => 'Vente introuvable',
            'RETURN_NOT_PENDING' => 'Ce retour n\'est plus en attente',
            'RETURN_MIGRATION_REQUIRED' => 'Migration retours requise',
        ];

        $status = $code === 'SALE_NOT_FOUND' ? 404 : 422;

        return Response::json([
            'success' => false,
            'message' => $messages[$code] ?? $code,
            'code' => $code,
        ], $status);
    }
}
