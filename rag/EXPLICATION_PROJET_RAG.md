# 📚 Explication du Projet RAG - Assistant Éducatif

## 🎯 Objectif du Projet

Ce projet implémente un système **RAG (Retrieval Augmented Generation)** pour créer un assistant éducatif capable de répondre aux questions des étudiants en se basant sur une base de connaissances de documents académiques (Text Mining, Services Web, Récupération d'Information, etc.).

---

## 📋 Étapes Réalisées dans le Projet

### **Étape 1 : Préparation des Données**

**Ce qui a été fait :**
- Collecte de documents PDF académiques dans le dossier `data/`
- Documents sur : Text Mining, Services Web (SOAP/REST), Word2Vec, Topic Modeling, etc.
- Utilisation du notebook `rag.ipynb` pour traiter les documents

**Processus :**
1. Chargement des documents PDF avec `DirectoryLoader` de LangChain
2. Découpage des documents en chunks (morceaux) de texte avec `RecursiveCharacterTextSplitter`
   - Taille des chunks : 1000 caractères
   - Chevauchement : 200 caractères (pour éviter de couper les phrases importantes)
3. Résultat : Transformation des documents en petits segments exploitables

---

### **Étape 2 : Création de la Base Vectorielle (Embeddings)**

**Ce qui a été fait :**
- Conversion des chunks de texte en vecteurs numériques (embeddings)
- Utilisation du modèle `sentence-transformers/all-MiniLM-L6-v2` de HuggingFace
- Création d'un index vectoriel avec FAISS (Facebook AI Similarity Search)

**Pourquoi cette étape est importante :**
- Les embeddings permettent de représenter le sens sémantique du texte sous forme de nombres
- FAISS permet de rechercher rapidement les documents les plus similaires à une question
- L'index est sauvegardé dans `faiss_index_cours/` pour être réutilisé

**Résultat :**
- Base vectorielle contenant tous les chunks de documents indexés
- Capacité de recherche sémantique rapide

---

### **Étape 3 : Développement du Backend (API FastAPI)**

**Ce qui a été fait :**
- Création de l'API REST avec FastAPI dans `api.py`
- Configuration du modèle LLM (Groq avec Llama 3.1 8B)
- Intégration de la chaîne RAG complète

**Architecture du Backend :**

```
Question utilisateur
    ↓
Recherche dans FAISS (top 5 documents similaires)
    ↓
Récupération du contexte pertinent
    ↓
Construction du prompt avec contexte + historique
    ↓
Génération de la réponse par le LLM
    ↓
Retour de la réponse à l'utilisateur
```

**Fonctionnalités implémentées :**
1. **Recherche sémantique** : Trouve les documents les plus pertinents pour chaque question
2. **Gestion de session** : Maintient l'historique de conversation par utilisateur
3. **Prompt pédagogique** : Le LLM est configuré pour donner des explications détaillées et éducatives
4. **API REST** : Endpoint `/query` pour recevoir les questions et retourner les réponses

**Code clé :**
```python
# Chaîne RAG complète
rag_chain = (
    {
        "context": itemgetter("question") | retriever | format_docs,
        "question": itemgetter("question"),
        "history": itemgetter("history"), 
    }
    | prompt
    | llm
    | StrOutputParser()
)
```

---

### **Étape 4 : Développement du Frontend (Interface React)**

**Ce qui a été fait :**
- Interface web moderne avec React + TypeScript
- Design responsive avec Tailwind CSS
- Animations avec Framer Motion

**Composants développés :**
1. **Chatbot** : Composant principal gérant la conversation
2. **ChatInput** : Zone de saisie des questions
3. **ChatMessage** : Affichage des messages utilisateur/bot
4. **QuickQuestions** : Questions rapides suggérées
5. **TypingIndicator** : Indicateur de frappe pendant la génération
6. **ThemeToggle** : Basculement thème clair/sombre
7. **ApiStatus** : Vérification de la connexion à l'API

**Fonctionnalités :**
- Sauvegarde automatique de l'historique dans le localStorage
- Interface adaptative (mobile/desktop)
- Animations fluides pour une meilleure UX
- Gestion des erreurs et états de chargement

---

### **Étape 5 : Évaluation avec RAGAS**

**Ce qui a été fait :**
- Création du fichier `ragas_eval.py` pour évaluer la qualité du système RAG
- Utilisation de métriques standardisées pour mesurer les performances

**Métriques évaluées :**
1. **Faithfulness** : La réponse est-elle fidèle au contexte fourni ?
2. **Answer Relevancy** : La réponse est-elle pertinente par rapport à la question ?
3. **Context Precision** : Les documents récupérés sont-ils pertinents ?
4. **Context Recall** : Tous les documents pertinents ont-ils été récupérés ?

**Résultats obtenus :**
- Faithfulness : 83.33%
- Answer Relevancy : 78.43%
- Context Precision : 100%
- Context Recall : 75%

**Interprétation :**
- Le système récupère très bien les bons documents (Precision 100%)
- Les réponses sont fidèles au contexte (Faithfulness 83%)
- Amélioration possible sur la pertinence des réponses (Relevancy 78%)

---

## 🏗️ Architecture Technique Complète

### **Stack Technologique**

**Backend :**
- Python 3.11
- FastAPI (API REST)
- LangChain (orchestration RAG)
- Groq API (LLM Llama 3.1 8B)
- FAISS (base vectorielle)
- HuggingFace (embeddings)

**Frontend :**
- React 18
- TypeScript
- Vite (build tool)
- Tailwind CSS (styling)
- Framer Motion (animations)

**Évaluation :**
- RAGAS (métriques d'évaluation)

---

## 🔄 Flux de Données Complet

```
1. Utilisateur pose une question dans l'interface React
   ↓
2. Frontend envoie la question à l'API FastAPI (POST /query)
   ↓
3. Backend convertit la question en embedding
   ↓
4. Recherche dans FAISS pour trouver les 5 documents les plus similaires
   ↓
5. Récupération du contexte (chunks de documents pertinents)
   ↓
6. Construction du prompt avec :
   - Historique de conversation
   - Contexte récupéré
   - Question de l'utilisateur
   ↓
7. Envoi au LLM (Groq) pour génération de la réponse
   ↓
8. Retour de la réponse au frontend
   ↓
9. Affichage dans l'interface utilisateur
   ↓
10. Sauvegarde de l'échange dans l'historique
```

---

## 📊 Points Forts du Projet

1. **Système RAG complet** : De la préparation des données à l'interface utilisateur
2. **Base de connaissances spécialisée** : Documents académiques sur le Text Mining et les Services Web
3. **Interface moderne** : Design professionnel avec animations
4. **Gestion de contexte** : Maintien de l'historique de conversation
5. **Évaluation quantitative** : Utilisation de RAGAS pour mesurer les performances
6. **Architecture modulaire** : Séparation claire backend/frontend

---

## 🎓 Concepts RAG Expliqués

### **Qu'est-ce que RAG ?**

**RAG (Retrieval Augmented Generation)** est une technique qui combine :
- **Retrieval (Récupération)** : Recherche d'informations pertinentes dans une base de connaissances
- **Augmented (Augmenté)** : Enrichissement du prompt avec ces informations
- **Generation (Génération)** : Création de la réponse par un modèle de langage

### **Pourquoi utiliser RAG ?**

1. **Réduit les hallucinations** : Le LLM se base sur des documents réels
2. **Mise à jour facile** : On peut ajouter de nouveaux documents sans réentraîner le modèle
3. **Transparence** : On sait d'où viennent les informations (traçabilité)
4. **Spécialisation** : Le système peut être adapté à un domaine spécifique

### **Comment ça fonctionne ?**

1. **Indexation** : Les documents sont convertis en vecteurs et stockés
2. **Recherche** : Quand une question arrive, on cherche les documents similaires
3. **Enrichissement** : On ajoute ces documents au prompt du LLM
4. **Génération** : Le LLM génère une réponse basée sur le contexte fourni

---

## 📁 Structure du Projet

```
rag/
├── api.py                 # Backend FastAPI avec chaîne RAG
├── rag.py                 # (vide, peut être utilisé pour tests)
├── ragas_eval.py          # Script d'évaluation RAGAS
├── rag.ipynb              # Notebook pour créer l'index FAISS
├── data/                  # Documents PDF sources
│   ├── 1_Services_Web_SOAP_ver 3_published.pdf
│   ├── 2_REST_Web_Services_ver 3_published.pdf
│   ├── Conceptual_Foundations_of_Text_Mining...
│   └── ...
├── faiss_index_cours/     # Index vectoriel FAISS
│   ├── index.faiss
│   └── index.pkl
└── src/                    # Frontend React
    ├── App.tsx
    ├── components/
    │   ├── Chatbot.tsx
    │   ├── ChatInput.tsx
    │   ├── ChatMessage.tsx
    │   └── ...
    └── utils/
        └── chatbot.ts
```

---

## 🚀 Utilisation

### **Démarrer le Backend :**
```bash
python api.py
```
Le serveur démarre sur `http://localhost:8000`

### **Démarrer le Frontend :**
```bash
npm install
npm run dev
```
L'interface est accessible sur `http://localhost:5173`

### **Évaluer le système :**
```bash
python ragas_eval.py
```

---

## 📝 Conclusion

Ce projet démontre une implémentation complète d'un système RAG pour l'éducation, avec :
- ✅ Préparation et indexation des données
- ✅ Backend API fonctionnel
- ✅ Interface utilisateur moderne
- ✅ Évaluation quantitative des performances

Le système permet aux étudiants de poser des questions sur des concepts académiques et de recevoir des explications détaillées basées sur les documents de cours.

---

**Auteur :** [Votre nom]  
**Date :** 2024  
**Contexte :** Projet académique - Système RAG pour Assistant Éducatif

