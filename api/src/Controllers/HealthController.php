<?php

declare(strict_types=1);

namespace Souma\Api\Controllers;

use Souma\Api\Core\Database;
use Souma\Api\Core\Request;
use Souma\Api\Core\Response;

final class HealthController
{
    public function index(Request $request): Response
    {
        $dbOk = false;
        try {
            Database::connection()->query('SELECT 1');
            $dbOk = true;
        } catch (\Throwable) {
            $dbOk = false;
        }

        return Response::json([
            'success' => true,
            'service' => 'SOUMAPARFUMERIE API',
            'version' => '1.0.0',
            'database' => $dbOk ? 'connected' : 'disconnected',
            'timestamp' => date('c'),
        ]);
    }
}
