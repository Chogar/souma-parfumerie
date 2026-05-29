<?php

declare(strict_types=1);

namespace Souma\Api\Services;

use Souma\Api\Core\Database;
use PDO;

/** Données et actions Manager — parité avec l'app desktop. */
final class PortalManagerService
{
    private PDO $pdo;

    public function __construct()
    {
        $this->pdo = Database::connection();
    }

    /** @return array<string, int> */
    public function menuBadges(): array
    {
        $alerts = new AlertsService();
        $summary = $alerts->summary();
        $pending = $this->fetchOne("SELECT COUNT(*)::int AS c FROM sales WHERE return_status = 'pending'");

        return [
            'alerts' => ($summary['counts']['low_stock'] ?? 0) + ($summary['counts']['expiring'] ?? 0),
            'returns' => (int) ($pending['c'] ?? 0),
        ];
    }

    // ——— Produits ———

    /** @return list<array<string, mixed>> */
    public function listProducts(?string $search = null): array
    {
        $sql = '
            SELECT p.*, COALESCE(s.quantity, 0) AS quantity,
                   c.name_fr AS category_name_fr, c.name_ar AS category_name_ar
            FROM products p
            LEFT JOIN stock_levels s ON s.product_id = p.id
            JOIN categories c ON c.id = p.category_id
            WHERE p.is_active = TRUE';
        $params = [];
        if ($search !== null && trim($search) !== '') {
            $sql .= ' AND (p.name_fr ILIKE :q OR p.name_ar ILIKE :q OR p.barcode ILIKE :q)';
            $params['q'] = '%' . trim($search) . '%';
        }
        $sql .= ' ORDER BY p.name_fr ASC LIMIT 500';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @param array<string, mixed> $body */
    public function saveProduct(array $body): string
    {
        $id = $body['id'] ?? null;
        $isNew = $id === null || $id === '';

        if ($isNew) {
            $id = UuidHelper::v4();
            $this->pdo->prepare(
                'INSERT INTO products (
                    id, category_id, barcode, name_fr, name_ar, brand, volume_ml,
                    purchase_price, sale_price, min_stock_level, expires_at, is_synced
                 ) VALUES (
                    :id, :cat, :barcode, :name_fr, :name_ar, :brand, :vol,
                    :purchase, :sale, :min_stock, :expires, FALSE
                 )'
            )->execute($this->productParams($id, $body));

            $qty = (int) ($body['initial_stock'] ?? $body['stock_quantity'] ?? 0);
            $this->pdo->prepare(
                'INSERT INTO stock_levels (id, product_id, quantity, is_synced)
                 VALUES (:id, :pid, :qty, FALSE)'
            )->execute(['id' => UuidHelper::v4(), 'pid' => $id, 'qty' => $qty]);
        } else {
            $this->pdo->prepare(
                'UPDATE products SET
                    category_id = :cat, barcode = :barcode, name_fr = :name_fr,
                    name_ar = :name_ar, brand = :brand, volume_ml = :vol,
                    purchase_price = :purchase, sale_price = :sale,
                    min_stock_level = :min_stock, expires_at = :expires,
                    is_synced = FALSE, updated_at = NOW()
                 WHERE id = :id'
            )->execute($this->productParams($id, $body));

            if (isset($body['stock_quantity'])) {
                $this->pdo->prepare(
                    'UPDATE stock_levels SET quantity = :qty, is_synced = FALSE, updated_at = NOW()
                     WHERE product_id = :pid'
                )->execute(['qty' => (int) $body['stock_quantity'], 'pid' => $id]);
            }
        }

        return $id;
    }

    public function deactivateProduct(string $id): void
    {
        $this->pdo->prepare(
            'UPDATE products SET is_active = FALSE, is_synced = FALSE, updated_at = NOW() WHERE id = :id'
        )->execute(['id' => $id]);
    }

    // ——— Catégories ———

    /** @return list<array<string, mixed>> */
    public function listCategories(): array
    {
        return $this->pdo->query(
            'SELECT * FROM categories WHERE is_active = TRUE ORDER BY sort_order, name_fr'
        )->fetchAll();
    }

    /** @param array<string, mixed> $body */
    public function saveCategory(array $body): void
    {
        $id = $body['id'] ?? null;
        if ($id) {
            $this->pdo->prepare(
                'UPDATE categories SET name_fr = :fr, name_ar = :ar, sort_order = :ord, is_synced = FALSE WHERE id = :id'
            )->execute([
                'id' => $id, 'fr' => $body['name_fr'], 'ar' => $body['name_ar'],
                'ord' => (int) ($body['sort_order'] ?? 0),
            ]);
        } else {
            $this->pdo->prepare(
                'INSERT INTO categories (id, name_fr, name_ar, sort_order, is_synced)
                 VALUES (:id, :fr, :ar, :ord, FALSE)'
            )->execute([
                'id' => UuidHelper::v4(), 'fr' => $body['name_fr'], 'ar' => $body['name_ar'],
                'ord' => (int) ($body['sort_order'] ?? 0),
            ]);
        }
    }

    // ——— Fournisseurs ———

    /** @return list<array<string, mixed>> */
    public function listSuppliers(?string $search = null): array
    {
        $sql = 'SELECT * FROM suppliers WHERE is_active = TRUE';
        $params = [];
        if ($search !== null && trim($search) !== '') {
            $sql .= ' AND (name ILIKE :q OR phone ILIKE :q OR email ILIKE :q)';
            $params['q'] = '%' . trim($search) . '%';
        }
        $sql .= ' ORDER BY name ASC LIMIT 300';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @param array<string, mixed> $body */
    public function saveSupplier(array $body): void
    {
        $id = $body['id'] ?? null;
        $params = [
            'name' => trim((string) $body['name']),
            'phone' => $body['phone'] ?? null,
            'email' => $body['email'] ?? null,
            'address' => $body['address'] ?? null,
            'active' => !isset($body['is_active']) || $body['is_active'],
        ];
        if ($id) {
            $params['id'] = $id;
            $this->pdo->prepare(
                'UPDATE suppliers SET name = :name, phone = :phone, email = :email,
                    address = :address, is_active = :active::boolean, updated_at = NOW(), is_synced = FALSE
                 WHERE id = :id'
            )->execute($params);
        } else {
            $this->pdo->prepare(
                'INSERT INTO suppliers (id, name, phone, email, address, is_active, is_synced)
                 VALUES (:id, :name, :phone, :email, :address, :active::boolean, FALSE)'
            )->execute(array_merge($params, ['id' => UuidHelper::v4()]));
        }
    }

    // ——— Utilisateurs ———

    /** @return list<array<string, mixed>> */
    public function listUsers(): array
    {
        return $this->pdo->query(
            'SELECT u.id, u.username, u.full_name, u.is_active,
                    r.code AS role_code, r.label_fr, r.label_ar,
                    COALESCE(u.permissions, \'{}\'::jsonb) AS permissions
             FROM users u
             JOIN roles r ON r.id = u.role_id
             ORDER BY u.full_name'
        )->fetchAll();
    }

    /** @return list<array<string, mixed>> */
    public function listRoles(): array
    {
        return $this->pdo->query('SELECT id, code, label_fr, label_ar FROM roles ORDER BY code')->fetchAll();
    }

    /** @param array<string, mixed> $body */
    public function saveUser(array $body): void
    {
        $roleId = $this->roleIdByCode((string) $body['role_code']);
        $id = $body['id'] ?? null;
        $perms = json_encode($body['permissions'] ?? []);

        if ($id) {
            $sql = 'UPDATE users SET full_name = :name, role_id = :role,
                    permissions = :perms::jsonb, is_synced = FALSE, updated_at = NOW()';
            $params = ['id' => $id, 'name' => $body['full_name'], 'role' => $roleId, 'perms' => $perms];
            if (!empty($body['password'])) {
                $sql .= ', password_hash = :hash';
                $params['hash'] = password_hash((string) $body['password'], PASSWORD_BCRYPT);
            }
            $sql .= ' WHERE id = :id';
            $this->pdo->prepare($sql)->execute($params);
        } else {
            $this->pdo->prepare(
                'INSERT INTO users (id, role_id, username, password_hash, full_name, permissions, is_synced)
                 VALUES (:id, :role, :user, :hash, :name, :perms::jsonb, FALSE)'
            )->execute([
                'id' => UuidHelper::v4(),
                'role' => $roleId,
                'user' => $body['username'],
                'hash' => password_hash((string) $body['password'], PASSWORD_BCRYPT),
                'name' => $body['full_name'],
                'perms' => $perms,
            ]);
        }
    }

    // ——— Dépenses ———

    /** @return list<array<string, mixed>> */
    public function listExpenses(?string $from, ?string $to, ?string $category): array
    {
        if (!$this->expensesTableExists()) {
            return [];
        }
        $sql = '
            SELECT e.*, u.full_name AS user_name, s.name AS supplier_name
            FROM expenses e
            JOIN users u ON u.id = e.user_id
            LEFT JOIN suppliers s ON s.id = e.supplier_id
            WHERE 1=1';
        $params = [];
        if ($from) {
            $sql .= ' AND e.expense_date >= :from';
            $params['from'] = $from;
        }
        if ($to) {
            $sql .= ' AND e.expense_date <= :to';
            $params['to'] = $to;
        }
        if ($category) {
            $sql .= ' AND e.category = :cat';
            $params['cat'] = $category;
        }
        $sql .= ' ORDER BY e.expense_date DESC LIMIT 200';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @param array<string, mixed> $body */
    public function saveExpense(array $body, string $userId): void
    {
        $id = $body['id'] ?? UuidHelper::v4();
        $exists = $this->fetchOne('SELECT id FROM expenses WHERE id = :id', ['id' => $id]);
        $params = [
            'id' => $id,
            'date' => $body['expense_date'],
            'amount' => $body['amount'],
            'cat' => $body['category'],
            'desc' => $body['description'] ?? null,
            'ben' => $body['beneficiary'] ?? null,
            'sup' => $body['supplier_id'] ?? null,
            'user' => $userId,
            'pay' => $body['payment_method'] ?? 'cash',
        ];
        if ($exists) {
            $this->pdo->prepare(
                'UPDATE expenses SET expense_date = :date, amount = :amount, category = :cat,
                    description = :desc, beneficiary = :ben, supplier_id = :sup,
                    is_synced = FALSE, updated_at = NOW() WHERE id = :id'
            )->execute($params);
        } else {
            $this->pdo->prepare(
                'INSERT INTO expenses (id, expense_date, amount, category, description,
                    beneficiary, supplier_id, user_id, payment_method, is_synced)
                 VALUES (:id, :date, :amount, :cat, :desc, :ben, :sup, :user, :pay, FALSE)'
            )->execute($params);
        }
    }

    public function deleteExpense(string $id): void
    {
        $this->pdo->prepare('DELETE FROM expenses WHERE id = :id')->execute(['id' => $id]);
    }

    // ——— Paramètres boutique ———

    /** @return array<string, mixed> */
    public function getStoreSettings(): array
    {
        $row = $this->fetchOne('SELECT value FROM app_settings WHERE key = \'store\'');
        if (!$row || !isset($row['value'])) {
            return $this->defaultStoreSettings();
        }
        $v = $row['value'];
        if (is_string($v)) {
            $decoded = json_decode($v, true);

            return is_array($decoded) ? $decoded : $this->defaultStoreSettings();
        }

        return is_array($v) ? $v : $this->defaultStoreSettings();
    }

    /** @param array<string, mixed> $settings */
    public function saveStoreSettings(array $settings): void
    {
        $json = json_encode($settings, JSON_UNESCAPED_UNICODE);
        $existing = $this->fetchOne('SELECT id FROM app_settings WHERE key = \'store\'');
        if ($existing) {
            $this->pdo->prepare(
                'UPDATE app_settings SET value = :value::jsonb, is_synced = FALSE, updated_at = NOW() WHERE key = \'store\''
            )->execute(['value' => $json]);
        } else {
            $this->pdo->prepare(
                'INSERT INTO app_settings (id, key, value, is_synced) VALUES (:id, \'store\', :value::jsonb, FALSE)'
            )->execute(['id' => UuidHelper::v4(), 'value' => $json]);
        }
    }

    /** @return list<array<string, mixed>> */
    public function listReturnHistory(?string $status = null): array
    {
        $sql = '
            SELECT s.id, s.invoice_number, s.total, s.return_status, s.return_reason,
                   s.return_requested_at, s.return_approved_at,
                   u.full_name AS cashier_name, ru.full_name AS return_requester_name
            FROM sales s
            JOIN users u ON u.id = s.user_id
            LEFT JOIN users ru ON ru.id = s.return_requested_by
            WHERE s.return_status IS NOT NULL';
        $params = [];
        if ($status) {
            $sql .= ' AND s.return_status = :status';
            $params['status'] = $status;
        }
        $sql .= ' ORDER BY COALESCE(s.return_requested_at, s.return_approved_at) DESC LIMIT 200';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    // ——— Caisse (POS) ———

    /** @return list<array<string, mixed>> */
    public function posSearchProducts(?string $query): array
    {
        $sql = '
            SELECT p.*, COALESCE(s.quantity, 0) AS quantity
            FROM products p
            LEFT JOIN stock_levels s ON s.product_id = p.id
            WHERE p.is_active = TRUE
              AND (p.expires_at IS NULL OR p.expires_at >= CURRENT_DATE)';
        $params = [];
        $q = trim((string) $query);
        if ($q !== '') {
            $sql .= ' AND (p.barcode ILIKE :q OR p.name_fr ILIKE :q OR p.name_ar ILIKE :q)';
            $params['q'] = '%' . $q . '%';
        }
        $sql .= ' ORDER BY CASE WHEN COALESCE(s.quantity, 0) > 0 THEN 0 ELSE 1 END, p.name_fr LIMIT 200';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @param array<string, mixed> $body @return array{invoice_number: string} */
    public function completeSale(array $body, string $userId): array
    {
        $lines = $body['lines'] ?? [];
        if (!is_array($lines) || $lines === []) {
            throw new \InvalidArgumentException('Panier vide');
        }

        $saleId = UuidHelper::v4();
        $invoice = 'INV-' . (string) (int) (microtime(true) * 1000);

        $this->pdo->beginTransaction();
        try {
            $clientId = null;
            $phone = trim((string) ($body['client_phone'] ?? ''));
            if ($phone !== '') {
                $stmt = $this->pdo->prepare('SELECT id FROM clients WHERE phone = :phone');
                $stmt->execute(['phone' => $phone]);
                $row = $stmt->fetch();
                if ($row) {
                    $clientId = $row['id'];
                } else {
                    $clientId = UuidHelper::v4();
                    $this->pdo->prepare(
                        'INSERT INTO clients (id, phone, loyalty_points, is_synced) VALUES (:id, :phone, 0, FALSE)'
                    )->execute(['id' => $clientId, 'phone' => $phone]);
                }
            }

            $this->pdo->prepare(
                'INSERT INTO sales (
                    id, invoice_number, user_id, client_id, subtotal, discount_amount,
                    discount_percent, total, payment_method, amount_paid, change_given,
                    status, is_synced
                 ) VALUES (
                    :id, :inv, :user, :client, :sub, :disc, :discp, :total, :pay, :paid, :change,
                    \'completed\', FALSE
                 )'
            )->execute([
                'id' => $saleId,
                'inv' => $invoice,
                'user' => $userId,
                'client' => $clientId,
                'sub' => $body['subtotal'] ?? $body['total'],
                'disc' => $body['discount_amount'] ?? 0,
                'discp' => $body['discount_percent'] ?? 0,
                'total' => $body['total'],
                'pay' => $body['payment_method'] ?? 'cash',
                'paid' => $body['amount_paid'] ?? $body['total'],
                'change' => $body['change_given'] ?? 0,
            ]);

            foreach ($lines as $line) {
                $productId = $line['product_id'];
                $qty = (int) $line['quantity'];
                $unitPrice = (float) $line['unit_price'];
                $lineTotal = (float) ($line['line_total'] ?? $unitPrice * $qty);

                $this->pdo->prepare(
                    'INSERT INTO sale_lines (id, sale_id, product_id, quantity, unit_price, line_total, is_synced)
                     VALUES (:id, :sale, :product, :qty, :price, :total, FALSE)'
                )->execute([
                    'id' => UuidHelper::v4(), 'sale' => $saleId, 'product' => $productId,
                    'qty' => $qty, 'price' => $unitPrice, 'total' => $lineTotal,
                ]);

                $this->pdo->prepare(
                    'INSERT INTO stock_movements (id, product_id, movement_type, quantity_delta,
                        reference_type, reference_id, user_id, is_synced)
                     VALUES (:id, :product, \'sale\', :delta, \'sale\', :sale, :user, FALSE)'
                )->execute([
                    'id' => UuidHelper::v4(), 'product' => $productId, 'delta' => -$qty,
                    'sale' => $saleId, 'user' => $userId,
                ]);

                $upd = $this->pdo->prepare(
                    'UPDATE stock_levels SET quantity = GREATEST(0, quantity - :d), updated_at = NOW(), is_synced = FALSE
                     WHERE product_id = :product'
                );
                $upd->execute(['d' => $qty, 'product' => $productId]);
                if ($upd->rowCount() === 0) {
                    $this->pdo->prepare(
                        'INSERT INTO stock_levels (id, product_id, quantity, is_synced)
                         VALUES (:id, :product, 0, FALSE)'
                    )->execute(['id' => UuidHelper::v4(), 'product' => $productId]);
                }

                if ($clientId) {
                    $this->pdo->prepare(
                        'UPDATE clients SET loyalty_points = loyalty_points + 1, updated_at = NOW(), is_synced = FALSE
                         WHERE id = :id'
                    )->execute(['id' => $clientId]);
                }
            }

            $this->pdo->commit();

            return ['invoice_number' => $invoice, 'sale_id' => $saleId];
        } catch (\Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    /** @param array<string, mixed> $body */
    public function saveClient(array $body): void
    {
        $id = $body['id'] ?? null;
        if ($id) {
            $this->pdo->prepare(
                'UPDATE clients SET phone = :phone, name = :name, is_synced = FALSE, updated_at = NOW()
                 WHERE id = :id'
            )->execute(['id' => $id, 'phone' => $body['phone'], 'name' => $body['name'] ?? null]);
        } else {
            $this->pdo->prepare(
                'INSERT INTO clients (id, phone, name, loyalty_points, is_synced)
                 VALUES (:id, :phone, :name, 0, FALSE)
                 ON CONFLICT (phone) DO UPDATE SET name = COALESCE(EXCLUDED.name, clients.name), is_synced = FALSE'
            )->execute([
                'id' => UuidHelper::v4(), 'phone' => $body['phone'], 'name' => $body['name'] ?? null,
            ]);
        }
    }

    public function redeemClientGift(string $clientId): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE clients SET loyalty_points = 0, gifts_received = gifts_received + 1,
                is_synced = FALSE, updated_at = NOW()
             WHERE id = :id AND loyalty_points >= 10'
        );
        $stmt->execute(['id' => $clientId]);

        return $stmt->rowCount() > 0;
    }

    private function roleIdByCode(string $code): string
    {
        $row = $this->fetchOne('SELECT id FROM roles WHERE code = :code', ['code' => $code]);
        if (!$row) {
            throw new \RuntimeException('Rôle inconnu');
        }

        return $row['id'];
    }

    private function expensesTableExists(): bool
    {
        $row = $this->fetchOne(
            "SELECT 1 FROM information_schema.tables WHERE table_name = 'expenses' LIMIT 1"
        );

        return $row !== null;
    }

    /** @return array<string, mixed> */
    private function defaultStoreSettings(): array
    {
        return [
            'name_fr' => 'Souma Parfumerie',
            'name_ar' => 'سوما للعطور',
            'address' => '',
            'phone' => '',
            'email' => '',
            'currency_symbol' => 'FCFA',
            'currency_code' => 'XAF',
        ];
    }

    /** @param array<string, mixed> $body @return array<string, mixed> */
    private function productParams(string $id, array $body): array
    {
        return [
            'id' => $id,
            'cat' => $body['category_id'],
            'barcode' => $body['barcode'] ?? '',
            'name_fr' => $body['name_fr'],
            'name_ar' => $body['name_ar'] ?? $body['name_fr'],
            'brand' => $body['brand'] ?? null,
            'vol' => $body['volume_ml'] ?? null,
            'purchase' => $body['purchase_price'] ?? 0,
            'sale' => $body['sale_price'],
            'min_stock' => (int) ($body['min_stock_level'] ?? 5),
            'expires' => !empty($body['expires_at']) ? $body['expires_at'] : null,
        ];
    }

    /** @return array<string, mixed>|null */
    private function fetchOne(string $sql, array $params = []): ?array
    {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }
}
