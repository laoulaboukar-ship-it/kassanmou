-- ============================================================
-- KASSAN'MOU — Script SQL de nettoyage Supabase
-- À exécuter dans : Supabase Dashboard → SQL Editor
-- ============================================================

-- 1. VOIR tous les produits actuellement en base (diagnostic)
SELECT id, nom, statut, categorie, date_soumission, date_validation
FROM produits
ORDER BY date_soumission DESC;

-- 2. SUPPRIMER les produits de test / fictifs
--    (ceux qui ont des noms génériques ou créés comme test)
DELETE FROM produits
WHERE
  nom ILIKE '%test%'
  OR nom ILIKE '%fictif%'
  OR nom ILIKE '%demo%'
  OR nom ILIKE '%exemple%'
  OR nom ILIKE '%sample%'
  OR nom ILIKE '%essai%'
  -- Supprimer les produits sans vendeur lié
  OR vendeur_id IS NULL
  -- Supprimer les produits avec statut 'en_attente' depuis plus de 30 jours (abandonnés)
  OR (statut = 'en_attente' AND date_soumission < NOW() - INTERVAL '30 days');

-- 3. VÉRIFIER ce qui reste après nettoyage
SELECT id, nom, statut, categorie, date_validation
FROM produits
ORDER BY date_validation DESC;

-- 4. RÉINITIALISER les séquences si nécessaire (optionnel)
-- SELECT setval(pg_get_serial_sequence('produits', 'id'), MAX(id)) FROM produits;

-- ============================================================
-- NOTE : Si vous voulez supprimer UN produit spécifique par son ID
-- copiez l'ID depuis le Centre de Contrôle et utilisez :
-- DELETE FROM produits WHERE id = 'VOTRE-ID-ICI';
-- ============================================================
