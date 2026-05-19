-- Données initiales SOUMAPARFUMERIE

INSERT INTO roles (id, code, label_fr, label_ar, is_synced) VALUES
    ('a0000000-0000-4000-8000-000000000001', 'gestionnaire', 'Gestionnaire', 'مديرة', TRUE),
    ('a0000000-0000-4000-8000-000000000002', 'manager', 'Manager', 'مدير', TRUE)
ON CONFLICT (code) DO NOTHING;

-- Mot de passe : Admin@2026 (BCrypt cost 12)
INSERT INTO users (id, role_id, username, password_hash, full_name, is_synced) VALUES
    (
        'b0000000-0000-4000-8000-000000000001',
        'a0000000-0000-4000-8000-000000000002',
        'admin',
        '$2y$12$HHEns3GCl9qGgsXJgIdAjOOPSKM/lIkekA4WzDE9wylko3DIt65CS',
        'Administrateur Souma',
        TRUE
    ),
    (
        'b0000000-0000-4000-8000-000000000002',
        'a0000000-0000-4000-8000-000000000001',
        'caisse',
        '$2y$12$HHEns3GCl9qGgsXJgIdAjOOPSKM/lIkekA4WzDE9wylko3DIt65CS',
        'Gestionnaire Caisse',
        TRUE
    )
ON CONFLICT (username) DO NOTHING;

INSERT INTO categories (id, name_fr, name_ar, sort_order, is_synced) VALUES
    ('c0000000-0000-4000-8000-000000000001', 'Parfums', 'عطور', 1, TRUE),
    ('c0000000-0000-4000-8000-000000000002', 'Cosmétiques', 'مستحضرات تجميل', 2, TRUE),
    ('c0000000-0000-4000-8000-000000000003', 'Accessoires', 'إكسسوارات', 3, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO products (id, category_id, barcode, name_fr, name_ar, brand, volume_ml, purchase_price, sale_price, min_stock_level, is_synced) VALUES
    ('d0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', '3760123456789', 'Eau de Parfum Rose 50ml', 'عطر ورد 50 مل', 'Souma', 50, 15000, 25000, 5, TRUE),
    ('d0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000001', '3760123456790', 'Eau de Parfum Oud 100ml', 'عطر عود 100 مل', 'Souma', 100, 35000, 55000, 3, TRUE),
    ('d0000000-0000-4000-8000-000000000003', 'c0000000-0000-4000-8000-000000000002', '3760123456791', 'Crème Hydratante 200ml', 'كريم مرطب 200 مل', 'Souma Care', 200, 5000, 8500, 10, TRUE)
ON CONFLICT (barcode) DO NOTHING;

INSERT INTO stock_levels (product_id, quantity, is_synced)
SELECT id, 25, TRUE FROM products WHERE barcode = '3760123456789'
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO stock_levels (product_id, quantity, is_synced)
SELECT id, 15, TRUE FROM products WHERE barcode = '3760123456790'
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO stock_levels (product_id, quantity, is_synced)
SELECT id, 40, TRUE FROM products WHERE barcode = '3760123456791'
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO app_settings (key, value, is_synced) VALUES
    ('store', '{"name_fr":"SOUMAPARFUMERIE","name_ar":"سوما للعطور","currency":"XAF","address":""}', TRUE),
    ('print', '{"language":"fr","receipt_width":80,"auto_print":true}', TRUE),
    ('sync', '{"api_base_url":"https://votre-domaine.lws.fr/api","enabled":true}', TRUE)
ON CONFLICT (key) DO NOTHING;

INSERT INTO sync_state (device_id, last_pull_at, last_push_at) VALUES
    ('local-dev-machine', NULL, NULL)
ON CONFLICT (device_id) DO NOTHING;
