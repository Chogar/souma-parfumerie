<?php

declare(strict_types=1);

namespace Souma\Api\Core;

final class Request
{
    public function __construct(
        public readonly string $method,
        public readonly string $path,
        public readonly array $query,
        public readonly array $body,
        public readonly array $headers,
        public readonly ?array $user = null,
    ) {}

    public static function fromGlobals(): self
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        $uri = $_SERVER['REQUEST_URI'] ?? '/';
        $path = parse_url($uri, PHP_URL_PATH) ?: '/';

        // MAMP / sous-dossier : /Souma Parfumerie/api/public/api/health → /api/health
        $scriptName = $_SERVER['SCRIPT_NAME'] ?? '';
        $basePath = rtrim(str_replace('\\', '/', dirname($scriptName)), '/');
        if ($basePath !== '' && $basePath !== '/' && str_starts_with($path, $basePath)) {
            $path = substr($path, strlen($basePath)) ?: '/';
        }
        if (!str_starts_with($path, '/')) {
            $path = '/' . $path;
        }

        $headers = [];
        foreach ($_SERVER as $key => $value) {
            if (str_starts_with($key, 'HTTP_')) {
                $name = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($key, 5)))));
                $headers[$name] = $value;
            }
        }

        $raw = file_get_contents('php://input') ?: '';
        $body = json_decode($raw, true);
        if (!is_array($body)) {
            $body = $_POST;
        }

        return new self($method, $path, $_GET, $body, $headers);
    }

    public function bearerToken(): ?string
    {
        $auth = $this->headers['Authorization'] ?? $this->headers['authorization'] ?? null;
        if ($auth && preg_match('/Bearer\s+(\S+)/i', $auth, $m)) {
            return $m[1];
        }
        return null;
    }

    public function withUser(array $user): self
    {
        return new self($this->method, $this->path, $this->query, $this->body, $this->headers, $user);
    }
}
