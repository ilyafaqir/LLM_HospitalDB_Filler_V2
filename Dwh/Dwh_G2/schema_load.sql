/* ==========================================================
   FULL SCRIPT : DWH (DDL + ETL)
   Source : morocco_health_db
   Cible  : sante_dw
   Compatible MySQL 5.7 / MariaDB (pas de CTE)
   ========================================================== */

SET FOREIGN_KEY_CHECKS = 0;

-- ==========================================================
-- A) DDL : Création du schéma DWH
-- ==========================================================
DROP DATABASE IF EXISTS sante_dw;
CREATE DATABASE IF NOT EXISTS sante_dw
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_general_ci;

USE sante_dw;

DROP TABLE IF EXISTS Fact_Sante;
DROP TABLE IF EXISTS Dim_Hospital;
DROP TABLE IF EXISTS Dim_Supplier;
DROP TABLE IF EXISTS Dim_Element;
DROP TABLE IF EXISTS Dim_Geography;
DROP TABLE IF EXISTS Dim_Date;

CREATE TABLE Dim_Date (
  date_sk INT PRIMARY KEY,          -- YYYYMMDD
  date_value DATE NOT NULL,
  year INT NOT NULL,
  month INT NOT NULL,
  day INT NOT NULL,
  quarter INT NOT NULL,
  month_name VARCHAR(20),
  day_name VARCHAR(20),
  UNIQUE KEY uq_date_value (date_value)
) ENGINE=InnoDB;

CREATE TABLE Dim_Geography (
  geo_sk INT PRIMARY KEY AUTO_INCREMENT,
  place_id_nk INT UNIQUE,           -- morocco_health_db.places.id
  region VARCHAR(100),
  province VARCHAR(100),
  city VARCHAR(100) NOT NULL,
  KEY idx_geo_city (city)
) ENGINE=InnoDB;

CREATE TABLE Dim_Hospital (
  hospital_sk INT PRIMARY KEY AUTO_INCREMENT,
  hospital_id_nk INT UNIQUE,        -- morocco_health_db.hospitals.id
  name VARCHAR(255) NOT NULL,
  type VARCHAR(100),
  beds INT DEFAULT 0,
  phone VARCHAR(100),
  email VARCHAR(150),
  website VARCHAR(255),
  address TEXT,
  geo_sk INT NULL,
  created_at TIMESTAMP NULL,
  KEY idx_dim_hosp_geo (geo_sk),
  CONSTRAINT fk_dim_hospital_geo FOREIGN KEY (geo_sk) REFERENCES Dim_Geography(geo_sk)
) ENGINE=InnoDB;

-- Dimension fournisseurs (sans faits tant qu'il n'y a pas de lien)
CREATE TABLE Dim_Supplier (
  supplier_sk INT PRIMARY KEY AUTO_INCREMENT,
  supplier_id_nk INT UNIQUE,        -- morocco_health_db.suppliers.id
  name VARCHAR(255) NOT NULL,
  category VARCHAR(100),
  activity TEXT,
  city VARCHAR(100),
  address TEXT,
  phone VARCHAR(100),
  responsible_pharmacist VARCHAR(150),
  KEY idx_dim_supplier_city (city)
) ENGINE=InnoDB;

-- Dimension unifiée pour equipment/services/medications
CREATE TABLE Dim_Element (
  element_sk INT PRIMARY KEY AUTO_INCREMENT,
  source_table VARCHAR(30) NOT NULL,   -- 'equipment' | 'services' | 'medications'
  source_id INT NOT NULL,
  type_element VARCHAR(30) NOT NULL,   -- 'EQUIPMENT' | 'SERVICE' | 'MEDICATION'
  name VARCHAR(255) NOT NULL,

  code VARCHAR(50),
  category VARCHAR(100),
  description TEXT,
  active_substance VARCHAR(255),
  dosage VARCHAR(100),
  form VARCHAR(100),
  therapeutic_class VARCHAR(150),
  manufacturer VARCHAR(150),
  price_public DECIMAL(10,2),
  price_hospital DECIMAL(10,2),
  commercialization_status VARCHAR(100),

  UNIQUE KEY uq_element (source_table, source_id),
  KEY idx_element_type (type_element),
  KEY idx_element_name (name)
) ENGINE=InnoDB;

CREATE TABLE Fact_Sante (
  fact_id BIGINT PRIMARY KEY AUTO_INCREMENT,

  date_sk INT NOT NULL,
  geo_sk INT NULL,
  hospital_sk INT NULL,
  supplier_sk INT NULL,
  element_sk INT NOT NULL,

  nature_fait VARCHAR(50) NOT NULL, -- 'HOSPITAL_EQUIPMENT' | 'HOSPITAL_SERVICE'
  quantite INT DEFAULT NULL,

  load_ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_fact_date     FOREIGN KEY (date_sk)     REFERENCES Dim_Date(date_sk),
  CONSTRAINT fk_fact_geo      FOREIGN KEY (geo_sk)      REFERENCES Dim_Geography(geo_sk),
  CONSTRAINT fk_fact_hospital FOREIGN KEY (hospital_sk) REFERENCES Dim_Hospital(hospital_sk),
  CONSTRAINT fk_fact_supplier FOREIGN KEY (supplier_sk) REFERENCES Dim_Supplier(supplier_sk),
  CONSTRAINT fk_fact_element  FOREIGN KEY (element_sk)  REFERENCES Dim_Element(element_sk),

  INDEX idx_fact_date     (date_sk),
  INDEX idx_fact_hospital (hospital_sk),
  INDEX idx_fact_supplier (supplier_sk),
  INDEX idx_fact_element  (element_sk),
  INDEX idx_fact_geo      (geo_sk),

  -- Rend le chargement relançable (snapshot/jour)
  UNIQUE KEY uq_fact_snapshot (date_sk, hospital_sk, supplier_sk, element_sk, nature_fait)
) ENGINE=InnoDB;

-- ==========================================================
-- B) ETL : Chargement des dimensions + faits
-- ==========================================================

-- B1) DIM_DATE : génération sans CTE
SET @start_date := (
  SELECT COALESCE(DATE(MIN(created_at)), CURDATE())
  FROM morocco_health_db.hospitals
);
SET @end_date := CURDATE();

INSERT INTO sante_dw.Dim_Date
(date_sk, date_value, year, month, day, quarter, month_name, day_name)
SELECT
  (YEAR(dt)*10000 + MONTH(dt)*100 + DAY(dt)) AS date_sk,
  dt AS date_value,
  YEAR(dt), MONTH(dt), DAY(dt),
  QUARTER(dt),
  DATE_FORMAT(dt, '%M'),
  DATE_FORMAT(dt, '%W')
FROM (
  SELECT DATE_ADD(@start_date, INTERVAL n DAY) AS dt
  FROM (
    SELECT (a.n + b.n*10 + c.n*100 + d.n*1000) AS n
    FROM
      (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
    CROSS JOIN
      (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
    CROSS JOIN
      (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
    CROSS JOIN
      (SELECT 0 n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
       UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
  ) nums
) dates
WHERE dt <= @end_date
ON DUPLICATE KEY UPDATE
  date_value = VALUES(date_value),
  year = VALUES(year),
  month = VALUES(month),
  day = VALUES(day),
  quarter = VALUES(quarter),
  month_name = VALUES(month_name),
  day_name = VALUES(day_name);

-- (sécurité : ajouter aussi la date du jour au cas où)
SET @today := CURDATE();
SET @today_sk := (YEAR(@today)*10000 + MONTH(@today)*100 + DAY(@today));

INSERT INTO sante_dw.Dim_Date
(date_sk, date_value, year, month, day, quarter, month_name, day_name)
VALUES
(@today_sk, @today, YEAR(@today), MONTH(@today), DAY(@today),
 QUARTER(@today), DATE_FORMAT(@today,'%M'), DATE_FORMAT(@today,'%W'))
ON DUPLICATE KEY UPDATE
  date_value = VALUES(date_value),
  year = VALUES(year),
  month = VALUES(month),
  day = VALUES(day),
  quarter = VALUES(quarter),
  month_name = VALUES(month_name),
  day_name = VALUES(day_name);

-- B2) DIM_GEOGRAPHY : places
INSERT INTO sante_dw.Dim_Geography (place_id_nk, region, province, city)
SELECT p.id, p.region, p.province, p.city
FROM morocco_health_db.places p
ON DUPLICATE KEY UPDATE
  region = VALUES(region),
  province = VALUES(province),
  city = VALUES(city);

-- B3) DIM_HOSPITAL : hospitals (+ geo_sk)
INSERT INTO sante_dw.Dim_Hospital
(hospital_id_nk, name, type, beds, phone, email, website, address, geo_sk, created_at)
SELECT
  h.id,
  h.name,
  h.type,
  h.beds,
  h.phone,
  h.email,
  h.website,
  h.address,
  g.geo_sk,
  h.created_at
FROM morocco_health_db.hospitals h
LEFT JOIN sante_dw.Dim_Geography g ON g.place_id_nk = h.place_id
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  type = VALUES(type),
  beds = VALUES(beds),
  phone = VALUES(phone),
  email = VALUES(email),
  website = VALUES(website),
  address = VALUES(address),
  geo_sk = VALUES(geo_sk),
  created_at = VALUES(created_at);

-- B4) DIM_SUPPLIER : suppliers (dimension seulement)
INSERT INTO sante_dw.Dim_Supplier
(supplier_id_nk, name, category, activity, city, address, phone, responsible_pharmacist)
SELECT
  s.id, s.name, s.category, s.activity, s.city, s.address, NULL, NULL
FROM morocco_health_db.suppliers s
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  category = VALUES(category),
  activity = VALUES(activity),
  city = VALUES(city),
  address = VALUES(address),
  phone = VALUES(phone),
  responsible_pharmacist = VALUES(responsible_pharmacist);

-- B5) DIM_ELEMENT : equipment
INSERT INTO sante_dw.Dim_Element
(source_table, source_id, type_element, name, code, category)
SELECT 'equipment', e.id, 'EQUIPMENT', e.name, e.code, e.category
FROM morocco_health_db.equipment e
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  code = VALUES(code),
  category = VALUES(category);

-- B6) DIM_ELEMENT : services
INSERT INTO sante_dw.Dim_Element
(source_table, source_id, type_element, name, description)
SELECT 'services', s.id, 'SERVICE', s.name, s.description
FROM morocco_health_db.services s
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  description = VALUES(description);

-- B7) DIM_ELEMENT : medications
INSERT INTO sante_dw.Dim_Element
(source_table, source_id, type_element, name,
 active_substance, dosage, form, therapeutic_class, manufacturer,
 price_public, price_hospital, commercialization_status)
SELECT
  'medications', m.id, 'MEDICATION', m.name,
  m.active_substance, m.dosage, m.form, m.therapeutic_class, m.manufacturer,
  m.price_public, m.price_hospital, m.commercialization_status
FROM morocco_health_db.medications m
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  active_substance = VALUES(active_substance),
  dosage = VALUES(dosage),
  form = VALUES(form),
  therapeutic_class = VALUES(therapeutic_class),
  manufacturer = VALUES(manufacturer),
  price_public = VALUES(price_public),
  price_hospital = VALUES(price_hospital),
  commercialization_status = VALUES(commercialization_status);

-- B8) FACT_SANTE : snapshot du jour
-- (Dim_Date est garanti, donc FK date OK)
-- 8.1 Hospital Equipment
INSERT INTO sante_dw.Fact_Sante
(date_sk, geo_sk, hospital_sk, supplier_sk, element_sk, nature_fait, quantite)
SELECT
  @today_sk,
  dh.geo_sk,
  dh.hospital_sk,
  NULL,
  de.element_sk,
  'HOSPITAL_EQUIPMENT',
  he.quantity
FROM morocco_health_db.hospital_equipment he
JOIN sante_dw.Dim_Hospital dh ON dh.hospital_id_nk = he.hospital_id
JOIN sante_dw.Dim_Element de ON de.source_table='equipment' AND de.source_id=he.equipment_id
ON DUPLICATE KEY UPDATE
  quantite = VALUES(quantite),
  load_ts = CURRENT_TIMESTAMP;

-- 8.2 Hospital Services (quantite = 1)
INSERT INTO sante_dw.Fact_Sante
(date_sk, geo_sk, hospital_sk, supplier_sk, element_sk, nature_fait, quantite)
SELECT
  @today_sk,
  dh.geo_sk,
  dh.hospital_sk,
  NULL,
  de.element_sk,
  'HOSPITAL_SERVICE',
  1
FROM morocco_health_db.hospital_services hs
JOIN sante_dw.Dim_Hospital dh ON dh.hospital_id_nk = hs.hospital_id
JOIN sante_dw.Dim_Element de ON de.source_table='services' AND de.source_id=hs.service_id
ON DUPLICATE KEY UPDATE
  quantite = VALUES(quantite),
  load_ts = CURRENT_TIMESTAMP;

SET FOREIGN_KEY_CHECKS = 1;

-- ==========================================================
-- C) Vérifications rapides
-- ==========================================================
SELECT 'Dim_Date' AS table_name, COUNT(*) AS n FROM sante_dw.Dim_Date
UNION ALL SELECT 'Dim_Geography', COUNT(*) FROM sante_dw.Dim_Geography
UNION ALL SELECT 'Dim_Hospital', COUNT(*) FROM sante_dw.Dim_Hospital
UNION ALL SELECT 'Dim_Supplier', COUNT(*) FROM sante_dw.Dim_Supplier
UNION ALL SELECT 'Dim_Element', COUNT(*) FROM sante_dw.Dim_Element
UNION ALL SELECT 'Fact_Sante', COUNT(*) FROM sante_dw.Fact_Sante;
