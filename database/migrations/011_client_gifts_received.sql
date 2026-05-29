-- Compteur de cadeaux fidélité remis par client

ALTER TABLE clients ADD COLUMN IF NOT EXISTS gifts_received INT NOT NULL DEFAULT 0;

COMMENT ON COLUMN clients.gifts_received IS 'Nombre de cadeaux fidélité offerts (carte remise à zéro à chaque fois)';
