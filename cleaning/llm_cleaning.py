import os
import json
import time
import mysql.connector
import requests
from dotenv import load_dotenv

# Setup
load_dotenv()
GROQ_API_KEY = os.getenv("GROQ_API_KEY")

# Database Configuration
db_config = {
    'user': 'root',
    'password': '',
    'host': 'localhost',
    'database': 'morocco_health_db'
}

# ============================================================================
# MODEL CONFIGURATION - GROQ
# ============================================================================

AVAILABLE_MODELS = {
    "1": {
        "name": "Llama 3.3 70B (Versatile)",
        "id": "llama-3.3-70b-versatile",
        "description": "Best overall model, great for complex tasks"
    },
    "2": {
        "name": "Llama 3.1 8B (Instant)",
        "id": "llama-3.1-8b-instant",
        "description": "Fastest model, good for simple tasks"
    },
    "3": {
        "name": "Mixtral 8x7B",
        "id": "mixtral-8x7b-32768",
        "description": "Great balance of speed and quality"
    },
    "4": {
        "name": "Gemma 2 9B",
        "id": "gemma2-9b-it",
        "description": "Google's efficient model"
    }
}

# Default model
SELECTED_MODEL = "llama-3.3-70b-versatile"

# ============================================================================
# LOCAL MAPPING DATA (Primary method - no API needed)
# ============================================================================

MOROCCO_REGIONS_MAP = {
    # Casablanca-Settat
    'CASABLANCA': ('Casablanca-Settat', 'Casablanca'),
    'MOHAMMEDIA': ('Casablanca-Settat', 'Mohammedia'),
    'SETTAT': ('Casablanca-Settat', 'Settat'),
    'EL JADIDA': ('Casablanca-Settat', 'El Jadida'),
    'BERRECHID': ('Casablanca-Settat', 'Berrechid'),
    'BENSLIMANE': ('Casablanca-Settat', 'Benslimane'),
    'MEDIOUNA': ('Casablanca-Settat', 'Médiouna'),
    'CHEMAIA': ('Casablanca-Settat', 'El Jadida'),
    'ECHEMMAIA': ('Casablanca-Settat', 'El Jadida'),
    'SAADINA': ('Casablanca-Settat', 'El Jadida'),
    
    # Rabat-Salé-Kénitra
    'RABAT': ('Rabat-Salé-Kénitra', 'Rabat'),
    'SALE': ('Rabat-Salé-Kénitra', 'Salé'),
    'KENITRA': ('Rabat-Salé-Kénitra', 'Kénitra'),
    'TEMARA': ('Rabat-Salé-Kénitra', 'Skhirate-Témara'),
    'SKHIRAT': ('Rabat-Salé-Kénitra', 'Skhirate-Témara'),
    'KHEMISSET': ('Rabat-Salé-Kénitra', 'Khémisset'),
    'TIFLET': ('Rabat-Salé-Kénitra', 'Khémisset'),
    'SIDI KACEM': ('Rabat-Salé-Kénitra', 'Sidi Kacem'),
    'SIDI SLIMANE': ('Rabat-Salé-Kénitra', 'Sidi Slimane'),
    'SIDI ALI BELKACEM': ('Rabat-Salé-Kénitra', 'Khémisset'),
    
    # Fès-Meknès
    'FES': ('Fès-Meknès', 'Fès'),
    'MEKNES': ('Fès-Meknès', 'Meknès'),
    'TAZA': ('Fès-Meknès', 'Taza'),
    'IFRANE': ('Fès-Meknès', 'Ifrane'),
    'SEFROU': ('Fès-Meknès', 'Sefrou'),
    'EL HAJEB': ('Fès-Meknès', 'El Hajeb'),
    'BOULEMANE': ('Fès-Meknès', 'Boulemane'),
    
    # Tanger-Tétouan-Al Hoceïma
    'TANGER': ('Tanger-Tétouan-Al Hoceïma', 'Tanger-Assilah'),
    'TETOUAN': ('Tanger-Tétouan-Al Hoceïma', 'Tétouan'),
    'AL HOCEIMA': ('Tanger-Tétouan-Al Hoceïma', 'Al Hoceïma'),
    'LARACHE': ('Tanger-Tétouan-Al Hoceïma', 'Larache'),
    'CHEFCHAOUEN': ('Tanger-Tétouan-Al Hoceïma', 'Chefchaouen'),
    'OUAZZANE': ('Tanger-Tétouan-Al Hoceïma', 'Ouezzane'),
    'ASSILAH': ('Tanger-Tétouan-Al Hoceïma', 'Tanger-Assilah'),
    'FNIDEQ': ('Tanger-Tétouan-Al Hoceïma', 'M\'diq-Fnideq'),
    'BELYOUNECH': ('Tanger-Tétouan-Al Hoceïma', 'Fahs-Anjra'),
    
    # Souss-Massa
    'AGADIR': ('Souss-Massa', 'Agadir-Ida-Ou-Tanane'),
    'TIZNIT': ('Souss-Massa', 'Tiznit'),
    'TAROUDANT': ('Souss-Massa', 'Taroudannt'),
    'INEZGANE': ('Souss-Massa', 'Inezgane-Aït Melloul'),
    'AIT MELLOUL': ('Souss-Massa', 'Inezgane-Aït Melloul'),
    'TATA': ('Souss-Massa', 'Tata'),
    'TIMITAR': ('Souss-Massa', 'Agadir-Ida-Ou-Tanane'),
    'DRARGA': ('Souss-Massa', 'Agadir-Ida-Ou-Tanane'),
    
    # Marrakech-Safi
    'MARRAKECH': ('Marrakech-Safi', 'Marrakech'),
    'SAFI': ('Marrakech-Safi', 'Safi'),
    'ESSAOUIRA': ('Marrakech-Safi', 'Essaouira'),
    'YOUSSOUFIA': ('Marrakech-Safi', 'Youssoufia'),
    'KELAA DES SRAGHNA': ('Marrakech-Safi', 'Rehamna'),
    'CHICHAOUA': ('Marrakech-Safi', 'Chichaoua'),
    
    # Béni Mellal-Khénifra
    'BENI MELLAL': ('Béni Mellal-Khénifra', 'Béni Mellal'),
    'KHOURIBGA': ('Béni Mellal-Khénifra', 'Khouribga'),
    'CHP KHOURIBGA': ('Béni Mellal-Khénifra', 'Khouribga'),
    'AZILAL': ('Béni Mellal-Khénifra', 'Azilal'),
    'KHENIFRA': ('Béni Mellal-Khénifra', 'Khénifra'),
    'FQUIH BEN SALAH': ('Béni Mellal-Khénifra', 'Fquih Ben Salah'),
    
    # Oriental
    'OUJDA': ('Oriental', 'Oujda-Angad'),
    'NADOR': ('Oriental', 'Nador'),
    'BERKANE': ('Oriental', 'Berkane'),
    'TAOURIRT': ('Oriental', 'Taourirt'),
    'TAURIRT': ('Oriental', 'Taourirt'),
    'JERADA': ('Oriental', 'Jerada'),
    'FIGUIG': ('Oriental', 'Figuig'),
    'DRIOUCH': ('Oriental', 'Driouch'),
    'GUERCIF': ('Oriental', 'Guercif'),
    
    # Drâa-Tafilalet
    'ERRACHIDIA': ('Drâa-Tafilalet', 'Errachidia'),
    'OUARZAZATE': ('Drâa-Tafilalet', 'Ouarzazate'),
    'TINGHIR': ('Drâa-Tafilalet', 'Tinghir'),
    'ZAGORA': ('Drâa-Tafilalet', 'Zagora'),
    'MIDELT': ('Drâa-Tafilalet', 'Midelt'),
    
    # Guelmim-Oued Noun
    'GUELMIM': ('Guelmim-Oued Noun', 'Guelmim'),
    'TAN-TAN': ('Guelmim-Oued Noun', 'Tan-Tan'),
    'SIDI IFNI': ('Guelmim-Oued Noun', 'Sidi Ifni'),
    'ASSA-ZAG': ('Guelmim-Oued Noun', 'Assa-Zag'),
    'TOULAL': ('Guelmim-Oued Noun', 'Guelmim'),
    
    # Laâyoune-Sakia El Hamra
    'LAAYOUNE': ('Laâyoune-Sakia El Hamra', 'Laâyoune'),
    'BOUJDOUR': ('Laâyoune-Sakia El Hamra', 'Boujdour'),
    'ES-SEMARA': ('Laâyoune-Sakia El Hamra', 'Es-Semara'),
    'TARFAYA': ('Laâyoune-Sakia El Hamra', 'Tarfaya'),
    
    # Dakhla-Oued Ed-Dahab
    'DAKHLA': ('Dakhla-Oued Ed-Dahab', 'Oued Ed-Dahab'),
    'AOUSSERD': ('Dakhla-Oued Ed-Dahab', 'Aousserd'),
}

SERVICE_DESCRIPTIONS = {
    'RADIOLOGIE': 'Service d\'imagerie médicale offrant des examens radiologiques diagnostiques.',
    'CARDIOLOGIE': 'Consultation et traitement des maladies cardiovasculaires.',
    'PEDIATRIE': 'Soins médicaux spécialisés pour nourrissons, enfants et adolescents.',
    'GYNECOLOGIE': 'Consultation gynécologique, santé reproductive et obstétrique.',
    'DERMATOLOGIE': 'Diagnostic et traitement des maladies de la peau.',
    'ANALYSE': 'Laboratoire d\'analyses biologiques et tests diagnostiques.',
    'ANALYSE MEDICALE': 'Laboratoire d\'analyses biologiques et tests diagnostiques.',
    'CHIRURGIE': 'Service de chirurgie générale et interventions chirurgicales.',
    'OPHTALMOLOGIE': 'Consultation et traitement des maladies des yeux.',
    'ORL': 'Traitement des pathologies de l\'oreille, du nez et de la gorge.',
    'DENTAIRE': 'Soins dentaires et traitement des pathologies bucco-dentaires.',
    'ORTHODONTIE': 'Correction de la position des dents et des mâchoires.',
    'NEUROLOGIE': 'Diagnostic et traitement des maladies du système nerveux.',
    'PSYCHIATRIE': 'Prise en charge des troubles mentaux et psychologiques.',
    'URGENCE': 'Service d\'urgences médicales disponible 24h/24.',
    'PHARMACIE': 'Dispensation de médicaments et conseil pharmaceutique.',
    'KINESITHERAPIE': 'Rééducation fonctionnelle et thérapie par le mouvement.',
    'MATERNITE': 'Suivi de grossesse, accouchement et soins postnatals.',
    'MEDECINE GENERALE': 'Consultation médicale générale et suivi de santé.',
    'IMAGERIE': 'Service d\'imagerie médicale et radiologie diagnostique.',
    'UROLOGIE': 'Diagnostic et traitement des pathologies urinaires et génitales.',
    'TRAUMATOLOGIE': 'Prise en charge des traumatismes et urgences orthopédiques.',
    'ONCOLOGIE': 'Diagnostic et traitement des cancers et tumeurs.',
    'ENDOCRINOLOGIE': 'Traitement des troubles hormonaux et métaboliques.',
    'RHUMATOLOGIE': 'Diagnostic et traitement des maladies articulaires.',
    'GASTRO': 'Spécialité des maladies digestives et hépatiques.',
    'NEPHROLOGIE': 'Traitement des maladies rénales.',
    'PNEUMOLOGIE': 'Diagnostic et traitement des maladies respiratoires.',
    'ALLERGOLOGIE': 'Diagnostic et traitement des allergies.',
    'HEMATO': 'Spécialité des maladies du sang.',
}

# ============================================================================
# GROQ API FUNCTIONS
# ============================================================================

def call_groq(prompt, retry_count=3, model=None):
    """Call Groq API with selected model"""
    
    if model is None:
        model = SELECTED_MODEL
    
    url = "https://api.groq.com/openai/v1/chat/completions"
    
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json"
    }
    
    # Add JSON instruction to prompt
    json_prompt = f"{prompt}\n\nIMPORTANT: Respond ONLY with valid JSON. No markdown, no explanation."
    
    data = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": json_prompt
            }
        ],
        "temperature": 0.1,
        "max_tokens": 2000
    }
    
    for attempt in range(retry_count):
        try:
            response = requests.post(url, headers=headers, json=data, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            content = result['choices'][0]['message']['content']
            
            # Clean up response - remove markdown code blocks if present
            content = content.strip()
            if content.startswith('```json'):
                content = content[7:]
            if content.startswith('```'):
                content = content[3:]
            if content.endswith('```'):
                content = content[:-3]
            content = content.strip()
            
            # Parse JSON from response
            return json.loads(content)
            
        except requests.exceptions.HTTPError as e:
            if response.status_code == 429:
                wait_time = 5 * (attempt + 1)
                print(f"⏳ Rate limit. Waiting {wait_time}s...")
                time.sleep(wait_time)
            else:
                print(f"❌ HTTP Error {response.status_code}: {e}")
                if attempt < retry_count - 1:
                    time.sleep(2)
                else:
                    return None
        except json.JSONDecodeError as e:
            print(f"⚠️ JSON Parse Error: {e}")
            print(f"Response content: {content[:200]}...")
            if attempt < retry_count - 1:
                time.sleep(2)
            else:
                return None
        except Exception as e:
            print(f"❌ API Error: {e}")
            if attempt < retry_count - 1:
                time.sleep(2)
            else:
                return None
    
    return None

# ============================================================================
# PLACES CLEANING
# ============================================================================

def get_places_missing_region(batch_size=50):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)
        query = f"SELECT id, city FROM places WHERE region IS NULL OR province IS NULL LIMIT {batch_size}"
        cursor.execute(query)
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        return rows
    except mysql.connector.Error as err:
        print(f"❌ Database Error: {err}")
        return []

def fill_places_locally(rows):
    """Try local mapping first"""
    results = []
    unknown_cities = []
    
    for row in rows:
        city = row['city'].upper().strip()
        
        if city in MOROCCO_REGIONS_MAP:
            region, province = MOROCCO_REGIONS_MAP[city]
            results.append({
                'id': row['id'],
                'city': row['city'],
                'region': region,
                'province': province,
                'action': 'UPDATE'
            })
            print(f"  ✓ [LOCAL] ID {row['id']}: {row['city']} → {region}")
        else:
            unknown_cities.append(row)
    
    return results, unknown_cities

def fill_places_with_ai(rows):
    """Use Groq AI for unknown cities"""
    if not rows:
        return []
    
    cities_list = [f"ID {row['id']}: {row['city']}" for row in rows]
    
    prompt = f"""You are a Moroccan geography expert. Map these cities to their region and province.

Cities to map:
{chr(10).join(cities_list)}

Moroccan Regions:
- Casablanca-Settat, Rabat-Salé-Kénitra, Fès-Meknès, Tanger-Tétouan-Al Hoceïma
- Souss-Massa, Marrakech-Safi, Béni Mellal-Khénifra, Oriental
- Drâa-Tafilalet, Guelmim-Oued Noun, Laâyoune-Sakia El Hamra, Dakhla-Oued Ed-Dahab

Return JSON with this structure:
{{
  "results": [
    {{"id": 1, "region": "Region Name", "province": "Province Name", "action": "UPDATE"}},
    {{"id": 2, "region": null, "province": null, "action": "DELETE"}}
  ]
}}

Use action="DELETE" for invalid/unknown cities."""

    result = call_groq(prompt)
    
    if result and 'results' in result:
        return result['results']
    return []

def apply_places_updates(cleaned_data):
    if not cleaned_data:
        return 0, 0
    
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        updated = 0
        deleted = 0
        
        for item in cleaned_data:
            if item.get('action') == 'UPDATE':
                try:
                    sql = "UPDATE places SET region=%s, province=%s WHERE id=%s"
                    cursor.execute(sql, (item.get('region'), item.get('province'), item['id']))
                    updated += cursor.rowcount
                except mysql.connector.Error as err:
                    print(f"⚠️ SQL Error ID {item['id']}: {err}")
            elif item.get('action') == 'DELETE':
                try:
                    sql = "DELETE FROM places WHERE id=%s"
                    cursor.execute(sql, (item['id'],))
                    deleted += cursor.rowcount
                except mysql.connector.Error as err:
                    print(f"⚠️ SQL Error ID {item['id']}: {err}")
        
        conn.commit()
        cursor.close()
        conn.close()
        return updated, deleted
    except mysql.connector.Error as err:
        print(f"❌ Database Error: {err}")
        return 0, 0

# ============================================================================
# SERVICES CLEANING
# ============================================================================

def get_services_without_description(batch_size=50):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)
        query = f"SELECT id, name FROM services WHERE description IS NULL OR description = '' LIMIT {batch_size}"
        cursor.execute(query)
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        return rows
    except mysql.connector.Error as err:
        print(f"❌ Database Error: {err}")
        return []

def fill_services_locally(rows):
    results = []
    unknown_services = []
    
    for row in rows:
        name = row['name'].upper().strip()
        matched = False
        
        # Exact match
        if name in SERVICE_DESCRIPTIONS:
            results.append({
                'id': row['id'],
                'name': row['name'],
                'description': SERVICE_DESCRIPTIONS[name],
                'action': 'UPDATE'
            })
            print(f"  ✓ [LOCAL] ID {row['id']}: {row['name']}")
            matched = True
        else:
            # Partial match
            for key, desc in SERVICE_DESCRIPTIONS.items():
                if key in name or name in key:
                    results.append({
                        'id': row['id'],
                        'name': row['name'],
                        'description': desc,
                        'action': 'UPDATE'
                    })
                    print(f"  ✓ [PARTIAL] ID {row['id']}: {row['name']} ≈ {key}")
                    matched = True
                    break
        
        if not matched:
            unknown_services.append(row)
    
    return results, unknown_services

def fill_services_with_ai(rows):
    if not rows:
        return []
    
    services_list = [f"ID {row['id']}: {row['name']}" for row in rows]
    
    prompt = f"""You are a medical expert. Generate concise French descriptions (max 120 characters) for these medical services.

Services:
{chr(10).join(services_list)}

Return JSON:
{{
  "results": [
    {{"id": 1, "description": "French description here", "action": "UPDATE"}}
  ]
}}

Make descriptions professional and informative."""

    result = call_groq(prompt)
    
    if result and 'results' in result:
        return result['results']
    return []

def apply_service_updates(cleaned_data):
    if not cleaned_data:
        return 0
    
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        updated = 0
        
        for item in cleaned_data:
            if item.get('action') == 'UPDATE':
                try:
                    sql = "UPDATE services SET description=%s WHERE id=%s"
                    cursor.execute(sql, (item.get('description'), item['id']))
                    updated += cursor.rowcount
                except mysql.connector.Error as err:
                    print(f"⚠️ SQL Error ID {item['id']}: {err}")
        
        conn.commit()
        cursor.close()
        conn.close()
        return updated
    except mysql.connector.Error as err:
        print(f"❌ Database Error: {err}")
        return 0

# ============================================================================
# MAIN
# ============================================================================

def get_count(table, condition):
    try:
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM {table} WHERE {condition}")
        count = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        return count
    except:
        return 0

def select_model():
    """Let user choose which model to use"""
    global SELECTED_MODEL
    
    print("\n" + "=" * 70)
    print("🤖 SELECT GROQ MODEL")
    print("=" * 70)
    
    for key, model in AVAILABLE_MODELS.items():
        print(f"{key}. {model['name']}")
        print(f"   ID: {model['id']}")
        print(f"   {model['description']}\n")
    
    choice = input("Select model (1-4, or press Enter for default): ").strip()
    
    if choice in AVAILABLE_MODELS:
        SELECTED_MODEL = AVAILABLE_MODELS[choice]['id']
        print(f"\n✅ Selected: {AVAILABLE_MODELS[choice]['name']}\n")
    else:
        print(f"\n✅ Using default: Llama 3.3 70B (Versatile)\n")

def clean_places():
    print("\n" + "=" * 70)
    print(f"🏙️  CLEANING PLACES - Using {SELECTED_MODEL}")
    print("=" * 70)
    
    initial = get_count('places', 'region IS NULL OR province IS NULL')
    print(f"\n📊 Missing data: {initial}\n")
    
    if initial == 0:
        print("✨ All complete!")
        return
    
    total_updated = 0
    total_deleted = 0
    batch = 0
    
    while True:
        batch += 1
        print(f"\n{'─' * 70}\n📦 BATCH {batch}\n{'─' * 70}")
        
        rows = get_places_missing_region(50)
        if not rows:
            break
        
        print(f"📥 Processing {len(rows)} places")
        
        # Try local first
        local_results, unknown = fill_places_locally(rows)
        
        # Use AI for unknown
        if unknown:
            print(f"\n🤖 {len(unknown)} unknown cities, using Groq AI...")
            ai_results = fill_places_with_ai(unknown)
            if ai_results:
                local_results.extend(ai_results)
        
        if local_results:
            print(f"\n💾 Updating database...")
            updated, deleted = apply_places_updates(local_results)
            total_updated += updated
            total_deleted += deleted
            print(f"✅ {updated} updated, {deleted} deleted")
        
        time.sleep(1)
    
    print(f"\n{'=' * 70}\n✅ COMPLETE: {total_updated} updated, {total_deleted} deleted\n{'=' * 70}")

def clean_services():
    print("\n" + "=" * 70)
    print(f"🏥 CLEANING SERVICES - Using {SELECTED_MODEL}")
    print("=" * 70)
    
    condition = "description IS NULL OR description = ''"
    initial = get_count('services', condition)
    print(f"\n📊 Missing: {initial}\n")
    
    if initial == 0:
        print("✨ All complete!")
        return
    
    total = 0
    batch = 0
    
    while True:
        batch += 1
        print(f"\n{'─' * 70}\n📦 BATCH {batch}\n{'─' * 70}")
        
        rows = get_services_without_description(50)
        if not rows:
            break
        
        print(f"📥 Processing {len(rows)} services")
        
        local_results, unknown = fill_services_locally(rows)
        
        if unknown:
            print(f"\n🤖 {len(unknown)} unknown services, using Groq AI...")
            ai_results = fill_services_with_ai(unknown)
            if ai_results:
                local_results.extend(ai_results)
        
        if local_results:
            print(f"\n💾 Updating database...")
            updated = apply_service_updates(local_results)
            total += updated
            print(f"✅ {updated} updated")
        
        time.sleep(1)
    
    print(f"\n{'=' * 70}\n✅ COMPLETE: {total} updated\n{'=' * 70}")

if __name__ == "__main__":
    print("=" * 70)
    print("🚀 HYBRID CLEANER - Groq AI (Lightning Fast & Free)")
    print("=" * 70)
    
    # Let user select model
    select_model()
    
    print("\n1. Places\n2. Services\n3. Both")
    choice = input("\nChoice: ").strip()
    
    if choice == "1":
        clean_places()
    elif choice == "2":
        clean_services()
    elif choice == "3":
        clean_places()
        clean_services()
    
    print("\n🎉 DONE!")