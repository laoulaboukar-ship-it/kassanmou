-- ═══════════════════════════════════════════════════
-- KASSAN'MOU v40 — SQL à exécuter dans Supabase
-- ═══════════════════════════════════════════════════

-- 1. Ajouter colonne email dans la table vendeurs (si elle n'existe pas)
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Créer la table commissions
CREATE TABLE IF NOT EXISTS commissions (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  vendeur_id    UUID REFERENCES vendeurs(id) ON DELETE SET NULL,
  produit_id    UUID REFERENCES produits(id) ON DELETE SET NULL,
  produit_nom   TEXT NOT NULL DEFAULT '',
  commande_ref  TEXT,
  montant       NUMERIC(10,2) NOT NULL DEFAULT 0,
  taux          NUMERIC(5,2) NOT NULL DEFAULT 2,
  base_calcul   NUMERIC(12,2) DEFAULT 0,
  type          TEXT DEFAULT 'publication', -- 'publication' ou 'vente'
  statut        TEXT DEFAULT 'due',         -- 'due' ou 'payee'
  payee_le      TIMESTAMP WITH TIME ZONE,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Index pour performances
CREATE INDEX IF NOT EXISTS idx_commissions_vendeur ON commissions(vendeur_id);
CREATE INDEX IF NOT EXISTS idx_commissions_statut  ON commissions(statut);

-- 4. Désactiver RLS pour l'instant (admin voit tout)
ALTER TABLE commissions DISABLE ROW LEVEL SECURITY;

-- 5. Politique publique temporaire (admin lit et écrit tout)
DROP POLICY IF EXISTS "admin_all" ON commissions;
CREATE POLICY "admin_all" ON commissions FOR ALL USING (true) WITH CHECK (true);

-- 6. Vérification
SELECT 'Table commissions créée avec succès ✅' AS status;
SELECT count(*) AS nb_commissions FROM commissions;
