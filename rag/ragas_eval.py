"""
Petit script d'évaluation RAG avec ragas.

Prérequis :
- Dépendances : ragas, datasets, langchain-groq, langchain-community, langchain-huggingface
- Variables d'environnement : GROQ_API_KEY (ou adapter llm ci-dessous)

Exécution :
    python ragas_eval.py
"""

import os
from datasets import Dataset
from ragas import evaluate
from ragas.metrics import (
    faithfulness,
    answer_relevancy,
    context_precision,
    context_recall,
)
from langchain_groq import ChatGroq
from langchain_huggingface import HuggingFaceEmbeddings


def build_sample_dataset() -> Dataset:
    """Construit un dataset minimal pour illustrer l'évaluation."""
    examples = [
        {
            "question": "Explique la différence entre SOAP et REST.",
            "answer": "SOAP est un protocole avec un format XML strict, REST est un style architectural plus léger utilisant HTTP.",
            "contexts": [
                "SOAP impose un format XML et des enveloppes pour les messages.",
                "REST repose sur les verbes HTTP et accepte plusieurs formats (JSON, XML).",
            ],
            "ground_truth": "SOAP est un protocole basé sur XML avec des enveloppes définies; REST est un style architectural s'appuyant sur HTTP, plus léger et flexible (souvent JSON).",
        },
        {
            "question": "Qu'est-ce que le text mining ?",
            "answer": "Le text mining consiste à extraire de l'information et des patterns à partir de textes.",
            "contexts": [
                "Le text mining inclut le prétraitement (tokenisation, normalisation) et des méthodes statistiques ou de ML.",
                "On y retrouve aussi des techniques comme le topic modeling et la vectorisation.",
            ],
            "ground_truth": "Le text mining regroupe les techniques de prétraitement et d'analyse statistique/ML pour extraire des informations ou connaissances à partir de textes.",
        },
        {
            "question": "En quoi consiste le topic modeling ?",
            "answer": "Le topic modeling identifie automatiquement des thèmes latents dans un corpus, par des modèles comme LDA.",
            "contexts": [
                "Le topic modeling regroupe les documents autour de thèmes probabilistes.",
                "LDA est un modèle bayésien génératif qui découvre des distributions de sujets dans les textes.",
            ],
            "ground_truth": "Le topic modeling est un ensemble de méthodes pour découvrir des thèmes latents dans un corpus, souvent via LDA qui apprend des distributions de sujets et de mots.",
        },
        {
            "question": "À quoi sert Word2Vec dans la récupération d'information ?",
            "answer": "Word2Vec produit des vecteurs de mots capturant la similarité sémantique, utiles pour améliorer le matching dans la recherche.",
            "contexts": [
                "Word2Vec apprend des représentations distribuées où des mots proches partagent du contexte.",
                "Ces vecteurs permettent de mesurer la similarité sémantique au-delà du simple mot exact.",
            ],
            "ground_truth": "Word2Vec apprend des embeddings de mots reflétant leurs contextes, ce qui permet de comparer sémantiquement des requêtes et des documents et d'améliorer le rappel en recherche.",
        },
    ]
    return Dataset.from_list(examples)


def main() -> None:
    # Chargement de la clé Groq depuis l'env ou un .env local (clé "api=")
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key and os.path.exists(".env"):
        with open(".env", "r") as f:
            for line in f:
                if line.strip().startswith("api="):
                    api_key = line.split("=", 1)[1].strip().strip('"').strip("'")
                    break

    if not api_key:
        raise ValueError(
            "Clé GROQ manquante. Définissez GROQ_API_KEY ou ajoutez 'api=\"votre_cle\"' dans .env"
        )

    llm = ChatGroq(model_name="llama-3.1-8b-instant", temperature=0.0, api_key=api_key)
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/all-MiniLM-L6-v2"
    )

    dataset = build_sample_dataset()

    result = evaluate(
        dataset=dataset,
        metrics=[
            faithfulness,
            answer_relevancy,
            context_precision,
            context_recall,
        ],
        llm=llm,
        embeddings=embeddings,
    )

    print("Résultats ragas (moyenne des métriques) :")
    print(result)
    print("\nDétail par échantillon :")
    try:
        detail = result["per_sample"]
    except Exception:
        try:
            detail = result.to_pandas()
        except Exception:
            detail = "Détail par échantillon non disponible avec ce format de retour."
    print(detail)


if __name__ == "__main__":
    main()

