USE health_dw;

SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================================
-- 0) RESET
-- ==========================================================

TRUNCATE TABLE Fact_Hospital_Service;
TRUNCATE TABLE Fact_Hospital_Equipment;
TRUNCATE TABLE Fact_Hospital_Stats;

DELETE FROM Dim_Hospital;       ALTER TABLE Dim_Hospital       AUTO_INCREMENT = 1;
DELETE FROM Dim_Service;        ALTER TABLE Dim_Service        AUTO_INCREMENT = 1;
DELETE FROM Dim_Equipment;      ALTER TABLE Dim_Equipment      AUTO_INCREMENT = 1;
DELETE FROM Dim_Source;         ALTER TABLE Dim_Source         AUTO_INCREMENT = 1;
DELETE FROM Dim_OwnershipType;  ALTER TABLE Dim_OwnershipType  AUTO_INCREMENT = 1;
DELETE FROM Dim_FacilityType;   ALTER TABLE Dim_FacilityType   AUTO_INCREMENT = 1;
DELETE FROM Dim_Location;       ALTER TABLE Dim_Location       AUTO_INCREMENT = 1;
DELETE FROM Dim_Year;

SET FOREIGN_KEY_CHECKS = 1;

-- Important pour les conversions/valeurs littérales
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================
-- 1) LOAD DIMENSIONS
-- ==========================================================

/* 1.1 Dim_Year */
INSERT IGNORE INTO Dim_Year (year_sk, year_value)
SELECT DISTINCT y, y
FROM (
  SELECT YEAR(CURDATE()) AS y
  UNION
  SELECT COALESCE(hsm.annee_mise_service, YEAR(CURDATE())) AS y
  FROM all_data_db.hospital_stats_moh hsm
  UNION
  SELECT COALESCE(h.year_established, YEAR(CURDATE())) AS y
  FROM all_data_db.hospitals h
  UNION
  SELECT YEAR(h2.created_at) AS y
  FROM morocco_health_db.hospitals h2
) t
WHERE y IS NOT NULL;

/* 1.2 Dim_Location depuis all_data_db (avec src_city_id) */
INSERT IGNORE INTO Dim_Location (region, province, city, src_city_id)
SELECT
  r.name AS region,
  p.name AS province,
  c.name AS city,
  c.city_id AS src_city_id
FROM all_data_db.cities c
LEFT JOIN all_data_db.provinces p ON p.province_id = c.province_id
LEFT JOIN all_data_db.regions r ON r.region_id = COALESCE(c.region_id, p.region_id);

/* 1.3 Dim_Location depuis morocco_health_db.places (avec src_place_id) */
INSERT IGNORE INTO Dim_Location (region, province, city, src_place_id)
SELECT
  pl.region,
  pl.province,
  pl.city,
  pl.id
FROM morocco_health_db.places pl;

/* 1.4 Dim_FacilityType */
INSERT IGNORE INTO Dim_FacilityType (facility_type_name)
SELECT ft.name
FROM all_data_db.facility_types ft;

INSERT IGNORE INTO Dim_FacilityType (facility_type_name)
SELECT DISTINCT (CONVERT(TRIM(h2.type) USING utf8mb4) COLLATE utf8mb4_unicode_ci)
FROM morocco_health_db.hospitals h2
WHERE h2.type IS NOT NULL AND TRIM(h2.type) <> '';

/* 1.5 Dim_OwnershipType */
INSERT IGNORE INTO Dim_OwnershipType (ownership_type_name) VALUES ('UNKNOWN');
INSERT IGNORE INTO Dim_OwnershipType (ownership_type_name)
SELECT ot.name
FROM all_data_db.ownership_types ot;

/* 1.6 Dim_Source */
INSERT IGNORE INTO Dim_Source (source_name, source_description)
VALUES ('UNKNOWN', 'Valeur par défaut quand la source est inconnue');

INSERT IGNORE INTO Dim_Source (source_name, source_description)
SELECT s.name, s.description
FROM all_data_db.sources s;

/* 1.7 Dim_Equipment */
INSERT IGNORE INTO Dim_Equipment (nk_equipment_id, equipment_name, equipment_code, equipment_category)
SELECT e.id, e.name, e.code, e.category
FROM morocco_health_db.equipment e;

/* 1.8 Dim_Service */
INSERT IGNORE INTO Dim_Service (nk_service_id, service_name, service_description)
SELECT s.id, s.name, s.description
FROM morocco_health_db.services s;

/* 1.9 Dim_Hospital depuis all_data_db : join Location par src_city_id (pas de texte) */
INSERT INTO Dim_Hospital (
  hospital_name, name_arabic, name_french, name_english,
  street_address, latitude, longitude,
  contact_phone, contact_email, website,
  operational_status, year_established, year_closed,
  accreditation_licensing, historical_notes,
  location_sk, facility_type_sk, ownership_type_sk, source_sk,
  nk_all_hospital_id
)
SELECT
  COALESCE(
    NULLIF(TRIM(h.display_name), ''),
    NULLIF(TRIM(h.name_french), ''),
    NULLIF(TRIM(h.name_english), ''),
    NULLIF(TRIM(h.name_arabic), ''),
    CONCAT('HOSP_', h.hospital_id)
  ) AS hospital_name,
  h.name_arabic, h.name_french, h.name_english,
  h.street_address, h.latitude, h.longitude,
  h.contact_phone, h.contact_email, h.website,
  h.operational_status, h.year_established, h.year_closed,
  h.accreditation_licensing, h.historical_notes,
  dl.location_sk AS location_sk,
  dft.facility_type_sk AS facility_type_sk,
  dot.ownership_type_sk AS ownership_type_sk,
  ds.source_sk AS source_sk,
  h.hospital_id AS nk_all_hospital_id
FROM all_data_db.hospitals h
LEFT JOIN Dim_Location dl
  ON dl.src_city_id = h.city_id
LEFT JOIN all_data_db.facility_types ft
  ON ft.facility_type_id = h.facility_type_id
LEFT JOIN Dim_FacilityType dft
  ON dft.facility_type_name = ft.name
LEFT JOIN all_data_db.ownership_types ot
  ON ot.ownership_type_id = h.ownership_type_id
LEFT JOIN Dim_OwnershipType dot
  ON dot.ownership_type_name = COALESCE(ot.name, 'UNKNOWN')
LEFT JOIN all_data_db.sources s
  ON s.source_id = h.source_id
LEFT JOIN Dim_Source ds
  ON ds.source_name = COALESCE(s.name, 'UNKNOWN')
ON DUPLICATE KEY UPDATE
  Dim_Hospital.nk_all_hospital_id = VALUES(nk_all_hospital_id),
  Dim_Hospital.location_sk = COALESCE(VALUES(location_sk), Dim_Hospital.location_sk),
  Dim_Hospital.facility_type_sk = COALESCE(VALUES(facility_type_sk), Dim_Hospital.facility_type_sk),
  Dim_Hospital.ownership_type_sk = COALESCE(VALUES(ownership_type_sk), Dim_Hospital.ownership_type_sk),
  Dim_Hospital.source_sk = COALESCE(VALUES(source_sk), Dim_Hospital.source_sk);

/* 1.10 Dim_Hospital depuis morocco_health_db : join Location par src_place_id (pas de texte) */
INSERT INTO Dim_Hospital (
  hospital_name,
  street_address, contact_phone, contact_email, website,
  year_established,
  location_sk, facility_type_sk, ownership_type_sk, source_sk,
  nk_morocco_hospital_id,
  created_at_src
)
SELECT
  (CONVERT(TRIM(h2.name) USING utf8mb4) COLLATE utf8mb4_unicode_ci) AS hospital_name,
  h2.address, h2.phone, h2.email, h2.website,
  YEAR(h2.created_at) AS year_established,
  dl.location_sk AS location_sk,
  dft.facility_type_sk AS facility_type_sk,
  dot.ownership_type_sk AS ownership_type_sk,
  ds.source_sk AS source_sk,
  h2.id AS nk_morocco_hospital_id,
  h2.created_at
FROM morocco_health_db.hospitals h2
LEFT JOIN Dim_Location dl
  ON dl.src_place_id = h2.place_id
LEFT JOIN Dim_FacilityType dft
  ON dft.facility_type_name
     = (CONVERT(TRIM(h2.type) USING utf8mb4) COLLATE utf8mb4_unicode_ci)
LEFT JOIN Dim_OwnershipType dot
  ON dot.ownership_type_name = 'UNKNOWN'
LEFT JOIN Dim_Source ds
  ON ds.source_name = 'UNKNOWN'
ON DUPLICATE KEY UPDATE
  Dim_Hospital.nk_morocco_hospital_id = COALESCE(VALUES(nk_morocco_hospital_id), Dim_Hospital.nk_morocco_hospital_id),
  Dim_Hospital.created_at_src = COALESCE(VALUES(created_at_src), Dim_Hospital.created_at_src),
  Dim_Hospital.location_sk = COALESCE(VALUES(location_sk), Dim_Hospital.location_sk),
  Dim_Hospital.facility_type_sk = COALESCE(VALUES(facility_type_sk), Dim_Hospital.facility_type_sk);

-- ==========================================================
-- 2) LOAD FACTS
-- ==========================================================

/* 2.1 Fact_Hospital_Stats depuis hospital_stats_moh */
INSERT INTO Fact_Hospital_Stats (
  hospital_sk, year_sk,
  capacite_theorique, capacite_fonctionnelle,
  medecins, infirmiers, personnel_administratif,
  mode_gestion, statut_juridique,
  samu, laboratoire, radiologie, bloc_operatoire, salle_reveil, salle_isolement
)
SELECT
  dh.hospital_sk,
  dy.year_sk,
  hsm.capacite_theorique,
  hsm.capacite_fonctionnelle,
  hsm.medecins,
  hsm.infirmiers,
  hsm.personnel_administratif,
  hsm.mode_gestion,
  hsm.statut_juridique,
  CASE WHEN LOWER(COALESCE(hsm.samu,'')) IN ('oui','yes','1','true') THEN 1 WHEN hsm.samu IS NULL THEN NULL ELSE 0 END,
  CASE WHEN LOWER(COALESCE(hsm.laboratoire,'')) IN ('oui','yes','1','true') THEN 1 WHEN hsm.laboratoire IS NULL THEN NULL ELSE 0 END,
  CASE WHEN LOWER(COALESCE(hsm.radiologie,'')) IN ('oui','yes','1','true') THEN 1 WHEN hsm.radiologie IS NULL THEN NULL ELSE 0 END,
  CASE WHEN LOWER(COALESCE(hsm.bloc_operatoire,'')) IN ('oui','yes','1','true') THEN 1 WHEN hsm.bloc_operatoire IS NULL THEN NULL ELSE 0 END,
  CASE WHEN LOWER(COALESCE(hsm.salle_reveil,'')) IN ('oui','yes','1','true') THEN 1 WHEN hsm.salle_reveil IS NULL THEN NULL ELSE 0 END,
  CASE WHEN LOWER(COALESCE(hsm.salle_isolement,'')) IN ('oui','yes','1','true') THEN 1 WHEN hsm.salle_isolement IS NULL THEN NULL ELSE 0 END
FROM all_data_db.hospital_stats_moh hsm
JOIN Dim_Hospital dh ON dh.nk_all_hospital_id = hsm.hospital_id
JOIN Dim_Year dy ON dy.year_value = COALESCE(hsm.annee_mise_service, YEAR(CURDATE()))
ON DUPLICATE KEY UPDATE
  capacite_theorique = VALUES(capacite_theorique),
  capacite_fonctionnelle = VALUES(capacite_fonctionnelle),
  medecins = VALUES(medecins),
  infirmiers = VALUES(infirmiers),
  personnel_administratif = VALUES(personnel_administratif);

/* 2.2 Beds depuis morocco_health_db.hospitals */
INSERT INTO Fact_Hospital_Stats (hospital_sk, year_sk, beds_declared)
SELECT
  dh.hospital_sk,
  dy.year_sk,
  h2.beds
FROM morocco_health_db.hospitals h2
JOIN Dim_Hospital dh ON dh.nk_morocco_hospital_id = h2.id
JOIN Dim_Year dy ON dy.year_value = COALESCE(YEAR(h2.created_at), YEAR(CURDATE()))
ON DUPLICATE KEY UPDATE
  beds_declared = COALESCE(VALUES(beds_declared), beds_declared);

/* 2.3 Fact_Hospital_Equipment (snapshot année courante) */
INSERT INTO Fact_Hospital_Equipment (hospital_sk, equipment_sk, year_sk, quantity)
SELECT
  dh.hospital_sk,
  de.equipment_sk,
  dy.year_sk,
  SUM(COALESCE(he.quantity, 0)) AS qty
FROM morocco_health_db.hospital_equipment he
JOIN Dim_Hospital dh ON dh.nk_morocco_hospital_id = he.hospital_id
JOIN Dim_Equipment de ON de.nk_equipment_id = he.equipment_id
JOIN Dim_Year dy ON dy.year_value = YEAR(CURDATE())
GROUP BY dh.hospital_sk, de.equipment_sk, dy.year_sk
ON DUPLICATE KEY UPDATE quantity = VALUES(quantity);

/* 2.4 Fact_Hospital_Service (factless année courante) */
INSERT IGNORE INTO Fact_Hospital_Service (hospital_sk, service_sk, year_sk)
SELECT
  dh.hospital_sk,
  ds.service_sk,
  dy.year_sk
FROM morocco_health_db.hospital_services hs
JOIN Dim_Hospital dh ON dh.nk_morocco_hospital_id = hs.hospital_id
JOIN Dim_Service ds ON ds.nk_service_id = hs.service_id
JOIN Dim_Year dy ON dy.year_value = YEAR(CURDATE());

-- ==========================================================
-- 3) CHECK
-- ==========================================================
SELECT
  (SELECT COUNT(*) FROM Dim_Hospital) AS dim_hospital,
  (SELECT COUNT(*) FROM Dim_Equipment) AS dim_equipment,
  (SELECT COUNT(*) FROM Dim_Service) AS dim_service,
  (SELECT COUNT(*) FROM Fact_Hospital_Equipment) AS fact_equipment,
  (SELECT COUNT(*) FROM Fact_Hospital_Service) AS fact_service,
  (SELECT COUNT(*) FROM Fact_Hospital_Stats) AS fact_stats;
