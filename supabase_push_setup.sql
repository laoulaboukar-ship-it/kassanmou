-- ══════════════════════════════════════════════════════════
-- Kassan'Mou v65b — Setup Push Notifications
-- À exécuter dans Supabase → SQL Editor
-- ══════════════════════════════════════════════════════════

-- 1. Table des abonnements push
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  endpoint    text NOT NULL UNIQUE,
  p256dh      text,
  auth        text,
  vendeur_id  uuid REFERENCES vendeurs(id) ON DELETE SET NULL,
  role        text DEFAULT 'acheteur' CHECK (role IN ('admin','vendeur','acheteur')),
  user_agent  text,
  created_at  timestamptz DEFAULT now(),
  updated_at  timestamptz DEFAULT now()
);

-- 2. RLS : seul l'admin peut lire toutes les subscriptions
ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut créer/mettre à jour sa propre subscription
CREATE POLICY "push_insert_own" ON push_subscriptions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "push_update_own" ON push_subscriptions
  FOR UPDATE USING (endpoint = endpoint);

-- Seul l'admin peut lire (pour envoyer les pushs)
CREATE POLICY "push_admin_read" ON push_subscriptions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );

-- 3. Index pour performance
CREATE INDEX IF NOT EXISTS push_subs_role_idx      ON push_subscriptions(role);
CREATE INDEX IF NOT EXISTS push_subs_vendeur_idx   ON push_subscriptions(vendeur_id);
CREATE INDEX IF NOT EXISTS push_subs_endpoint_idx  ON push_subscriptions(endpoint);

-- ══════════════════════════════════════════════════════════
-- NETTOYAGE COLONNES EN DOUBLE (Tâche 4 Phase 4)
-- Exécuter seulement après avoir vérifié que v65a est en prod
-- ══════════════════════════════════════════════════════════

-- Supprimer la colonne montant redondante (remplacée par montant_commission)
-- ALTER TABLE commissions DROP COLUMN IF EXISTS montant;
-- ALTER TABLE commissions DROP COLUMN IF EXISTS date_paiement;
-- (Décommenter après validation en production)

SELECT 'Setup push_subscriptions OK ✅' as status;
