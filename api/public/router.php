<?php

declare(strict_types=1);

/**
 * Routeur pour le serveur PHP intégré (php -S).
 * - Portail /manager/ avec en-têtes no-cache (évite JS/CSS obsolètes)
 * - API via index.php
 */
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/');

$managerRoot = __DIR__ . '/manager';

if ($uri === '/manager' || $uri === '/manager/') {
    serveManagerFile($managerRoot . '/index.html');
    return;
}

if (str_starts_with($uri, '/manager/')) {
    $rel = substr($uri, strlen('/manager/'));
    if ($rel === '' || str_contains($rel, '..')) {
        http_response_code(404);
        echo 'Not found';
        return;
    }
    $file = $managerRoot . '/' . $rel;
    if (is_file($file)) {
        serveManagerFile($file);
        return;
    }
}

if ($uri !== '/' && is_file(__DIR__ . $uri)) {
    return false;
}

require __DIR__ . '/index.php';

function serveManagerFile(string $path): void
{
    $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
    $types = [
        'html' => 'text/html; charset=UTF-8',
        'js' => 'application/javascript; charset=UTF-8',
        'css' => 'text/css; charset=UTF-8',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'svg' => 'image/svg+xml',
        'webp' => 'image/webp',
        'ico' => 'image/x-icon',
    ];

    header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
    header('Pragma: no-cache');
    header('Expires: 0');

    $v = managerAssetVersion();

    if (in_array($ext, ['js', 'css'], true)) {
        $reqV = $_GET['v'] ?? '';
        $base = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        if ($reqV !== $v) {
            header('Location: ' . $base . '?v=' . $v, true, 302);
            return;
        }
        header('X-Portal-Version: ' . $v);
    }

    if (isset($types[$ext])) {
        header('Content-Type: ' . $types[$ext]);
    }

    if ($ext === 'html') {
        $html = file_get_contents($path);
        if ($html !== false) {
            $html = str_replace('__PORTAL_V__', $v, $html);
            echo $html;
            return;
        }
    }

    readfile($path);
}

function managerAssetVersion(): string
{
    $dir = __DIR__ . '/manager';
    $mtimes = [];
    foreach (['index.html', 'app.js', 'portal-modules.js', 'report-pdf.js', 'i18n.js', 'styles.css'] as $name) {
        $f = $dir . '/' . $name;
        if (is_file($f)) {
            $mtimes[] = filemtime($f);
        }
    }
    return $mtimes !== [] ? (string) max($mtimes) : '1';
}
