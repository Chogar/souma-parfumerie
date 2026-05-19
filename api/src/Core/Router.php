<?php

declare(strict_types=1);

namespace Souma\Api\Core;

final class Router
{
    /** @var array<string, array<string, array{callable, array}>> */
    private array $routes = [];

    public function get(string $path, callable $handler, array $middleware = []): void
    {
        $this->add('GET', $path, $handler, $middleware);
    }

    public function post(string $path, callable $handler, array $middleware = []): void
    {
        $this->add('POST', $path, $handler, $middleware);
    }

    private function add(string $method, string $path, callable $handler, array $middleware): void
    {
        $this->routes[$method][$path] = [$handler, $middleware];
    }

    public function dispatch(Request $request): Response
    {
        $method = $request->method;
        $path = rtrim($request->path, '/') ?: '/';

        $handler = $this->routes[$method][$path] ?? null;
        if ($handler === null) {
            return Response::json(['success' => false, 'message' => 'Route introuvable'], 404);
        }

        [$callable, $middleware] = $handler;
        $next = fn (Request $r) => $callable($r);

        foreach (array_reverse($middleware) as $mw) {
            $prev = $next;
            $next = fn (Request $r) => $mw->handle($r, $prev);
        }

        return $next($request);
    }
}
