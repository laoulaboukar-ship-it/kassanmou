-- KASSAN'MOU v40 — Exécuter dans Supabase SQL Editor
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS email TEXT;
CREATE TABLE IF NOT EXISTS commissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendeur_id UUID REFERENCES vendeurs(id) ON DELETE SET NULL,
  produit_id UUID REFERENCES produits(id) ON DELETE SET NULL,
  produit_nom TEXT NOT NULL DEFAULT '',
  commande_ref TEXT,
  montant NUMERIC(10,2) NOT NULL DEFAULT 0,
  taux NUMERIC(5,2) NOT NULL DEFAULT 2,
  base_calcul NUMERIC(12,2) DEFAULT 0,
  type TEXT DEFAULT 'publication',
  statut TEXT DEFAULT 'due',
  payee_le TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_commissions_vendeur ON commissions(vendeur_id);
CREATE INDEX IF NOT EXISTS idx_commissions_statut ON commissions(statut);
ALTER TABLE commissions DISABLE ROW LEVEL SECURITY;
SELECT 'OK' AS status, count(*) AS nb FROM commissions;
