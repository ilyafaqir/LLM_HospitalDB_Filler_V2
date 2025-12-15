-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1
-- Généré le : lun. 15 déc. 2025 à 14:26
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
-- Base de données : `all_data_db`
--

-- --------------------------------------------------------

--
-- Structure de la table `cities`
--

CREATE TABLE `cities` (
  `city_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `province_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `facility_types`
--

CREATE TABLE `facility_types` (
  `facility_type_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `hospitals`
--

CREATE TABLE `hospitals` (
  `hospital_id` int(11) NOT NULL,
  `name_arabic` text DEFAULT NULL,
  `name_french` text DEFAULT NULL,
  `name_english` text DEFAULT NULL,
  `display_name` text DEFAULT NULL,
  `city_id` int(11) DEFAULT NULL,
  `province_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  `street_address` text DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `facility_type_id` int(11) DEFAULT NULL,
  `ownership_type_id` int(11) DEFAULT NULL,
  `operational_status` varchar(100) DEFAULT NULL,
  `capacity_beds` int(11) DEFAULT NULL,
  `services_specializations` text DEFAULT NULL,
  `contact_phone` varchar(100) DEFAULT NULL,
  `contact_email` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `year_established` int(11) DEFAULT NULL,
  `year_closed` int(11) DEFAULT NULL,
  `accreditation_licensing` text DEFAULT NULL,
  `historical_notes` text DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  `source_record_key` varchar(255) DEFAULT NULL,
  `raw_source` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `hospital_reports`
--

CREATE TABLE `hospital_reports` (
  `report_id` int(11) NOT NULL,
  `hospital_name` text DEFAULT NULL,
  `report_type` varchar(255) DEFAULT NULL,
  `report_period` varchar(255) DEFAULT NULL,
  `source_name` varchar(255) DEFAULT NULL,
  `raw_json` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `hospital_stats_moh`
--

CREATE TABLE `hospital_stats_moh` (
  `stat_id` int(11) NOT NULL,
  `hospital_id` int(11) DEFAULT NULL,
  `annee_mise_service` int(11) DEFAULT NULL,
  `capacite_theorique` int(11) DEFAULT NULL,
  `capacite_fonctionnelle` int(11) DEFAULT NULL,
  `medecins` int(11) DEFAULT NULL,
  `infirmiers` int(11) DEFAULT NULL,
  `personnel_administratif` int(11) DEFAULT NULL,
  `mode_gestion` varchar(255) DEFAULT NULL,
  `statut_juridique` varchar(255) DEFAULT NULL,
  `services_specialises` text DEFAULT NULL,
  `equipements_biomedicaux` text DEFAULT NULL,
  `samu` varchar(50) DEFAULT NULL,
  `laboratoire` varchar(50) DEFAULT NULL,
  `radiologie` varchar(50) DEFAULT NULL,
  `bloc_operatoire` varchar(50) DEFAULT NULL,
  `salle_reveil` varchar(50) DEFAULT NULL,
  `salle_isolement` varchar(50) DEFAULT NULL,
  `conseil_administration` varchar(50) DEFAULT NULL,
  `comites_consultatifs` varchar(50) DEFAULT NULL,
  `projet_etablissement` varchar(50) DEFAULT NULL,
  `systeme_information` varchar(50) DEFAULT NULL,
  `observations_cour_comptes` text DEFAULT NULL,
  `recommandations` text DEFAULT NULL,
  `reponse_ministere` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `ownership_types`
--

CREATE TABLE `ownership_types` (
  `ownership_type_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `provinces`
--

CREATE TABLE `provinces` (
  `province_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `region_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `regions`
--

CREATE TABLE `regions` (
  `region_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `sources`
--

CREATE TABLE `sources` (
  `source_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `cities`
--
ALTER TABLE `cities`
  ADD PRIMARY KEY (`city_id`),
  ADD UNIQUE KEY `uq_city_name_province` (`name`,`province_id`),
  ADD KEY `idx_cities_province` (`province_id`),
  ADD KEY `idx_cities_region` (`region_id`);

--
-- Index pour la table `facility_types`
--
ALTER TABLE `facility_types`
  ADD PRIMARY KEY (`facility_type_id`),
  ADD UNIQUE KEY `uq_facility_types_name` (`name`);

--
-- Index pour la table `hospitals`
--
ALTER TABLE `hospitals`
  ADD PRIMARY KEY (`hospital_id`),
  ADD KEY `idx_hosp_city` (`city_id`),
  ADD KEY `idx_hosp_province` (`province_id`),
  ADD KEY `idx_hosp_region` (`region_id`),
  ADD KEY `idx_hosp_facility_type` (`facility_type_id`),
  ADD KEY `idx_hosp_ownership_type` (`ownership_type_id`),
  ADD KEY `idx_hosp_source` (`source_id`);

--
-- Index pour la table `hospital_reports`
--
ALTER TABLE `hospital_reports`
  ADD PRIMARY KEY (`report_id`);

--
-- Index pour la table `hospital_stats_moh`
--
ALTER TABLE `hospital_stats_moh`
  ADD PRIMARY KEY (`stat_id`),
  ADD KEY `idx_stats_hospital` (`hospital_id`);

--
-- Index pour la table `ownership_types`
--
ALTER TABLE `ownership_types`
  ADD PRIMARY KEY (`ownership_type_id`),
  ADD UNIQUE KEY `uq_ownership_types_name` (`name`);

--
-- Index pour la table `provinces`
--
ALTER TABLE `provinces`
  ADD PRIMARY KEY (`province_id`),
  ADD UNIQUE KEY `uq_provinces_name` (`name`),
  ADD KEY `idx_provinces_region` (`region_id`);

--
-- Index pour la table `regions`
--
ALTER TABLE `regions`
  ADD PRIMARY KEY (`region_id`),
  ADD UNIQUE KEY `uq_regions_name` (`name`);

--
-- Index pour la table `sources`
--
ALTER TABLE `sources`
  ADD PRIMARY KEY (`source_id`),
  ADD UNIQUE KEY `uq_sources_name` (`name`);

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `cities`
--
ALTER TABLE `cities`
  ADD CONSTRAINT `fk_cities_province` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`province_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_cities_region` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Contraintes pour la table `hospitals`
--
ALTER TABLE `hospitals`
  ADD CONSTRAINT `fk_hosp_city` FOREIGN KEY (`city_id`) REFERENCES `cities` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hosp_facility_type` FOREIGN KEY (`facility_type_id`) REFERENCES `facility_types` (`facility_type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hosp_ownership_type` FOREIGN KEY (`ownership_type_id`) REFERENCES `ownership_types` (`ownership_type_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hosp_province` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`province_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hosp_region` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hosp_source` FOREIGN KEY (`source_id`) REFERENCES `sources` (`source_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Contraintes pour la table `hospital_stats_moh`
--
ALTER TABLE `hospital_stats_moh`
  ADD CONSTRAINT `fk_stats_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospitals` (`hospital_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Contraintes pour la table `provinces`
--
ALTER TABLE `provinces`
  ADD CONSTRAINT `fk_provinces_region` FOREIGN KEY (`region_id`) REFERENCES `regions` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
