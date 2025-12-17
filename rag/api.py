import os
from operator import itemgetter # <--- NOUVEL IMPORT IMPORTANT
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
    temperature=0.0, 
    api_key=api_key
)

# --- 3. EMBEDDINGS ---
embedding = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")

# --- 4. CHARGEMENT FAISS ---
index_path = "faiss_index_hospitals" 
if not os.path.exists(index_path):
    raise FileNotFoundError(f"❌ Dossier '{index_path}' introuvable.")

vectorstore = FAISS.load_local(index_path, embedding, allow_dangerous_deserialization=True)
retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

# --- 5. GESTION DE LA MÉMOIRE (DICTIONNAIRE GLOBAL) ---
# Stocke l'historique : { "session_1": "Human: ... AI: ...", "session_2": ... }
sessions = {}

# --- 6. PROMPT AVEC HISTORIQUE ---
template_text = """
Tu es un assistant expert en hôpitaux marocains.
Tu dois répondre UNIQUEMENT à partir du contexte fourni (les fiches hôpitaux) et de l'historique de la conversation.

Ton objectif est de donner des réponses claires, structurées et courtes en français.

### Règles générales
1. Si l'utilisateur mentionne le nom d'un hôpital (ex. "Lalla Meriem", "Targuist"), concentre ta réponse sur cet hôpital.
2. Utilise l'historique pour comprendre les pronoms comme "il", "elle", "cet hôpital", "celui-ci".
3. Si une information n'apparaît pas dans le contexte, dis-le honnêtement (par ex. "Cette information n'est pas précisée dans la fiche de l'hôpital.").
4. Ne pas inventer de nouveaux hôpitaux ni de nouvelles données.
5. Réponds de manière concise (quelques phrases ou une petite liste à puces).

### Quand on pose une question sur un hôpital précis
- Résume les **informations générales** (type d'établissement, nombre de lits, région/ville si utile).
- Présente les **services médicaux principaux** si demandés.
- Présente les **équipements médicaux principaux** si demandés.
- Termine si possible par une **phrase de synthèse** simple.

### Contenu disponible
Historique de la conversation :
{history}

Contexte (extraits de la base de données hôpitaux) :
{context}

Question actuelle :
{question}

Réponse (en français, claire et structurée) :
"""

prompt = PromptTemplate.from_template(template_text)

def format_docs(docs):
    return "\n\n".join(list(set([doc.page_content for doc in docs])))

# --- 7. CHAÎNE RAG (MULTI-ENTRÉES) ---
# On utilise itemgetter pour récupérer 'question' et 'history' séparément
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
app = FastAPI(title="API Hôpitaux avec Mémoire", version="2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Nouveau modèle de requête : on ajoute session_id
class QueryRequest(BaseModel):
    question: str
    session_id: str = "default" # Identifiant unique de l'utilisateur (par défaut "default")

@app.post("/query")
def ask_question_api(request: QueryRequest):
    try:
        # 1. Récupérer l'historique existant pour cet ID (ou vide si nouveau)
        session_id = request.session_id
        history = sessions.get(session_id, "")

        # 2. Invoquer la chaîne avec la question ET l'historique
        answer = rag_chain.invoke({
            "question": request.question,
            "history": history
        })

        # 3. Mettre à jour l'historique avec la nouvelle question/réponse
        # On ajoute l'échange à la fin de la chaîne
        new_exchange = f"Humain: {request.question}\nAssistant: {answer}\n"
        updated_history = history + new_exchange
        
        # (Optionnel) Limiter l'historique aux 2000 derniers caractères pour ne pas saturer le LLM
        if len(updated_history) > 2000:
            updated_history = updated_history[-2000:]
            
        sessions[session_id] = updated_history

        return {"answer": answer}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- 9. LANCEMENT ---
if __name__ == "__main__":
    import uvicorn
    print("🚀 Serveur Hôpitaux (Avec Mémoire 🧠) en cours de démarrage...")
    uvicorn.run(app, host="0.0.0.0", port=8000)