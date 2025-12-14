import mysql.connector
from mysql.connector import Error
import re

def execute_query(cursor, connection, query, description):
    """Execute a single query with error handling"""
    try:
        cursor.execute(query)
        connection.commit()
        rows = cursor.rowcount
        print(f"  ✓ {description}: {rows} rows affected")
        return rows
    except Error as e:
        print(f"  ✗ ERROR in {description}: {e}")
        connection.rollback()
        return 0

def clean_database(connection):
    """Complete cleaning process"""
    cursor = connection.cursor()
    
    print("\n" + "="*70)
    print("STEP 1: ANALYZING NON-CITY ENTRIES")
    print("="*70)
    
    # Show what will be removed
    cursor.execute("""
        SELECT city, COUNT(*) as count
        FROM places
        WHERE 
            city LIKE '%RUE%' OR
            city LIKE '%AVENUE%' OR
            city LIKE '%BOULEVARD%' OR
            city REGEXP '^[0-9]+ ' OR
            city LIKE '%LOTISSEMENT%' OR
            city LIKE '%QUARTIER%'
        GROUP BY city
        ORDER BY city
    """)
    
    problematic = cursor.fetchall()
    if problematic:
        print(f"\nFound {len(problematic)} problematic entries:")
        for city, count in problematic[:10]:  # Show first 10
            print(f"  - {city} ({count} rows)")
        if len(problematic) > 10:
            print(f"  ... and {len(problematic) - 10} more")
    else:
        print("No problematic entries found!")
    
    # STEP 2: Extract city names from addresses
    print("\n" + "="*70)
    print("STEP 2: EXTRACTING CITY NAMES FROM ADDRESS-LIKE ENTRIES")
    print("="*70)
    
    city_extraction_query = """
        UPDATE places
        SET city = CASE
            WHEN city LIKE '%FES%' OR city LIKE '%FEZ%' THEN 'FES'
            WHEN city LIKE '%CASABLANCA%' THEN 'CASABLANCA'
            WHEN city LIKE '%RABAT%' THEN 'RABAT'
            WHEN city LIKE '%TANGER%' THEN 'TANGER'
            WHEN city LIKE '%MARRAKECH%' THEN 'MARRAKECH'
            WHEN city LIKE '%AGADIR%' THEN 'AGADIR'
            WHEN city LIKE '%OUJDA%' THEN 'OUJDA'
            WHEN city LIKE '%KENITRA%' OR city LIKE '%KÉNITRA%' THEN 'KENITRA'
            WHEN city LIKE '%SALE%' OR city LIKE '%SALÉ%' THEN 'SALE'
            WHEN city LIKE '%MEKNES%' OR city LIKE '%MEKNÈS%' THEN 'MEKNES'
            ELSE city
        END
        WHERE 
            (city LIKE '%RUE%' OR city LIKE '%AVENUE%' OR city LIKE '%AIN%')
            AND (
                city LIKE '%FES%' OR city LIKE '%FEZ%' OR
                city LIKE '%CASABLANCA%' OR city LIKE '%RABAT%' OR
                city LIKE '%TANGER%' OR city LIKE '%MARRAKECH%' OR
                city LIKE '%AGADIR%' OR city LIKE '%OUJDA%' OR
                city LIKE '%KENITRA%' OR city LIKE '%KÉNITRA%' OR
                city LIKE '%SALE%' OR city LIKE '%SALÉ%' OR
                city LIKE '%MEKNES%' OR city LIKE '%MEKNÈS%'
            )
    """
    execute_query(cursor, connection, city_extraction_query, "Extracting city names")
    
    # STEP 3: Delete non-city entries
    print("\n" + "="*70)
    print("STEP 3: REMOVING STREET ADDRESSES AND NON-CITY ENTRIES")
    print("="*70)
    
    delete_queries = [
        ("Street addresses (RUE, AVENUE, etc.)", """
            DELETE FROM places
            WHERE 
                city LIKE '%RUE %' OR
                city LIKE '%AVENUE%' OR
                city LIKE '%BOULEVARD%' OR
                city LIKE 'RUE %' OR
                city LIKE '% RUE %'
        """),
        
        ("Entries with street numbers", """
            DELETE FROM places
            WHERE 
                city REGEXP '^[0-9]+ ' OR
                city LIKE '%N°%' OR
                city LIKE '%NUM%'
        """),
        
        ("Neighborhoods and zones", """
            DELETE FROM places
            WHERE 
                city LIKE '%LOTISSEMENT%' OR
                city LIKE '%QUARTIER%' OR
                city LIKE '%ZONE INDUSTRIELLE%' OR
                city LIKE 'SIDI ALLAL%' OR
                city LIKE 'AIT SKATOU%'
        """),
        
        ("Empty or NULL cities", """
            DELETE FROM places
            WHERE city IS NULL OR city = '' OR city = 'NULL'
        """),
        
        ("Small towns/neighborhoods (optional)", """
            DELETE FROM places
            WHERE city IN ('MIDAR', 'BENI ENSAR')
        """)
    ]
    
    for desc, query in delete_queries:
        execute_query(cursor, connection, query, desc)
    
    # STEP 4: Standardize city names
    print("\n" + "="*70)
    print("STEP 4: STANDARDIZING CITY NAME VARIATIONS")
    print("="*70)
    
    standardize_queries = [
        ("FEZ variations", "UPDATE places SET city = 'FES' WHERE city IN ('FEZ', 'FÈS', 'FEŞ')"),
        ("SALE variations", "UPDATE places SET city = 'SALE' WHERE city = 'SALÉ'"),
        ("TEMARA variations", "UPDATE places SET city = 'TEMARA' WHERE city = 'TÉMARA'"),
        ("KENITRA variations", "UPDATE places SET city = 'KENITRA' WHERE city = 'KÉNITRA'"),
        ("MEKNES variations", "UPDATE places SET city = 'MEKNES' WHERE city = 'MEKNÈS'"),
        ("TETOUAN variations", "UPDATE places SET city = 'TETOUAN' WHERE city = 'TÉTOUAN'"),
    ]
    
    for desc, query in standardize_queries:
        execute_query(cursor, connection, query, desc)
    
    # STEP 5: Fill regions and provinces
    print("\n" + "="*70)
    print("STEP 5: FILLING REGIONS AND PROVINCES")
    print("="*70)
    
    fill_region_query = """
        UPDATE places
        SET 
            region = CASE city
                WHEN 'CASABLANCA' THEN 'Casablanca-Settat'
                WHEN 'MOHAMMEDIA' THEN 'Casablanca-Settat'
                WHEN 'RABAT' THEN 'Rabat-Salé-Kénitra'
                WHEN 'SALE' THEN 'Rabat-Salé-Kénitra'
                WHEN 'TEMARA' THEN 'Rabat-Salé-Kénitra'
                WHEN 'KENITRA' THEN 'Rabat-Salé-Kénitra'
                WHEN 'FES' THEN 'Fès-Meknès'
                WHEN 'MEKNES' THEN 'Fès-Meknès'
                WHEN 'TANGER' THEN 'Tanger-Tétouan-Al Hoceïma'
                WHEN 'TETOUAN' THEN 'Tanger-Tétouan-Al Hoceïma'
                WHEN 'LARACHE' THEN 'Tanger-Tétouan-Al Hoceïma'
                WHEN 'OUAZZANE' THEN 'Tanger-Tétouan-Al Hoceïma'
                WHEN 'CHEFCHAOUEN' THEN 'Tanger-Tétouan-Al Hoceïma'
                WHEN 'AGADIR' THEN 'Souss-Massa'
                WHEN 'TIZNIT' THEN 'Souss-Massa'
                WHEN 'AIT MELLOUL' THEN 'Souss-Massa'
                WHEN 'MARRAKECH' THEN 'Marrakech-Safi'
                WHEN 'YOUSSOUFIA' THEN 'Marrakech-Safi'
                WHEN 'KHOURIBGA' THEN 'Béni Mellal-Khénifra'
                WHEN 'CHP KHOURIBGA' THEN 'Béni Mellal-Khénifra'
                WHEN 'BENI MELLAL' THEN 'Béni Mellal-Khénifra'
                WHEN 'OUJDA' THEN 'Oriental'
                WHEN 'TAOURIRT' THEN 'Oriental'
                WHEN 'FIGUIG' THEN 'Oriental'
                ELSE region
            END,
            province = CASE city
                WHEN 'CASABLANCA' THEN 'Casablanca'
                WHEN 'MOHAMMEDIA' THEN 'Mohammedia'
                WHEN 'RABAT' THEN 'Rabat'
                WHEN 'SALE' THEN 'Salé'
                WHEN 'TEMARA' THEN 'Skhirate-Témara'
                WHEN 'KENITRA' THEN 'Kénitra'
                WHEN 'FES' THEN 'Fès'
                WHEN 'MEKNES' THEN 'Meknès'
                WHEN 'TANGER' THEN 'Tanger-Assilah'
                WHEN 'TETOUAN' THEN 'Tétouan'
                WHEN 'LARACHE' THEN 'Larache'
                WHEN 'OUAZZANE' THEN 'Ouezzane'
                WHEN 'CHEFCHAOUEN' THEN 'Chefchaouen'
                WHEN 'AGADIR' THEN 'Agadir-Ida-Ou-Tanane'
                WHEN 'TIZNIT' THEN 'Tiznit'
                WHEN 'AIT MELLOUL' THEN 'Inezgane-Aït Melloul'
                WHEN 'MARRAKECH' THEN 'Marrakech'
                WHEN 'YOUSSOUFIA' THEN 'Youssoufia'
                WHEN 'KHOURIBGA' THEN 'Khouribga'
                WHEN 'CHP KHOURIBGA' THEN 'Khouribga'
                WHEN 'BENI MELLAL' THEN 'Béni Mellal'
                WHEN 'OUJDA' THEN 'Oujda-Angad'
                WHEN 'TAOURIRT' THEN 'Taourirt'
                WHEN 'FIGUIG' THEN 'Figuig'
                ELSE province
            END
        WHERE region IS NULL OR region = 'NULL' OR province IS NULL OR province = 'NULL'
    """
    execute_query(cursor, connection, fill_region_query, "Filling regions and provinces")
    
    # STEP 6: Remove duplicates
    print("\n" + "="*70)
    print("STEP 6: REMOVING DUPLICATE CITIES")
    print("="*70)
    
    duplicate_query = """
        DELETE p1 FROM places p1
        INNER JOIN places p2 
        WHERE p1.city = p2.city 
        AND p1.id > p2.id
    """
    execute_query(cursor, connection, duplicate_query, "Removing duplicates")
    
    # VERIFICATION
    print("\n" + "="*70)
    print("FINAL VERIFICATION")
    print("="*70)
    
    # Count totals
    cursor.execute("SELECT COUNT(DISTINCT city) FROM places")
    unique_cities = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM places")
    total_rows = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT COUNT(*) FROM places 
        WHERE region IS NULL OR region = 'NULL' OR province IS NULL OR province = 'NULL'
    """)
    null_count = cursor.fetchone()[0]
    
    print(f"\n✓ Unique cities: {unique_cities}")
    print(f"✓ Total rows: {total_rows}")
    print(f"✓ Rows with NULL region/province: {null_count}")
    
    # Show sample
    print(f"\n{'='*70}")
    print("SAMPLE OF CLEANED DATA (first 15 cities)")
    print('='*70)
    
    cursor.execute("""
        SELECT DISTINCT city, region, province 
        FROM places 
        ORDER BY city 
        LIMIT 15
    """)
    
    results = cursor.fetchall()
    print(f"\n{'City':<25} {'Region':<30} {'Province':<20}")
    print("-" * 75)
    for row in results:
        city = row[0] or 'NULL'
        region = row[1] or 'NULL'
        province = row[2] or 'NULL'
        print(f"{city:<25} {region:<30} {province:<20}")
    
    cursor.close()

def main():
    # Database configuration
    config = {
        'host': 'localhost',
        'database': 'morocco_health_db',  # CHANGE THIS
        'user': 'root',            # CHANGE THIS
        'password': '',        # CHANGE THIS
    }
    
    connection = None
    
    try:
        print("="*70)
        print("MOROCCAN PLACES DATABASE - COMPLETE CLEANING")
        print("="*70)
        print("\nConnecting to database...")
        
        connection = mysql.connector.connect(**config)
        
        if connection.is_connected():
            print("✓ Connected successfully")
            clean_database(connection)
            print("\n" + "="*70)
            print("✓ CLEANING COMPLETED SUCCESSFULLY!")
            print("="*70)
            
    except Error as e:
        print(f"\n✗ ERROR: {e}")
    finally:
        if connection and connection.is_connected():
            connection.close()
            print("\n✓ Database connection closed")

if __name__ == "__main__":
    main()