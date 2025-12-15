-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : lun. 15 déc. 2025 à 14:33
-- Version du serveur : 10.4.32-MariaDB
-- Version de PHP : 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `health_dw`
--

-- --------------------------------------------------------

--
-- Structure de la table `dim_equipment`
--

CREATE TABLE `dim_equipment` (
  `equipment_sk` int(11) NOT NULL,
  `nk_equipment_id` int(11) DEFAULT NULL,
  `equipment_name` varchar(150) NOT NULL,
  `equipment_code` varchar(50) DEFAULT NULL,
  `equipment_category` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `dim_facilitytype`
--

CREATE TABLE `dim_facilitytype` (
  `facility_type_sk` int(11) NOT NULL,
  `facility_type_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `dim_hospital`
--

CREATE TABLE `dim_hospital` (
  `hospital_sk` int(11) NOT NULL,
  `hospital_name` text NOT NULL,
  `name_arabic` text DEFAULT NULL,
  `name_french` text DEFAULT NULL,
  `name_english` text DEFAULT NULL,
  `street_address` text DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `contact_phone` varchar(100) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `operational_status` varchar(100) DEFAULT NULL,
  `year_established` int(11) DEFAULT NULL,
  `year_closed` int(11) DEFAULT NULL,
  `accreditation_licensing` text DEFAULT NULL,
  `historical_notes` text DEFAULT NULL,
  `location_sk` int(11) DEFAULT NULL,
  `facility_type_sk` int(11) DEFAULT NULL,
  `ownership_type_sk` int(11) DEFAULT NULL,
  `source_sk` int(11) DEFAULT NULL,
  `nk_all_hospital_id` int(11) DEFAULT NULL,
  `nk_morocco_hospital_id` int(11) DEFAULT NULL,
  `created_at_src` datetime DEFAULT NULL,
  `hospital_name_clean` varchar(255) GENERATED ALWAYS AS (lcase(trim(coalesce(`hospital_name`,'')))) STORED
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `dim_location`
--

CREATE TABLE `dim_location` (
  `location_sk` int(11) NOT NULL,
  `region` varchar(255) DEFAULT NULL,
  `province` varchar(255) DEFAULT NULL,
  `city` varchar(255) NOT NULL,
  `src_city_id` int(11) DEFAULT NULL,
  `src_place_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `dim_ownershiptype`
--

CREATE TABLE `dim_ownershiptype` (
  `ownership_type_sk` int(11) NOT NULL,
  `ownership_type_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `dim_service`
--

CREATE TABLE `dim_service` (
  `service_sk` int(11) NOT NULL,
  `nk_service_id` int(11) DEFAULT NULL,
  `service_name` varchar(150) NOT NULL,
  `service_description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `dim_source`
--

CREATE TABLE `dim_source` (
  `source_sk` int(11) NOT NULL,
  `source_name` varchar(255) NOT NULL,
  `source_description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `dim_year`
--

CREATE TABLE `dim_year` (
  `year_sk` int(11) NOT NULL,
  `year_value` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `fact_hospital_equipment`
--

CREATE TABLE `fact_hospital_equipment` (
  `hospital_sk` int(11) NOT NULL,
  `equipment_sk` int(11) NOT NULL,
  `year_sk` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `fact_hospital_service`
--

CREATE TABLE `fact_hospital_service` (
  `hospital_sk` int(11) NOT NULL,
  `service_sk` int(11) NOT NULL,
  `year_sk` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `fact_hospital_stats`
--

CREATE TABLE `fact_hospital_stats` (
  `hospital_sk` int(11) NOT NULL,
  `year_sk` int(11) NOT NULL,
  `capacite_theorique` int(11) DEFAULT NULL,
  `capacite_fonctionnelle` int(11) DEFAULT NULL,
  `medecins` int(11) DEFAULT NULL,
  `infirmiers` int(11) DEFAULT NULL,
  `personnel_administratif` int(11) DEFAULT NULL,
  `beds_declared` int(11) DEFAULT NULL,
  `mode_gestion` varchar(255) DEFAULT NULL,
  `statut_juridique` varchar(255) DEFAULT NULL,
  `samu` tinyint(4) DEFAULT NULL,
  `laboratoire` tinyint(4) DEFAULT NULL,
  `radiologie` tinyint(4) DEFAULT NULL,
  `bloc_operatoire` tinyint(4) DEFAULT NULL,
  `salle_reveil` tinyint(4) DEFAULT NULL,
  `salle_isolement` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `dim_equipment`
--
ALTER TABLE `dim_equipment`
  ADD PRIMARY KEY (`equipment_sk`),
  ADD UNIQUE KEY `uq_equipment` (`equipment_name`,`equipment_code`),
  ADD KEY `idx_eq_nk` (`nk_equipment_id`);

--
-- Index pour la table `dim_facilitytype`
--
ALTER TABLE `dim_facilitytype`
  ADD PRIMARY KEY (`facility_type_sk`),
  ADD UNIQUE KEY `uq_facility_type` (`facility_type_name`);

--
-- Index pour la table `dim_hospital`
--
ALTER TABLE `dim_hospital`
  ADD PRIMARY KEY (`hospital_sk`),
  ADD UNIQUE KEY `uq_hosp_name_loc` (`hospital_name_clean`,`location_sk`),
  ADD KEY `idx_hosp_nk_all` (`nk_all_hospital_id`),
  ADD KEY `idx_hosp_nk_morocco` (`nk_morocco_hospital_id`),
  ADD KEY `idx_hosp_loc` (`location_sk`),
  ADD KEY `fk_hosp_fac` (`facility_type_sk`),
  ADD KEY `fk_hosp_own` (`ownership_type_sk`),
  ADD KEY `fk_hosp_src` (`source_sk`);

--
-- Index pour la table `dim_location`
--
ALTER TABLE `dim_location`
  ADD PRIMARY KEY (`location_sk`),
  ADD UNIQUE KEY `uq_location` (`region`,`province`,`city`),
  ADD KEY `idx_loc_city` (`city`),
  ADD KEY `idx_loc_province` (`province`),
  ADD KEY `idx_loc_region` (`region`);

--
-- Index pour la table `dim_ownershiptype`
--
ALTER TABLE `dim_ownershiptype`
  ADD PRIMARY KEY (`ownership_type_sk`),
  ADD UNIQUE KEY `uq_ownership_type` (`ownership_type_name`);

--
-- Index pour la table `dim_service`
--
ALTER TABLE `dim_service`
  ADD PRIMARY KEY (`service_sk`),
  ADD UNIQUE KEY `uq_service` (`service_name`),
  ADD KEY `idx_srv_nk` (`nk_service_id`);

--
-- Index pour la table `dim_source`
--
ALTER TABLE `dim_source`
  ADD PRIMARY KEY (`source_sk`),
  ADD UNIQUE KEY `uq_source` (`source_name`);

--
-- Index pour la table `dim_year`
--
ALTER TABLE `dim_year`
  ADD PRIMARY KEY (`year_sk`),
  ADD UNIQUE KEY `year_value` (`year_value`);

--
-- Index pour la table `fact_hospital_equipment`
--
ALTER TABLE `fact_hospital_equipment`
  ADD PRIMARY KEY (`hospital_sk`,`equipment_sk`,`year_sk`),
  ADD KEY `idx_fhe_year` (`year_sk`),
  ADD KEY `fk_fhe_eq` (`equipment_sk`);

--
-- Index pour la table `fact_hospital_service`
--
ALTER TABLE `fact_hospital_service`
  ADD PRIMARY KEY (`hospital_sk`,`service_sk`,`year_sk`),
  ADD KEY `idx_fhsrv_year` (`year_sk`),
  ADD KEY `fk_fhsrv_srv` (`service_sk`);

--
-- Index pour la table `fact_hospital_stats`
--
ALTER TABLE `fact_hospital_stats`
  ADD PRIMARY KEY (`hospital_sk`,`year_sk`),
  ADD KEY `idx_fhs_year` (`year_sk`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `dim_equipment`
--
ALTER TABLE `dim_equipment`
  MODIFY `equipment_sk` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `dim_facilitytype`
--
ALTER TABLE `dim_facilitytype`
  MODIFY `facility_type_sk` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `dim_hospital`
--
ALTER TABLE `dim_hospital`
  MODIFY `hospital_sk` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `dim_location`
--
ALTER TABLE `dim_location`
  MODIFY `location_sk` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `dim_ownershiptype`
--
ALTER TABLE `dim_ownershiptype`
  MODIFY `ownership_type_sk` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `dim_service`
--
ALTER TABLE `dim_service`
  MODIFY `service_sk` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pour la table `dim_source`
--
ALTER TABLE `dim_source`
  MODIFY `source_sk` int(11) NOT NULL AUTO_INCREMENT;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `dim_hospital`
--
ALTER TABLE `dim_hospital`
  ADD CONSTRAINT `fk_hosp_fac` FOREIGN KEY (`facility_type_sk`) REFERENCES `dim_facilitytype` (`facility_type_sk`),
  ADD CONSTRAINT `fk_hosp_loc` FOREIGN KEY (`location_sk`) REFERENCES `dim_location` (`location_sk`),
  ADD CONSTRAINT `fk_hosp_own` FOREIGN KEY (`ownership_type_sk`) REFERENCES `dim_ownershiptype` (`ownership_type_sk`),
  ADD CONSTRAINT `fk_hosp_src` FOREIGN KEY (`source_sk`) REFERENCES `dim_source` (`source_sk`);

--
-- Contraintes pour la table `fact_hospital_equipment`
--
ALTER TABLE `fact_hospital_equipment`
  ADD CONSTRAINT `fk_fhe_eq` FOREIGN KEY (`equipment_sk`) REFERENCES `dim_equipment` (`equipment_sk`),
  ADD CONSTRAINT `fk_fhe_hosp` FOREIGN KEY (`hospital_sk`) REFERENCES `dim_hospital` (`hospital_sk`),
  ADD CONSTRAINT `fk_fhe_year` FOREIGN KEY (`year_sk`) REFERENCES `dim_year` (`year_sk`);

--
-- Contraintes pour la table `fact_hospital_service`
--
ALTER TABLE `fact_hospital_service`
  ADD CONSTRAINT `fk_fhsrv_hosp` FOREIGN KEY (`hospital_sk`) REFERENCES `dim_hospital` (`hospital_sk`),
  ADD CONSTRAINT `fk_fhsrv_srv` FOREIGN KEY (`service_sk`) REFERENCES `dim_service` (`service_sk`),
  ADD CONSTRAINT `fk_fhsrv_year` FOREIGN KEY (`year_sk`) REFERENCES `dim_year` (`year_sk`);

--
-- Contraintes pour la table `fact_hospital_stats`
--
ALTER TABLE `fact_hospital_stats`
  ADD CONSTRAINT `fk_fhs_hosp` FOREIGN KEY (`hospital_sk`) REFERENCES `dim_hospital` (`hospital_sk`),
  ADD CONSTRAINT `fk_fhs_year` FOREIGN KEY (`year_sk`) REFERENCES `dim_year` (`year_sk`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
