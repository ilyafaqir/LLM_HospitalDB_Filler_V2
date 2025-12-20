# 🍽️ Chef Marocain - Assistant RAG pour Recettes Marocaines

Un chatbot intelligent basé sur le **RAG (Retrieval-Augmented Generation)** spécialisé dans les recettes de cuisine marocaine traditionnelle et authentique.

## 🎯 Description

Ce projet implémente un système RAG complet qui permet aux utilisateurs de découvrir et apprendre à préparer des plats marocains traditionnels. Le système recherche dans une base de connaissances de recettes avant de générer des réponses détaillées et pédagogiques.

## ✨ Fonctionnalités

- 🍲 **Recherche sémantique** : Trouve les recettes les plus pertinentes pour chaque question
- 💬 **Conversation naturelle** : Interface de chat moderne et intuitive
- 📚 **Base de connaissances** : Accès à une collection de recettes marocaines authentiques
- 🎨 **Design thématique** : Interface aux couleurs chaudes inspirées de la cuisine marocaine
- 💾 **Historique de conversation** : Maintient le contexte de la discussion
- 🌙 **Mode sombre** : Support du thème clair/sombre

## 🏗️ Architecture

### Backend (Python/FastAPI)
- **Framework** : FastAPI
- **LLM** : Groq (Llama 3.1 8B)
- **Vector Store** : FAISS
- **Embeddings** : HuggingFace (sentence-transformers/all-MiniLM-L6-v2)
- **Orchestration** : LangChain

### Frontend (React/TypeScript)
- **Framework** : React 18 + TypeScript
- **Styling** : Tailwind CSS
- **Animations** : Framer Motion
- **Build Tool** : Vite

## 🚀 Installation

### Prérequis
- Python 3.11+
- Node.js 18+
- Clé API Groq

### Backend

1. Installer les dépendances Python :
```bash
pip install fastapi uvicorn langchain-groq langchain-community langchain-huggingface faiss-cpu
```

2. Configurer la clé API :
   - Créer un fichier `.env` à la racine
   - Ajouter : `api="votre_cle_groq"`

3. Lancer le serveur :
```bash
python api.py
```

Le serveur démarre sur `http://localhost:8000`

### Frontend

1. Installer les dépendances :
```bash
npm install
```

2. Lancer le serveur de développement :
```bash
npm run dev
```

L'interface est accessible sur `http://localhost:5173`

## 📖 Utilisation

1. **Démarrer le backend** : `python api.py`
2. **Démarrer le frontend** : `npm run dev`
3. **Ouvrir le navigateur** : Aller sur `http://localhost:5173`
4. **Poser une question** : Par exemple :
   - "Comment préparer un tajine de poulet aux olives ?"
   - "Recette du couscous marocain traditionnel"
   - "Comment faire une pastilla ?"

## 🍽️ Exemples de Recettes

Le système peut vous aider avec :
- **Tajines** : Poulet aux olives, Agneau aux pruneaux, Poisson, etc.
- **Couscous** : Traditionnel, aux légumes, aux fruits secs
- **Pastillas** : B'stilla au poulet, aux fruits de mer
- **Soupes** : Harira, Chorba
- **Entrées** : Briouates, Makouda, Salades marocaines
- Et bien d'autres plats traditionnels !

## 🔧 Configuration

### Variables d'environnement

Créer un fichier `.env` :
```
api="votre_cle_groq"
```

Ou utiliser la variable d'environnement :
```bash
export GROQ_API_KEY="votre_cle_groq"
```

## 📊 Évaluation

Le projet inclut un script d'évaluation RAGAS pour mesurer les performances :

```bash
python ragas_eval.py
```

Métriques évaluées :
- **Faithfulness** : Fidélité de la réponse au contexte
- **Answer Relevancy** : Pertinence de la réponse
- **Context Precision** : Précision des documents récupérés
- **Context Recall** : Rappel des documents pertinents

## 📁 Structure du Projet

```
rag/
├── api.py                 # Backend FastAPI
├── ragas_eval.py          # Script d'évaluation
├── rag.ipynb              # Notebook pour créer l'index FAISS
├── data/                  # Documents PDF de recettes
├── faiss_index_cours/     # Index vectoriel FAISS
├── src/                   # Frontend React
│   ├── components/        # Composants React
│   ├── utils/             # Utilitaires
│   └── ...
└── .env                   # Configuration (non versionné)
```

## 🎨 Design

L'interface utilise un thème aux couleurs chaudes inspiré de la cuisine marocaine :
- **Couleurs principales** : Orange, Rouge, Ambre
- **Style** : Moderne avec animations fluides
- **Responsive** : Adapté mobile et desktop

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs
- Proposer de nouvelles fonctionnalités
- Améliorer la documentation
- Ajouter de nouvelles recettes

## 📝 Licence

MIT License

## 👨‍🍳 Auteur

Projet développé pour découvrir et partager les recettes de la cuisine marocaine traditionnelle.

---

**B'saha !** (Bon appétit !) 🍽️
