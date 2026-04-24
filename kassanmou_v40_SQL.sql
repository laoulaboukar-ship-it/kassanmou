-- ═══════════════════════════════════════════════════════
-- KASSAN'MOU v40 — SQL à exécuter dans Supabase SQL Editor
-- ═══════════════════════════════════════════════════════

-- 1. Ajouter colonne email dans vendeurs (si absente)
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Créer table commissions
CREATE TABLE IF NOT EXISTS commissions (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendeur_id    UUID REFERENCES vendeurs(id) ON DELETE SET NULL,
  produit_id    UUID REFERENCES produits(id) ON DELETE SET NULL,
  produit_nom   TEXT NOT NULL DEFAULT '',
  commande_ref  TEXT,
  montant       NUMERIC(10,2) NOT NULL DEFAULT 0,
  taux          NUMERIC(5,2)  NOT NULL DEFAULT 2,
  base_calcul   NUMERIC(12,2) DEFAULT 0,
  type          TEXT DEFAULT 'publication',
  statut        TEXT DEFAULT 'due',
  payee_le      TIMESTAMP WITH TIME ZONE,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Index
CREATE INDEX IF NOT EXISTS idx_commissions_vendeur ON commissions(vendeur_id);
CREATE INDEX IF NOT EXISTS idx_commissions_statut  ON commissions(statut);

-- 4. Désactiver RLS (admin voit tout)
ALTER TABLE commissions DISABLE ROW LEVEL SECURITY;

-- 5. Vérification
SELECT 'Table commissions OK' AS status;
SELECT count(*) AS nb FROM commissions;
