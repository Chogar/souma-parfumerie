-- Paramètres boutique (factures, rapports, tickets)

INSERT INTO app_settings (key, value, is_synced)
VALUES (
  'store',
  '{
    "name_fr": "Souma Parfumerie",
    "name_ar": "سوما للعطور",
    "address": "",
    "phone": "",
    "email": "",
    "currency_symbol": "FCFA",
    "currency_code": "XAF",
    "slogan_fr": "",
    "slogan_ar": "",
    "legal_info": "",
    "opening_hours": ""
  }'::jsonb,
  TRUE
)
ON CONFLICT (key) DO NOTHING;
