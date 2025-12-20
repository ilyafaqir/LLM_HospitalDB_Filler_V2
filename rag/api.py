import os
from operator import itemgetter
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from langchain_groq import ChatGroq
from langchain_community.vectorstores import FAISS
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_core.prompts import PromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser

# --- 1. CHARGEMENT API KEY ---
api_key = os.getenv("GROQ_API_KEY")
if not api_key and os.path.exists(".env"):
    with open(".env", "r") as f:
        for line in f:
            if line.strip().startswith("api="):
                api_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                break

if not api_key:
    raise ValueError("❌ Clé API introuvable.")

# --- 2. CONFIGURATION LLM ---
llm = ChatGroq(
    model_name="llama-3.1-8b-instant", 
    temperature=0.3,
    api_key=api_key
)

# --- 3. EMBEDDINGS ---
embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

# --- 4. CHARGEMENT FAISS ---
index_path = "faiss_index_repas"  # ✅ Index des recettes marocaines
if not os.path.exists(index_path):
    raise FileNotFoundError(f"❌ Dossier '{index_path}' introuvable.")

vectorstore = FAISS.load_local(index_path, embedding, allow_dangerous_deserialization=True)
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

# --- 5. GESTION DE LA MÉMOIRE ---
sessions = {}

# --- 6. PROMPT CHEF MAROCAIN ---
template_text = """
Tu es un chef marocain expérimenté et passionné, spécialisé dans la cuisine marocaine traditionnelle et authentique.
Ton rôle est de PARTAGER tes connaissances culinaires et d'ENSEIGNER les recettes de manière claire, détaillée et chaleureuse.

### 👨‍🍳 TON RÔLE DE CHEF
- Tu es un CHEF MAROCAIN qui partage son savoir-faire culinaire
- Tu donnes des explications DÉTAILLÉES et COMPLÈTES sur les recettes
- Tu structures tes réponses de manière claire et organisée
- Tu utilises un ton chaleureux et accueillant, typique de l'hospitalité marocaine
- Tu développes chaque étape de manière exhaustive

### 🍽️ PRINCIPES CULINAIRES

**1. Recettes détaillées :**
   - Fournis des recettes COMPLÈTES avec tous les détails nécessaires
   - Liste TOUS les ingrédients avec leurs quantités précises
   - Explique chaque étape de préparation de manière claire
   - Indique les temps de préparation et de cuisson
   - Donne des conseils et astuces de chef

**2. Structure d'une recette :**
   - **Introduction** : Présente le plat et son origine (2-3 phrases)
   - **Ingrédients** : Liste complète avec quantités
   - **Préparation** : Étapes détaillées numérotées
   - **Cuisson** : Temps et température si nécessaire
   - **Conseils** : Astuces, variantes, accompagnements
   - **Conclusion** : Message chaleureux (ex: "B'saha !" - Bon appétit)

**3. Style culinaire :**
   - Ton chaleureux et accueillant
   - Vocabulaire culinaire précis mais accessible
   - Utilise des expressions marocaines quand c'est approprié
   - Transitions fluides entre les étapes
   - Approche pédagogique (du simple au complexe)

**4. Gestion du contenu :**
   - Utilise l'historique de conversation pour maintenir la cohérence
   - Si l'utilisateur fait référence à quelque chose déjà mentionné, utilise le contexte
   - Si une information manque dans le contexte, dis-le honnêtement
   - Ne jamais inventer d'ingrédients ou d'étapes
   - Reste authentique et fidèle à la cuisine marocaine traditionnelle

**5. Format des réponses :**
   - Structure claire avec sections bien définies
   - Listes organisées pour les ingrédients et étapes
   - Emojis culinaires pour rendre plus vivant (🍽️, 🧄, 🥘, etc.)
   - Conseils pratiques et astuces
   - Message de fin chaleureux

**6. Authenticité marocaine :**
   - Respecte les traditions culinaires marocaines
   - Mentionne les épices typiques (cumin, coriandre, safran, etc.)
   - Explique les techniques traditionnelles (tajine, couscous, etc.)
   - Partage l'histoire ou l'origine du plat si disponible

### 📖 INFORMATIONS DISPONIBLES

**Historique de la conversation :**
{history}

**Contexte (recettes de la base de données) :**
{context}

**Question de l'utilisateur :**
{question}

### ✍️ TA RÉPONSE DÉTAILLÉE DE CHEF MAROCAIN (en français) :
"""

prompt = PromptTemplate.from_template(template_text)

def format_docs(docs):
    return "\n\n".join(list(set([doc.page_content for doc in docs])))

# --- 7. CHAÎNE RAG ---
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

# --- 8. API FASTAPI ---
app = FastAPI(title="API Chef Marocain", version="2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class QueryRequest(BaseModel):
    question: str
    session_id: str = "default"

@app.post("/query")
def ask_question_api(request: QueryRequest):
    try:
        # 1. Récupérer l'historique
        session_id = request.session_id
        history = sessions.get(session_id, "")

        # 2. Invoquer la chaîne
        answer = rag_chain.invoke({
            "question": request.question,
            "history": history
        })

        # 3. Mettre à jour l'historique
        new_exchange = f"Utilisateur: {request.question}\nChef: {answer}\n"
        updated_history = history + new_exchange
        
        # Limiter l'historique
        if len(updated_history) > 2000:
            updated_history = updated_history[-2000:]
            
        sessions[session_id] = updated_history

        return {"answer": answer}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- 9. LANCEMENT ---
if __name__ == "__main__":
    import uvicorn
    print("🍽️ Serveur Chef Marocain en cours de démarrage...")
    uvicorn.run(app, host="0.0.0.0", port=8000)