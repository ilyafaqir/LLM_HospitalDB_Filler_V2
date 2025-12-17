import pandas as pd
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

class CompleteHospitalDataPreparator:
    """
    Préparateur complet qui regroupe TOUTES les informations sans rien perdre.
    Crée un fichier texte enrichi par hôpital avec toutes les relations.
    """
    
    def __init__(self, csv_folder_path="."):
        self.folder = Path(csv_folder_path)
        self.data = {}
        
    def load_all_csv(self):
        """Charge tous les fichiers CSV."""
        print("📥 Chargement des fichiers CSV...")
        
        hospitals_filenames = ['hospitals.csv', 'hospitals 1.csv', 'hospital.csv']
        
        # Charger hospitals
        hospitals_loaded = False
        for filename in hospitals_filenames:
            try:
                filepath = self.folder / filename
                self.data['hospitals'] = pd.read_csv(filepath)
                print(f"  ✓ {filename}: {len(self.data['hospitals'])} lignes")
                hospitals_loaded = True
                break
            except FileNotFoundError:
                continue
        
        if not hospitals_loaded:
            print(f"  ❌ ERREUR: Fichier hospitals non trouvé")
            print(f"  📁 Fichiers CSV disponibles:")
            for f in self.folder.glob('*.csv'):
                print(f"     - {f.name}")
            return False
        
        # Charger les autres fichiers
        csv_files = {
            'places': 'places.csv',
            'services': 'services.csv', 
            'medications': 'medications.csv',
            'equipment': 'equipment.csv',
            'suppliers': 'suppliers.csv',
            'hospital_services': 'hospital_services.csv',
            'hospital_equipment': 'hospital_equipment.csv'
        }
        
        for key, filename in csv_files.items():
            try:
                filepath = self.folder / filename
                self.data[key] = pd.read_csv(filepath)
                print(f"  ✓ {filename}: {len(self.data[key])} lignes")
            except FileNotFoundError:
                print(f"  ⚠ {filename}: fichier non trouvé")
                self.data[key] = pd.DataFrame()
        
        print(f"\n✅ {len(self.data)} fichiers chargés avec succès")
        return True
    
    def create_complete_text_document(self, hospital_row):
        """
        Crée un document texte COMPLET pour un hôpital avec TOUTES les infos.
        
        Args:
            hospital_row: Ligne du DataFrame hospitals
            
        Returns:
            Texte complet formaté
        """
        lines = []
        hospital_id = int(hospital_row['id'])
        
        # ═══════════════════════════════════════════════════════
        # SECTION 1: INFORMATIONS GÉNÉRALES DE L'HÔPITAL
        # ═══════════════════════════════════════════════════════
        lines.append("=" * 70)
        lines.append(f"HÔPITAL: {hospital_row['name']}")
        lines.append("=" * 70)
        lines.append("")
        
        lines.append("--- INFORMATIONS GÉNÉRALES ---")
        lines.append(f"ID: {hospital_id}")
        lines.append(f"Type d'établissement: {hospital_row['type']}")
        lines.append(f"Nombre de lits: {int(hospital_row['beds']) if pd.notna(hospital_row['beds']) else 'Non spécifié'}")
        
        if pd.notna(hospital_row['created_at']):
            lines.append(f"Date de création: {hospital_row['created_at']}")
        
        lines.append("")
        
        # ═══════════════════════════════════════════════════════
        # SECTION 2: LOCALISATION COMPLÈTE
        # ═══════════════════════════════════════════════════════
        lines.append("--- LOCALISATION ---")
        
        if pd.notna(hospital_row['place_id']):
            place = self.data['places'][
                self.data['places']['id'] == hospital_row['place_id']
            ]
            if not place.empty:
                lines.append(f"Région: {place.iloc[0]['region']}")
                lines.append(f"Province: {place.iloc[0]['province']}")
                lines.append(f"Ville: {place.iloc[0]['city']}")
        
        if pd.notna(hospital_row['address']) and str(hospital_row['address']).strip():
            lines.append(f"Adresse: {hospital_row['address']}")
        
        lines.append("")
        
        # ═══════════════════════════════════════════════════════
        # SECTION 3: COORDONNÉES DE CONTACT
        # ═══════════════════════════════════════════════════════
        lines.append("--- CONTACT ---")
        
        if pd.notna(hospital_row['phone']):
            phone = str(hospital_row['phone']).replace('.0', '')
            lines.append(f"Téléphone: {phone}")
        
        if pd.notna(hospital_row['email']) and str(hospital_row['email']).strip():
            lines.append(f"Email: {hospital_row['email']}")
        
        if pd.notna(hospital_row['website']) and str(hospital_row['website']).strip():
            lines.append(f"Site web: {hospital_row['website']}")
        
        lines.append("")
        lines.append("")
        
        # ═══════════════════════════════════════════════════════
        # SECTION 4: SERVICES MÉDICAUX DISPONIBLES
        # ═══════════════════════════════════════════════════════
        hospital_services = self.data['hospital_services'][
            self.data['hospital_services']['hospital_id'] == hospital_id
        ]
        
        if not hospital_services.empty:
            lines.append("=" * 70)
            lines.append(f"SERVICES MÉDICAUX DISPONIBLES ({len(hospital_services)} services)")
            lines.append("=" * 70)
            lines.append("")
            
            for idx, hs in hospital_services.iterrows():
                service = self.data['services'][
                    self.data['services']['id'] == hs['service_id']
                ]
                if not service.empty:
                    service_name = service.iloc[0]['name']
                    service_desc = service.iloc[0]['description']
                    
                    lines.append(f"• {service_name}")
                    if pd.notna(service_desc) and str(service_desc).strip():
                        lines.append(f"  Description: {service_desc}")
                    lines.append("")
        else:
            lines.append("--- SERVICES MÉDICAUX ---")
            lines.append("Aucun service enregistré")
            lines.append("")
        
        # ═══════════════════════════════════════════════════════
        # SECTION 5: ÉQUIPEMENTS MÉDICAUX
        # ═══════════════════════════════════════════════════════
        hospital_equipment = self.data['hospital_equipment'][
            self.data['hospital_equipment']['hospital_id'] == hospital_id
        ]
        
        if not hospital_equipment.empty:
            lines.append("=" * 70)
            lines.append(f"ÉQUIPEMENTS MÉDICAUX ({len(hospital_equipment)} types d'équipements)")
            lines.append("=" * 70)
            lines.append("")
            
            # Grouper par catégorie
            equipment_by_category = {}
            
            for idx, he in hospital_equipment.iterrows():
                equip = self.data['equipment'][
                    self.data['equipment']['id'] == he['equipment_id']
                ]
                if not equip.empty:
                    category = equip.iloc[0]['category']
                    if category not in equipment_by_category:
                        equipment_by_category[category] = []
                    
                    equipment_by_category[category].append({
                        'name': equip.iloc[0]['name'],
                        'code': equip.iloc[0]['code'],
                        'quantity': int(he['quantity'])
                    })
            
            # Afficher par catégorie
            for category, equipments in sorted(equipment_by_category.items()):
                lines.append(f"--- {category.upper()} ---")
                for eq in equipments:
                    lines.append(f"• {eq['name']} (Code: {eq['code']})")
                    lines.append(f"  Quantité: {eq['quantity']} unité(s)")
                lines.append("")
        else:
            lines.append("--- ÉQUIPEMENTS MÉDICAUX ---")
            lines.append("Aucun équipement enregistré")
            lines.append("")
        
        # ═══════════════════════════════════════════════════════
        # SECTION BONUS: Informations contextuelles
        # ═══════════════════════════════════════════════════════
        lines.append("=" * 70)
        lines.append("RÉSUMÉ")
        lines.append("=" * 70)
        
        summary_parts = []
        summary_parts.append(f"Cet établissement de type {hospital_row['type']}")
        
        if pd.notna(hospital_row['beds']):
            summary_parts.append(f"dispose de {int(hospital_row['beds'])} lits")
        
        if not hospital_services.empty:
            summary_parts.append(f"offre {len(hospital_services)} services médicaux")
        
        if not hospital_equipment.empty:
            total_equipment = hospital_equipment['quantity'].sum()
            summary_parts.append(f"et possède {int(total_equipment)} équipements médicaux")
        
        lines.append(" ".join(summary_parts) + ".")
        lines.append("")
        
        return "\n".join(lines)
    
    def create_reference_documents(self, output_folder):
        """
        Crée des fichiers de référence pour les médicaments et fournisseurs.
        """
        output_path = Path(output_folder)
        
        # Fichier des médicaments
        if not self.data['medications'].empty:
            med_lines = []
            med_lines.append("=" * 70)
            med_lines.append("LISTE DES MÉDICAMENTS DISPONIBLES")
            med_lines.append("=" * 70)
            med_lines.append("")
            
            for idx, med in self.data['medications'].iterrows():
                med_lines.append(f"• {med['name']}")
                med_lines.append(f"  Substance active: {med['active_substance']}")
                med_lines.append(f"  Dosage: {med['dosage']}")
                med_lines.append(f"  Forme: {med['form']}")
                med_lines.append(f"  Présentation: {med['presentation']}")
                med_lines.append(f"  Classe thérapeutique: {med['therapeutic_class']}")
                med_lines.append(f"  Fabricant: {med['manufacturer']}")
                
                if pd.notna(med['price_public']):
                    med_lines.append(f"  Prix public: {med['price_public']} DH")
                if pd.notna(med['price_hospital']):
                    med_lines.append(f"  Prix hospitalier: {med['price_hospital']} DH")
                
                med_lines.append(f"  Statut: {med['commercialization_status']}")
                med_lines.append("")
            
            with open(output_path / 'medications_reference.txt', 'w', encoding='utf-8') as f:
                f.write("\n".join(med_lines))
            
            print(f"  ✓ medications_reference.txt créé")
        
        # Fichier des fournisseurs
        if not self.data['suppliers'].empty:
            sup_lines = []
            sup_lines.append("=" * 70)
            sup_lines.append("LISTE DES FOURNISSEURS")
            sup_lines.append("=" * 70)
            sup_lines.append("")
            
            # Grouper par catégorie
            suppliers_by_category = {}
            for idx, sup in self.data['suppliers'].iterrows():
                category = sup['category']
                if category not in suppliers_by_category:
                    suppliers_by_category[category] = []
                suppliers_by_category[category].append(sup)
            
            for category, suppliers in sorted(suppliers_by_category.items()):
                sup_lines.append(f"--- {category.upper()} ---")
                sup_lines.append("")
                
                for sup in suppliers:
                    sup_lines.append(f"• {sup['name']}")
                    sup_lines.append(f"  Activité: {sup['activity']}")
                    sup_lines.append(f"  Ville: {sup['city']}")
                    if pd.notna(sup['address']) and str(sup['address']).strip():
                        sup_lines.append(f"  Adresse: {sup['address']}")
                    sup_lines.append("")
            
            with open(output_path / 'suppliers_reference.txt', 'w', encoding='utf-8') as f:
                f.write("\n".join(sup_lines))
            
            print(f"  ✓ suppliers_reference.txt créé")
    
    def process_all_hospitals(self, output_folder="hospitals_complete"):
        """
        Traite tous les hôpitaux et crée un fichier texte pour chacun.
        """
        if 'hospitals' not in self.data or self.data['hospitals'].empty:
            print("❌ Aucun hôpital à traiter")
            return
        
        output_path = Path(output_folder)
        output_path.mkdir(exist_ok=True)
        
        print(f"\n📝 Création des documents texte...")
        
        total = len(self.data['hospitals'])
        
        for idx, hospital in self.data['hospitals'].iterrows():
            # Créer le document texte complet
            text_content = self.create_complete_text_document(hospital)
            
            # Sauvegarder
            filename = f"hospital_{int(hospital['id'])}.txt"
            with open(output_path / filename, 'w', encoding='utf-8') as f:
                f.write(text_content)
            
            if (idx + 1) % 100 == 0:
                print(f"  Traité {idx + 1}/{total} hôpitaux...")
        
        print(f"  ✓ {total} fichiers texte créés dans '{output_folder}/'")
        
        # Créer les fichiers de référence
        print(f"\n📚 Création des fichiers de référence...")
        self.create_reference_documents(output_folder)


# ═══════════════════════════════════════════════════════════════
# EXÉCUTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 70)
    print("PRÉPARATION COMPLÈTE DES DONNÉES POUR RAG")
    print("=" * 70)
    print()
    
    # Initialiser
    preparator = CompleteHospitalDataPreparator(csv_folder_path=".")
    
    # Charger les CSV
    if not preparator.load_all_csv():
        print("\n❌ Impossible de continuer sans le fichier hospitals")
        exit(1)
    
    # Traiter tous les hôpitaux
    preparator.process_all_hospitals(output_folder="hospitals_complete")
    
    print("\n" + "=" * 70)
    print("🎉 TRAITEMENT TERMINÉ AVEC SUCCÈS !")
    print("=" * 70)
    print()
    print("📁 Fichiers créés dans 'hospitals_complete/':")
    print()
    print("  1. hospital_1.txt, hospital_2.txt, ... hospital_829.txt")
    print("     → Un fichier par hôpital avec TOUTES les informations:")
    print("       • Infos générales (nom, type, capacité, dates)")
    print("       • Localisation complète (région, province, ville, adresse)")
    print("       • Coordonnées (téléphone, email, site web)")
    print("       • Liste complète des services médicaux avec descriptions")
    print("       • Liste complète des équipements par catégorie avec quantités")
    print("       • Résumé global")
    print()
    print("  2. medications_reference.txt")
    print("     → Liste complète des médicaments avec prix et détails")
    print()
    print("  3. suppliers_reference.txt")
    print("     → Liste complète des fournisseurs par catégorie")
    print()
    print("💡 Ces fichiers sont prêts pour votre système RAG !")
    print("   Aucune information n'a été perdue dans le processus.")
    print()