<?php

declare(strict_types=1);

use Souma\Api\Core\Application;
use Souma\Api\Core\Request;
use Souma\Api\Core\Response;

require dirname(__DIR__) . '/vendor/autoload.php';

$app = new Application();
$request = Request::fromGlobals();

try {
    $response = $app->handle($request);
} catch (Throwable $e) {
    $debug = ($_ENV['APP_DEBUG'] ?? 'false') === 'true';
    $response = Response::json([
        'success' => false,
        'message' => $debug ? $e->getMessage() : 'Erreur serveur',
    ], 500);
}

$response->send();
