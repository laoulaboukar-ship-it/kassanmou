-- KASSAN'MOU v50 — SQL à exécuter dans Supabase
-- Exécuter dans l'ordre dans l'éditeur SQL de Supabase

-- 1. Table notations (avis clients)
CREATE TABLE IF NOT EXISTS notations (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  produit_id uuid REFERENCES produits(id) ON DELETE CASCADE,
  note integer NOT NULL CHECK (note >= 1 AND note <= 5),
  commentaire text DEFAULT '',
  date_notation timestamp with time zone DEFAULT now()
);

-- RLS notations
ALTER TABLE notations ENABLE ROW LEVEL SECURITY;

-- Lecture publique
DROP POLICY IF EXISTS "notations_select_public" ON notations;
CREATE POLICY "notations_select_public" ON notations
  FOR SELECT USING (true);

-- Insert anonyme
DROP POLICY IF EXISTS "notations_insert_anon" ON notations;
CREATE POLICY "notations_insert_anon" ON notations
  FOR INSERT WITH CHECK (true);

-- Admin tout faire
DROP POLICY IF EXISTS "notations_admin_all" ON notations;
CREATE POLICY "notations_admin_all" ON notations
  USING (EXISTS (
    SELECT 1 FROM profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
  ));

-- 2. Colonnes livraison sur produits (si pas déjà présentes)
ALTER TABLE produits ADD COLUMN IF NOT EXISTS livraison_locale boolean DEFAULT true;
ALTER TABLE produits ADD COLUMN IF NOT EXISTS livraison_interville boolean DEFAULT false;
ALTER TABLE produits ADD COLUMN IF NOT EXISTS produit_frais boolean DEFAULT false;

-- 3. Index pour performances
CREATE INDEX IF NOT EXISTS idx_notations_produit_id ON notations(produit_id);
CREATE INDEX IF NOT EXISTS idx_produits_statut ON produits(statut);
CREATE INDEX IF NOT EXISTS idx_produits_est_vedette ON produits(est_vedette);

-- Vérification
SELECT 'notations OK' as status, count(*) as nb FROM notations
UNION ALL
SELECT 'livraison_interville col' as status, count(*) as nb FROM produits WHERE livraison_interville IS NOT NULL LIMIT 1;
