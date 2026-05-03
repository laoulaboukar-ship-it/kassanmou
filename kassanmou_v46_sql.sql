-- v46 : colonnes livraison sur table produits
ALTER TABLE produits ADD COLUMN IF NOT EXISTS livraison_locale boolean DEFAULT true;
ALTER TABLE produits ADD COLUMN IF NOT EXISTS livraison_interville boolean DEFAULT false;
ALTER TABLE produits ADD COLUMN IF NOT EXISTS produit_frais boolean DEFAULT false;

-- Vérification
SELECT column_name FROM information_schema.columns
WHERE table_schema='public' AND table_name='produits'
AND column_name IN ('livraison_locale','livraison_interville','produit_frais');
