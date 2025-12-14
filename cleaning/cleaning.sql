-- ==========================================================
-- 1. DROP UNUSED COLUMNS
-- ==========================================================
ALTER TABLE suppliers
DROP COLUMN phone,
DROP COLUMN responsible_pharmacist;

-- ==========================================================
-- 2. BASIC STANDARDIZATION
-- ==========================================================
-- Upper case and trim everything to make matching easier
UPDATE suppliers
SET 
    name = UPPER(TRIM(name)),
    category = UPPER(TRIM(category)),
    activity = TRIM(activity),
    address = UPPER(TRIM(address));

-- ==========================================================
-- 3. EXTRACT CITY FROM ADDRESS
-- ==========================================================
-- This fills the empty 'city' column by finding city names hidden in the address
UPDATE suppliers
SET city = CASE
    -- Major Cities
    WHEN address LIKE '%CASABLANCA%' THEN 'CASABLANCA'
    WHEN address LIKE '%RABAT%' THEN 'RABAT'
    WHEN address LIKE '%TANGER%' THEN 'TANGER'
    WHEN address LIKE '%MARRAKECH%' THEN 'MARRAKECH'
    WHEN address LIKE '%AGADIR%' THEN 'AGADIR'
    WHEN address LIKE '%FES%' OR address LIKE '%FÈS%' THEN 'FES'
    WHEN address LIKE '%TIFLET%' THEN 'TIFLET'
    WHEN address LIKE '%TEMARA%' OR address LIKE '%TÉMARA%' THEN 'TEMARA'
    WHEN address LIKE '%SALE%' OR address LIKE '%SALÉ%' THEN 'SALE'
    WHEN address LIKE '%KENITRA%' THEN 'KENITRA'
    WHEN address LIKE '%MOHAMMEDIA%' THEN 'MOHAMMEDIA'
    
    -- Neighborhoods (Clean based on your image)
    WHEN address LIKE '%SIDI MAAROUF%' OR address LIKE '%SIDI MOUMEN%' THEN 'CASABLANCA'
    WHEN address LIKE '%HAY RIYAD%' OR address LIKE '%HAY RIAD%' THEN 'RABAT'
    
    ELSE city 
END
WHERE city IS NULL OR city = 'NULL' OR city = '';

-- ==========================================================
-- 4. CLEAN ADDRESS TEXT
-- ==========================================================

-- Fix "N22RUE" -> "N 22 RUE" (adds space between number and text)
UPDATE suppliers
SET address = REGEXP_REPLACE(address, '([0-9])([A-Z])', '$1 $2');

-- Fix "11.RUE" -> "11. RUE" (adds space after dot)
UPDATE suppliers
SET address = REPLACE(address, '.', '. ');

-- Remove "MAROC" from the address field since we know the country
UPDATE suppliers
SET address = TRIM(REPLACE(REPLACE(address, ' MAROC', ''), ' MOROCCO', ''));
-- ==========================================================
-- 1. REMOVE ARABIC CHARACTERS & NOISE
-- ==========================================================
-- Logic: Keep only Latin letters (A-Z), Accents (éè...), Spaces, and Hyphens.
-- This effectively removes Arabic script without breaking names like "Témara".

UPDATE places
SET city = TRIM(REGEXP_REPLACE(city, '[^a-zA-Z0-9 àâäéèêëîïôöùûüçÀÂÄÉÈÊËÎÏÔÖÙÛÜÇ-]', ''))
WHERE city REGEXP '[^a-zA-Z0-9 ]';

-- ==========================================================
-- 2. STANDARDIZE TEXT
-- ==========================================================
UPDATE places
SET 
    city = UPPER(TRIM(city)),
    region = NULLIF(region, 'NULL'),
    province = NULLIF(province, 'NULL');

-- ==========================================================
-- 3. CLEAN "NOISY" NEIGHBORHOOD NAMES
-- ==========================================================
-- Removes extra details to standardize on the main City name

-- Fix "FES MDINA..." -> "FES"
UPDATE places 
SET city = 'FES' 
WHERE city LIKE 'FES %' OR city LIKE 'FÈS %';

-- Fix "MARRAKECH GUELIZ..." -> "MARRAKECH"
UPDATE places 
SET city = 'MARRAKECH' 
WHERE city LIKE 'MARRAKECH %';

-- Fix "TANGER MEDINA..." -> "TANGER"
UPDATE places 
SET city = 'TANGER' 
WHERE city LIKE 'TANGER %';

-- Fix "CASABLANCA ANFA..." -> "CASABLANCA"
UPDATE places 
SET city = 'CASABLANCA' 
WHERE city LIKE 'CASABLANCA %';

-- ==========================================================
-- 4. FILL MISSING REGIONS (Hardcoded Fixes)
-- ==========================================================
-- Fills in the specific NULL rows seen in your file

UPDATE places 
SET region = 'Rabat-Salé-Kénitra', province = 'Skhirate-Témara'
WHERE city = 'TEMARA' AND region IS NULL;

UPDATE places 
SET region = 'Béni Mellal-Khénifra', province = 'Béni Mellal'
WHERE city = 'BENI MELLAL' AND region IS NULL;

UPDATE places 
SET region = 'Casablanca-Settat', province = 'Settat'
WHERE city = 'SETTAT' AND region IS NULL;

UPDATE places 
SET region = 'Béni Mellal-Khénifra', province = 'Azilal'
WHERE city = 'AIT OUQABLI' AND region IS NULL;

-- ==========================================================
-- 5. SELF-HEALING (Auto-Fill remaining NULLs)
-- ==========================================================
-- If "Agadir" has region data in row 1, copy it to row 50
UPDATE places p1
JOIN places p2 ON p1.city = p2.city
SET 
    p1.region = p2.region,
    p1.province = p2.province
WHERE 
    p1.region IS NULL 
    AND p2.region IS NOT NULL
    AND p1.id <> p2.id;

-- ==========================================================
-- STEP 1: STANDARDIZE CITY NAMES (Fix duplicates/variations)
-- ==========================================================

-- Standardize FEZ variations
UPDATE places SET city = 'FES' WHERE city IN ('FEZ', 'FÈS', 'FEŞ');

-- Standardize SALE variations
UPDATE places SET city = 'SALE' WHERE city = 'SALÉ';

-- Standardize TEMARA variations
UPDATE places SET city = 'TEMARA' WHERE city = 'TÉMARA';

-- Standardize other common variations
UPDATE places SET city = 'KENITRA' WHERE city = 'KÉNITRA';
UPDATE places SET city = 'MEKNES' WHERE city = 'MEKNÈS';
UPDATE places SET city = 'TETOUAN' WHERE city = 'TÉTOUAN';

-- ==========================================================
-- STEP 2: FILL ALL REGIONS AND PROVINCES
-- ==========================================================

UPDATE places
SET 
    region = CASE city
        -- Casablanca-Settat Region
        WHEN 'CASABLANCA' THEN 'Casablanca-Settat'
        WHEN 'MOHAMMEDIA' THEN 'Casablanca-Settat'
        WHEN 'SETTAT' THEN 'Casablanca-Settat'
        WHEN 'BERRECHID' THEN 'Casablanca-Settat'
        WHEN 'EL JADIDA' THEN 'Casablanca-Settat'
        WHEN 'CHEMAIA' THEN 'Casablanca-Settat'
        WHEN 'ECHEMMAIA' THEN 'Casablanca-Settat'
        WHEN 'BENSLIMANE' THEN 'Casablanca-Settat'
        WHEN 'MEDIOUNA' THEN 'Casablanca-Settat'
        
        -- Rabat-Salé-Kénitra Region
        WHEN 'RABAT' THEN 'Rabat-Salé-Kénitra'
        WHEN 'SALE' THEN 'Rabat-Salé-Kénitra'
        WHEN 'TEMARA' THEN 'Rabat-Salé-Kénitra'
        WHEN 'KENITRA' THEN 'Rabat-Salé-Kénitra'
        WHEN 'TIFLET' THEN 'Rabat-Salé-Kénitra'
        WHEN 'SIDI ALI BELKACEM' THEN 'Rabat-Salé-Kénitra'
        WHEN 'KHEMISSET' THEN 'Rabat-Salé-Kénitra'
        WHEN 'SIDI KACEM' THEN 'Rabat-Salé-Kénitra'
        WHEN 'SKHIRAT' THEN 'Rabat-Salé-Kénitra'
        WHEN 'RUE MOHAMED EL HANSALI FES' THEN 'Rabat-Salé-Kénitra'
        
        -- Fès-Meknès Region
        WHEN 'FES' THEN 'Fès-Meknès'
        WHEN 'MEKNES' THEN 'Fès-Meknès'
        WHEN 'TAZA' THEN 'Fès-Meknès'
        WHEN 'IFRANE' THEN 'Fès-Meknès'
        WHEN 'SEFROU' THEN 'Fès-Meknès'
        WHEN 'EL HAJEB' THEN 'Fès-Meknès'
        
        -- Tanger-Tétouan-Al Hoceïma Region
        WHEN 'TANGER' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'TETOUAN' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'LARACHE' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'OUAZZANE' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'BELYOUNECH' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'ASSILAH' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'CHEFCHAOUEN' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'AL HOCEIMA' THEN 'Tanger-Tétouan-Al Hoceïma'
        WHEN 'FNIDEQ' THEN 'Tanger-Tétouan-Al Hoceïma'
        
        -- Souss-Massa Region
        WHEN 'AGADIR' THEN 'Souss-Massa'
        WHEN 'TIZNIT' THEN 'Souss-Massa'
        WHEN 'TIMITAR' THEN 'Souss-Massa'
        WHEN 'DRARGA' THEN 'Souss-Massa'
        WHEN 'INEZGANE' THEN 'Souss-Massa'
        WHEN 'AIT MELLOUL' THEN 'Souss-Massa'
        WHEN 'TAROUDANT' THEN 'Souss-Massa'
        WHEN 'TATA' THEN 'Souss-Massa'
        
        -- Marrakech-Safi Region
        WHEN 'MARRAKECH' THEN 'Marrakech-Safi'
        WHEN 'YOUSSOUFIA' THEN 'Marrakech-Safi'
        WHEN 'SAFI' THEN 'Marrakech-Safi'
        WHEN 'ESSAOUIRA' THEN 'Marrakech-Safi'
        WHEN 'KELAA DES SRAGHNA' THEN 'Marrakech-Safi'
        
        -- Béni Mellal-Khénifra Region
        WHEN 'KHOURIBGA' THEN 'Béni Mellal-Khénifra'
        WHEN 'CHP KHOURIBGA' THEN 'Béni Mellal-Khénifra'
        WHEN 'BENI MELLAL' THEN 'Béni Mellal-Khénifra'
        WHEN 'AZILAL' THEN 'Béni Mellal-Khénifra'
        WHEN 'KHENIFRA' THEN 'Béni Mellal-Khénifra'
        WHEN 'FQUIH BEN SALAH' THEN 'Béni Mellal-Khénifra'
        
        -- Oriental Region
        WHEN 'OUJDA' THEN 'Oriental'
        WHEN 'NADOR' THEN 'Oriental'
        WHEN 'BERKANE' THEN 'Oriental'
        WHEN 'TAOURIRT' THEN 'Oriental'
        WHEN 'TAURIRT' THEN 'Oriental'
        WHEN 'JERADA' THEN 'Oriental'
        WHEN 'FIGUIG' THEN 'Oriental'
        
        -- Drâa-Tafilalet Region
        WHEN 'ERRACHIDIA' THEN 'Drâa-Tafilalet'
        WHEN 'OUARZAZATE' THEN 'Drâa-Tafilalet'
        WHEN 'TINGHIR' THEN 'Drâa-Tafilalet'
        WHEN 'ZAGORA' THEN 'Drâa-Tafilalet'
        
        -- Laâyoune-Sakia El Hamra Region
        WHEN 'LAAYOUNE' THEN 'Laâyoune-Sakia El Hamra'
        
        -- Dakhla-Oued Ed-Dahab Region
        WHEN 'DAKHLA' THEN 'Dakhla-Oued Ed-Dahab'
        
        -- Guelmim-Oued Noun Region
        WHEN 'GUELMIM' THEN 'Guelmim-Oued Noun'
        WHEN 'TAN-TAN' THEN 'Guelmim-Oued Noun'
        WHEN 'SIDI IFNI' THEN 'Guelmim-Oued Noun'
        WHEN 'ASSA-ZAG' THEN 'Guelmim-Oued Noun'
        WHEN 'TOULAL' THEN 'Guelmim-Oued Noun'
        
        -- Additional cities
        WHEN 'SAADINA' THEN 'Casablanca-Settat'
        
        ELSE region
    END,
    province = CASE city
        -- Casablanca-Settat Provinces
        WHEN 'CASABLANCA' THEN 'Casablanca'
        WHEN 'MOHAMMEDIA' THEN 'Mohammedia'
        WHEN 'SETTAT' THEN 'Settat'
        WHEN 'CHEMAIA' THEN 'El Jadida'
        WHEN 'ECHEMMAIA' THEN 'El Jadida'
        WHEN 'BENSLIMANE' THEN 'Benslimane'
        WHEN 'BERRECHID' THEN 'Berrechid'
        WHEN 'EL JADIDA' THEN 'El Jadida'
        WHEN 'MEDIOUNA' THEN 'Médiouna'
        WHEN 'SAADINA' THEN 'El Jadida'
        
        -- Rabat-Salé-Kénitra Provinces
        WHEN 'RABAT' THEN 'Rabat'
        WHEN 'SALE' THEN 'Salé'
        WHEN 'TEMARA' THEN 'Skhirate-Témara'
        WHEN 'KENITRA' THEN 'Kénitra'
        WHEN 'TIFLET' THEN 'Khémisset'
        WHEN 'SIDI ALI BELKACEM' THEN 'Khémisset'
        WHEN 'KHEMISSET' THEN 'Khémisset'
        WHEN 'SIDI KACEM' THEN 'Sidi Kacem'
        WHEN 'SKHIRAT' THEN 'Skhirate-Témara'
        WHEN 'RUE MOHAMED EL HANSALI FES' THEN 'Kénitra'
        
        -- Fès-Meknès Provinces
        WHEN 'FES' THEN 'Fès'
        WHEN 'MEKNES' THEN 'Meknès'
        WHEN 'TAZA' THEN 'Taza'
        WHEN 'IFRANE' THEN 'Ifrane'
        WHEN 'SEFROU' THEN 'Sefrou'
        WHEN 'EL HAJEB' THEN 'El Hajeb'
        
        -- Tanger-Tétouan-Al Hoceïma Provinces
        WHEN 'TANGER' THEN 'Tanger-Assilah'
        WHEN 'TETOUAN' THEN 'Tétouan'
        WHEN 'LARACHE' THEN 'Larache'
        WHEN 'OUAZZANE' THEN 'Ouezzane'
        WHEN 'BELYOUNECH' THEN 'Fahs-Anjra'
        WHEN 'ASSILAH' THEN 'Tanger-Assilah'
        WHEN 'CHEFCHAOUEN' THEN 'Chefchaouen'
        WHEN 'AL HOCEIMA' THEN 'Al Hoceïma'
        WHEN 'FNIDEQ' THEN 'M\'diq-Fnideq'
        
        -- Souss-Massa Provinces
        WHEN 'AGADIR' THEN 'Agadir-Ida-Ou-Tanane'
        WHEN 'TIZNIT' THEN 'Tiznit'
        WHEN 'TIMITAR' THEN 'Agadir-Ida-Ou-Tanane'
        WHEN 'DRARGA' THEN 'Agadir-Ida-Ou-Tanane'
        WHEN 'INEZGANE' THEN 'Inezgane-Aït Melloul'
        WHEN 'AIT MELLOUL' THEN 'Inezgane-Aït Melloul'
        WHEN 'TAROUDANT' THEN 'Taroudannt'
        WHEN 'TATA' THEN 'Tata'
        
        -- Marrakech-Safi Provinces
        WHEN 'MARRAKECH' THEN 'Marrakech'
        WHEN 'YOUSSOUFIA' THEN 'Youssoufia'
        WHEN 'SAFI' THEN 'Safi'
        WHEN 'ESSAOUIRA' THEN 'Essaouira'
        WHEN 'KELAA DES SRAGHNA' THEN 'Rehamna'
        
        -- Béni Mellal-Khénifra Provinces
        WHEN 'KHOURIBGA' THEN 'Khouribga'
        WHEN 'CHP KHOURIBGA' THEN 'Khouribga'
        WHEN 'BENI MELLAL' THEN 'Béni Mellal'
        WHEN 'AZILAL' THEN 'Azilal'
        WHEN 'KHENIFRA' THEN 'Khénifra'
        WHEN 'FQUIH BEN SALAH' THEN 'Fquih Ben Salah'
        
        -- Oriental Provinces
        WHEN 'OUJDA' THEN 'Oujda-Angad'
        WHEN 'NADOR' THEN 'Nador'
        WHEN 'BERKANE' THEN 'Berkane'
        WHEN 'TAOURIRT' THEN 'Taourirt'
        WHEN 'TAURIRT' THEN 'Taourirt'
        WHEN 'JERADA' THEN 'Jerada'
        WHEN 'FIGUIG' THEN 'Figuig'
        
        -- Drâa-Tafilalet Provinces
        WHEN 'ERRACHIDIA' THEN 'Errachidia'
        WHEN 'OUARZAZATE' THEN 'Ouarzazate'
        WHEN 'TINGHIR' THEN 'Tinghir'
        WHEN 'ZAGORA' THEN 'Zagora'
        
        -- Laâyoune-Sakia El Hamra Provinces
        WHEN 'LAAYOUNE' THEN 'Laâyoune'
        
        -- Dakhla-Oued Ed-Dahab Provinces
        WHEN 'DAKHLA' THEN 'Oued Ed-Dahab'
        
        -- Guelmim-Oued Noun Provinces
        WHEN 'GUELMIM' THEN 'Guelmim'
        WHEN 'TAN-TAN' THEN 'Tan-Tan'
        WHEN 'SIDI IFNI' THEN 'Sidi Ifni'
        WHEN 'ASSA-ZAG' THEN 'Assa-Zag'
        WHEN 'TOULAL' THEN 'Guelmim'
        
        ELSE province
    END
WHERE region IS NULL OR region = 'NULL' OR province IS NULL OR province = 'NULL';

-- ==========================================================
-- STEP 3: REMOVE DUPLICATE CITIES
-- ==========================================================
-- Keep only one record per city (the one with the lowest ID)

DELETE p1 FROM places p1
INNER JOIN places p2 
WHERE p1.city = p2.city 
AND p1.id > p2.id;

-- ==========================================================
-- VERIFICATION
-- ==========================================================
SELECT 
    'Total cities' as metric,
    COUNT(DISTINCT city) as value
FROM places
UNION ALL
SELECT 
    'Rows with NULL region/province',
    COUNT(*)
FROM places
WHERE region IS NULL OR region = 'NULL' OR province IS NULL OR province = 'NULL'
UNION ALL
SELECT 
    'Total rows',
    COUNT(*)
FROM places;

-- Show all unique cities with their regions
SELECT DISTINCT
    city,
    region,
    province
FROM places
ORDER BY city;
-- ==========================================================
-- DETECT AND REMOVE NON-CITY ENTRIES (STREETS, ADDRESSES)
-- ==========================================================

-- First, let's see what we're dealing with
SELECT 
    city,
    CASE 
        WHEN city LIKE '%RUE%' THEN 'Street address'
        WHEN city LIKE '%AVENUE%' OR city LIKE '%AVE%' THEN 'Street address'
        WHEN city LIKE '%BOULEVARD%' OR city LIKE '%BD%' OR city LIKE '%BLVD%' THEN 'Street address'
        WHEN city LIKE '%PLACE%' THEN 'Street address'
        WHEN city LIKE '%LOTISSEMENT%' THEN 'Development/District'
        WHEN city LIKE '%QUARTIER%' THEN 'Neighborhood'
        WHEN city LIKE '%ZONE%' THEN 'Zone/Area'
        WHEN city LIKE '%N°%' OR city LIKE '%NUM%' THEN 'Has street number'
        WHEN city LIKE '%[0-9]%' THEN 'Contains numbers'
        WHEN city LIKE 'AIN %' AND city != 'AIN KADOUS FEZ' THEN 'Might be valid'
        WHEN city LIKE 'SIDI %' AND city NOT IN ('SIDI KACEM', 'SIDI IFNI', 'SIDI SLIMANE') THEN 'Neighborhood'
        ELSE 'Valid city'
    END as category,
    COUNT(*) as count
FROM places
GROUP BY city
HAVING category != 'Valid city'
ORDER BY category, city;

-- ==========================================================
-- DELETE NON-CITY ENTRIES
-- ==========================================================

-- Delete entries that are clearly street addresses
DELETE FROM places
WHERE 
    -- Street indicators
    city LIKE '%RUE %' OR
    city LIKE '%AVENUE%' OR
    city LIKE '%AVE %' OR
    city LIKE '%BOULEVARD%' OR
    city LIKE '%BD %' OR
    city LIKE '%BLVD%' OR
    city LIKE '%PLACE %' OR
    
    -- Development/Zone indicators
    city LIKE '%LOTISSEMENT%' OR
    city LIKE '%QUARTIER%' OR
    city LIKE '%ZONE INDUSTRIELLE%' OR
    city LIKE '%ZI %' OR
    
    -- Contains street numbers (like "87 RUE", "6 RUE")
    city REGEXP '^[0-9]+ ' OR
    city LIKE '%N°%' OR
    city LIKE '%NUM%' OR
    
    -- Specific non-city patterns
    city LIKE 'RUE %' OR
    city LIKE '% RUE %' OR
    
    -- Empty or null cities
    city IS NULL OR
    city = '' OR
    city = 'NULL';

-- ==========================================================
-- EXTRACT CITY FROM ADDRESS-LIKE ENTRIES
-- ==========================================================

-- For entries like "RUE IMAM ALI FES NOUVELLE" or "AIN KADOUS FEZ"
-- Extract the actual city name at the end

-- Strategy: If the city field contains a known city name, extract it

UPDATE places
SET city = CASE
    -- Extract FES/FEZ
    WHEN city LIKE '%FES%' OR city LIKE '%FEZ%' THEN 'FES'
    
    -- Extract CASABLANCA
    WHEN city LIKE '%CASABLANCA%' THEN 'CASABLANCA'
    
    -- Extract RABAT
    WHEN city LIKE '%RABAT%' THEN 'RABAT'
    
    -- Extract TANGER
    WHEN city LIKE '%TANGER%' THEN 'TANGER'
    
    -- Extract MARRAKECH
    WHEN city LIKE '%MARRAKECH%' THEN 'MARRAKECH'
    
    -- Extract AGADIR
    WHEN city LIKE '%AGADIR%' THEN 'AGADIR'
    
    -- Extract OUJDA
    WHEN city LIKE '%OUJDA%' THEN 'OUJDA'
    
    -- Extract KENITRA
    WHEN city LIKE '%KENITRA%' OR city LIKE '%KÉNITRA%' THEN 'KENITRA'
    
    -- Extract SALE
    WHEN city LIKE '%SALE%' OR city LIKE '%SALÉ%' THEN 'SALE'
    
    -- Extract MEKNES
    WHEN city LIKE '%MEKNES%' OR city LIKE '%MEKNÈS%' THEN 'MEKNES'
    
    -- Extract TETOUAN
    WHEN city LIKE '%TETOUAN%' OR city LIKE '%TÉTOUAN%' THEN 'TETOUAN'
    
    ELSE city
END
WHERE 
    (city LIKE '%RUE%' OR city LIKE '%AVENUE%' OR city LIKE '%AIN%' OR city LIKE '%SIDI%')
    AND (
        city LIKE '%FES%' OR city LIKE '%FEZ%' OR
        city LIKE '%CASABLANCA%' OR
        city LIKE '%RABAT%' OR
        city LIKE '%TANGER%' OR
        city LIKE '%MARRAKECH%' OR
        city LIKE '%AGADIR%' OR
        city LIKE '%OUJDA%' OR
        city LIKE '%KENITRA%' OR city LIKE '%KÉNITRA%' OR
        city LIKE '%SALE%' OR city LIKE '%SALÉ%' OR
        city LIKE '%MEKNES%' OR city LIKE '%MEKNÈS%' OR
        city LIKE '%TETOUAN%' OR city LIKE '%TÉTOUAN%'
    );

-- ==========================================================
-- HANDLE SPECIFIC PROBLEMATIC ENTRIES
-- ==========================================================

-- Delete or fix specific entries that don't fit patterns
DELETE FROM places
WHERE city IN (
    '87 RUE OMAR EL DRISSI',
    '6 RUE KASEM AMINE',
    'RUE ABDESSALAM SERGHINI',
    'RUE MOHAMED ZARKTOUNI FEZ',
    'RUE IMAM ALI FES NOUVELLE'
);

-- Handle neighborhoods that should be removed
DELETE FROM places
WHERE 
    city LIKE 'SIDI ALLAL%' OR
    city LIKE 'AIT SKATOU%' OR
    (city LIKE 'AIN %' AND city NOT IN ('AIN CHOCK', 'AIN SEBAA', 'AIN DIAB')) OR
    city LIKE 'BENI ENSAR%' OR  -- This is a small town, but if you want to keep it, remove this line
    city LIKE 'MIDAR%';  -- Small town in Oriental

-- ==========================================================
-- CLEAN UP: Remove duplicates after extraction
-- ==========================================================

DELETE p1 FROM places p1
INNER JOIN places p2 
WHERE p1.city = p2.city 
AND p1.id > p2.id;

-- ==========================================================
-- VERIFICATION
-- ==========================================================

-- Count what's left
SELECT 
    'Total unique cities remaining' as metric,
    COUNT(DISTINCT city) as value
FROM places
UNION ALL
SELECT 
    'Total rows',
    COUNT(*)
FROM places;

-- Show cities that might still be problematic
SELECT DISTINCT city
FROM places
WHERE 
    city LIKE '% RUE %' OR
    city LIKE '%AVENUE%' OR
    city LIKE '%[0-9]%' OR
    city LIKE 'RUE %' OR
    city LIKE '%QUARTIER%' OR
    LENGTH(city) > 30  -- Very long names might be addresses
ORDER BY city;

-- Show final clean list
SELECT DISTINCT 
    city,
    region,
    province,
    COUNT(*) as occurrence_count
FROM places
GROUP BY city, region, province
ORDER BY city;
-- ============================================================================
-- HOSPITAL DATA CLEANING SQL
-- ============================================================================

-- 1. DROP UNUSED COLUMNS (latitude, longitude, source)
-- ============================================================================
ALTER TABLE hospitals 
DROP COLUMN latitude,
DROP COLUMN longitude,
DROP COLUMN source;

-- 2. CLEAN PHONE NUMBERS
-- ============================================================================

-- Remove 'NULL' text values
UPDATE hospitals 
SET phone = NULL 
WHERE phone = 'NULL' OR phone = '' OR TRIM(phone) = '';

-- Standardize phone format: remove spaces, dots, dashes
UPDATE hospitals 
SET phone = REPLACE(REPLACE(REPLACE(phone, ' ', ''), '.', ''), '-', '')
WHERE phone IS NOT NULL;

-- Remove country code prefix if present (Morocco +212 or 00212 or 0212)
UPDATE hospitals 
SET phone = REGEXP_REPLACE(phone, '^(\\+212|00212|0212)', '0')
WHERE phone IS NOT NULL;

-- Ensure phone starts with 0 if it's a valid Moroccan number
UPDATE hospitals 
SET phone = CONCAT('0', phone)
WHERE phone IS NOT NULL 
  AND phone NOT LIKE '0%' 
  AND LENGTH(phone) = 9;

-- Mark invalid phones as NULL (valid Moroccan phones are 10 digits starting with 0)
UPDATE hospitals 
SET phone = NULL
WHERE phone IS NOT NULL 
  AND (LENGTH(phone) != 10 OR phone NOT LIKE '0%');

-- 3. CLEAN EMAIL ADDRESSES
-- ============================================================================

-- Remove 'NULL' text values
UPDATE hospitals 
SET email = NULL 
WHERE email = 'NULL' OR email = '' OR TRIM(email) = '';

-- Convert to lowercase
UPDATE hospitals 
SET email = LOWER(TRIM(email))
WHERE email IS NOT NULL;

-- Mark invalid emails as NULL (must contain @ and .)
UPDATE hospitals 
SET email = NULL
WHERE email IS NOT NULL 
  AND (email NOT LIKE '%@%.%' 
       OR email LIKE '%..%' 
       OR email LIKE '@%'
       OR email LIKE '%@');

-- 4. CLEAN WEBSITE URLS
-- ============================================================================

-- Remove 'NULL' text values
UPDATE hospitals 
SET website = NULL 
WHERE website = 'NULL' OR website = '' OR TRIM(website) = '';

-- Convert to lowercase
UPDATE hospitals 
SET website = LOWER(TRIM(website))
WHERE website IS NOT NULL;

-- Add https:// if missing
UPDATE hospitals 
SET website = CONCAT('https://', website)
WHERE website IS NOT NULL 
  AND website NOT LIKE 'http%';

-- 5. CLEAN NAME
-- ============================================================================

-- Trim and standardize spacing
UPDATE hospitals 
SET name = TRIM(REGEXP_REPLACE(name, '\\s+', ' '))
WHERE name IS NOT NULL;

-- 6. CLEAN ADDRESS
-- ============================================================================

-- Trim and standardize spacing
UPDATE hospitals 
SET address = TRIM(REGEXP_REPLACE(address, '\\s+', ' '))
WHERE address IS NOT NULL;

-- Remove trailing commas
UPDATE hospitals 
SET address = TRIM(TRAILING ',' FROM address)
WHERE address LIKE '%,';

-- Remove 'Morocco' and 'Maroc' from end of address (it's redundant)
UPDATE hospitals 
SET address = TRIM(REGEXP_REPLACE(address, ',?\\s*(Morocco|Maroc)\\s*$', ''))
WHERE address IS NOT NULL;

-- 7. CLEAN TYPE
-- ============================================================================

-- Standardize hospital types
UPDATE hospitals 
SET type = UPPER(TRIM(type))
WHERE type IS NOT NULL;

-- 8. CLEAN BEDS (capacity)
-- ============================================================================

-- Set invalid bed counts to NULL
UPDATE hospitals 
SET beds = NULL
WHERE beds IS NOT NULL 
  AND (beds < 0 OR beds > 10000);

-- 9. STANDARDIZE place_id
-- ============================================================================

-- Ensure place_id is valid (exists in places table)
UPDATE hospitals h
LEFT JOIN places p ON h.place_id = p.id
SET h.place_id = NULL
WHERE h.place_id IS NOT NULL AND p.id IS NULL;

-- 10. REMOVE DUPLICATE HOSPITALS
-- ============================================================================

-- Keep only the most complete record for duplicates (based on name + address)
DELETE h1 FROM hospitals h1
INNER JOIN hospitals h2 
WHERE h1.name = h2.name 
  AND h1.address = h2.address
  AND h1.id > h2.id;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check phone cleaning results
SELECT 
    'Valid phones' as metric,
    COUNT(*) as count
FROM hospitals 
WHERE phone IS NOT NULL AND LENGTH(phone) = 10

UNION ALL

SELECT 
    'NULL phones' as metric,
    COUNT(*) as count
FROM hospitals 
WHERE phone IS NULL

UNION ALL

-- Check email cleaning results
SELECT 
    'Valid emails' as metric,
    COUNT(*) as count
FROM hospitals 
WHERE email IS NOT NULL AND email LIKE '%@%.%'

UNION ALL

SELECT 
    'NULL emails' as metric,
    COUNT(*) as count
FROM hospitals 
WHERE email IS NULL

UNION ALL

-- Check website cleaning results
SELECT 
    'Valid websites' as metric,
    COUNT(*) as count
FROM hospitals 
WHERE website IS NOT NULL

UNION ALL

SELECT 
    'NULL websites' as metric,
    COUNT(*) as count
FROM hospitals 
WHERE website IS NULL;

-- Show sample of cleaned data
SELECT 
    id,
    name,
    phone,
    email,
    website,
    type,
    beds
FROM hospitals 
LIMIT 20;

-- Show hospitals with issues
SELECT 
    id,
    name,
    phone,
    email,
    address
FROM hospitals
WHERE (phone IS NULL AND email IS NULL)
   OR beds IS NULL
   OR place_id IS NULL
ORDER BY id
LIMIT 50;