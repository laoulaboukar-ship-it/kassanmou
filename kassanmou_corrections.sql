-- ================================================
-- KASSAN'MOU — CORRECTIONS COMPLÈTES v42 (CORRIGÉ)
-- Exécuter dans SQL Editor Supabase
-- ================================================


-- ════════════════════════════════════════════════
-- SECTION 1 : CORRECTION VENDEUR_ID NULL
-- ════════════════════════════════════════════════

INSERT INTO vendeurs (id, nom, email, telephone, ville, statut)
VALUES (
  gen_random_uuid(),
  'MONAEL JUS',
  'monael@kassanmou.com',
  '',
  'Niamey',
  'actif'
)
ON CONFLICT DO NOTHING;

UPDATE produits
SET vendeur_id = (
  SELECT id FROM vendeurs WHERE nom = 'MONAEL JUS' LIMIT 1
)
WHERE id = '3b90a704-34df-4b08-8ab0-bc96647d4e2e'
  AND vendeur_id IS NULL;


-- ════════════════════════════════════════════════
-- SECTION 2 : CONTRAINTES SUR PRODUITS
-- (sans IF NOT EXISTS — non supporté sur contraintes)
-- ════════════════════════════════════════════════

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'produits_description_min'
  ) THEN
    ALTER TABLE produits
      ADD CONSTRAINT produits_description_min
      CHECK (length(description) >= 20);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'produits_prix_positif'
  ) THEN
    ALTER TABLE produits
      ADD CONSTRAINT produits_prix_positif
      CHECK (prix > 0);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'produits_nom_non_vide'
  ) THEN
    ALTER TABLE produits
      ADD CONSTRAINT produits_nom_non_vide
      CHECK (length(trim(nom)) > 0);
  END IF;
END $$;


-- ════════════════════════════════════════════════
-- SECTION 3 : COLONNES MANQUANTES SUR VENDEURS
-- ════════════════════════════════════════════════

ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS statut text DEFAULT 'actif';
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS ville text;
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS region text;
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS auth_user_id uuid REFERENCES auth.users(id);
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS abonnement text DEFAULT 'standard';
ALTER TABLE vendeurs ADD COLUMN IF NOT EXISTS date_inscription timestamptz DEFAULT now();

CREATE INDEX IF NOT EXISTS vendeurs_email_idx ON vendeurs(email);
CREATE INDEX IF NOT EXISTS vendeurs_auth_user_id_idx ON vendeurs(auth_user_id);


-- ════════════════════════════════════════════════
-- SECTION 4 : COLONNES MANQUANTES SUR COMMISSIONS
-- ════════════════════════════════════════════════

ALTER TABLE commissions ADD COLUMN IF NOT EXISTS produit_id uuid REFERENCES produits(id);
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS vendeur_id uuid REFERENCES vendeurs(id);
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS montant_vente numeric(12,2);
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS montant_commission numeric(12,2);
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS taux_commission numeric(5,2) DEFAULT 2.00;
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS statut text DEFAULT 'due';
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS date_commission timestamptz DEFAULT now();
ALTER TABLE commissions ADD COLUMN IF NOT EXISTS date_paiement timestamptz;


-- ════════════════════════════════════════════════
-- SECTION 5 : COLONNES MANQUANTES SUR COMMANDES
-- ════════════════════════════════════════════════

ALTER TABLE commandes ADD COLUMN IF NOT EXISTS produit_id uuid REFERENCES produits(id);
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS acheteur_nom text;
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS acheteur_telephone text;
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS acheteur_ville text;
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS quantite numeric(10,2) DEFAULT 1;
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS prix_unitaire numeric(12,2);
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS montant_total numeric(12,2);
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS mode_paiement text;
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS mode_livraison text;
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS statut text DEFAULT 'en_attente';
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS date_commande timestamptz DEFAULT now();
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS reference text;


-- ════════════════════════════════════════════════
-- SECTION 6 : RLS — ACTIVER SUR COMMANDES
-- ════════════════════════════════════════════════

ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_all_commandes" ON commandes;
CREATE POLICY "admin_all_commandes"
ON commandes FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "public_read_commandes" ON commandes;
CREATE POLICY "public_read_commandes"
ON commandes FOR SELECT TO anon
USING (true);

DROP POLICY IF EXISTS "public_insert_commandes" ON commandes;
CREATE POLICY "public_insert_commandes"
ON commandes FOR INSERT TO anon
WITH CHECK (true);


-- ════════════════════════════════════════════════
-- SECTION 7 : RLS — VENDEURS
-- ════════════════════════════════════════════════

DROP POLICY IF EXISTS "admin_all_vendeurs" ON vendeurs;
CREATE POLICY "admin_all_vendeurs"
ON vendeurs FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "vendeur_own_profile" ON vendeurs;
CREATE POLICY "vendeur_own_profile"
ON vendeurs FOR SELECT TO authenticated
USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "vendeur_update_own" ON vendeurs;
CREATE POLICY "vendeur_update_own"
ON vendeurs FOR UPDATE TO authenticated
USING (auth_user_id = auth.uid());

DROP POLICY IF EXISTS "public_insert_vendeur" ON vendeurs;
CREATE POLICY "public_insert_vendeur"
ON vendeurs FOR INSERT TO anon
WITH CHECK (true);


-- ════════════════════════════════════════════════
-- SECTION 8 : RLS — COMMISSIONS
-- ════════════════════════════════════════════════

DROP POLICY IF EXISTS "admin_all_commissions" ON commissions;
CREATE POLICY "admin_all_commissions"
ON commissions FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "vendeur_own_commissions" ON commissions;
CREATE POLICY "vendeur_own_commissions"
ON commissions FOR SELECT TO authenticated
USING (
  vendeur_id IN (
    SELECT id FROM vendeurs WHERE auth_user_id = auth.uid()
  )
);


-- ════════════════════════════════════════════════
-- SECTION 9 : RLS — PRODUITS
-- ════════════════════════════════════════════════

DROP POLICY IF EXISTS "public_read_produits_valides" ON produits;
CREATE POLICY "public_read_produits_valides"
ON produits FOR SELECT TO anon
USING (statut = 'validé');

DROP POLICY IF EXISTS "admin_all_produits" ON produits;
CREATE POLICY "admin_all_produits"
ON produits FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role = 'admin'
  )
);

DROP POLICY IF EXISTS "public_insert_produit" ON produits;
CREATE POLICY "public_insert_produit"
ON produits FOR INSERT TO anon
WITH CHECK (true);


-- ════════════════════════════════════════════════
-- SECTION 10 : TRIGGER COMMISSION AUTOMATIQUE
-- ════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION creer_commission_automatique()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.statut = 'validé' AND (OLD.statut IS NULL OR OLD.statut != 'validé') THEN
    IF NOT EXISTS (SELECT 1 FROM commissions WHERE produit_id = NEW.id) THEN
      INSERT INTO commissions (
        produit_id, vendeur_id, montant_vente,
        montant_commission, taux_commission, statut, date_commission
      ) VALUES (
        NEW.id, NEW.vendeur_id, NEW.prix,
        ROUND(NEW.prix * 0.02, 2), 2.00, 'due', now()
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_commission_auto ON produits;
CREATE TRIGGER trigger_commission_auto
  AFTER UPDATE ON produits
  FOR EACH ROW
  EXECUTE FUNCTION creer_commission_automatique();


-- ════════════════════════════════════════════════
-- VÉRIFICATION FINALE
-- ════════════════════════════════════════════════

SELECT p.id, p.nom, p.vendeur_id, p.statut, v.nom AS vendeur, v.email
FROM produits p
LEFT JOIN vendeurs v ON p.vendeur_id = v.id;

SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' ORDER BY tablename;

SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
