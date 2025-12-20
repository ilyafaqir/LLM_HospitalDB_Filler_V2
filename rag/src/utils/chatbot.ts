import { Message } from '../types/chat'

// Configuration du chatbot
export const chatbotConfig = {
  name: 'Chef Marocain 🍽️',
  personality: 'spécialisé dans les recettes de cuisine marocaine traditionnelle et authentique',
  welcomeMessage: "Salam ! 👋 Je suis votre chef marocain virtuel. Je peux vous aider à préparer des tajines, couscous, pastillas, et toutes les délicieuses recettes de la cuisine marocaine. Quelle recette souhaitez-vous découvrir aujourd'hui ?",
  maxMessages: 100
}

// Interface pour la réponse de l'API RAG
interface RAGResponse {
  answer: string
  sources?: string[]
  confidence?: number
}

// Générer une réponse via l'API RAG
export const generateBotResponse = async (userMessage: string): Promise<string> => {
  try {
    console.log('🔄 Tentative de connexion à l\'API RAG...')
    console.log('📤 Envoi de la question:', userMessage)
    
    const response = await fetch('http://127.0.0.1:8000/query', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        question: userMessage
      })
    })

    console.log('📥 Réponse reçue, status:', response.status)

    if (!response.ok) {
      throw new Error(`Erreur HTTP: ${response.status} - ${response.statusText}`)
    }

    const data: RAGResponse = await response.json()
    console.log('📋 Données reçues:', data)
    
    // Formater la réponse avec les sources si disponibles
    let formattedResponse = data.answer || "Je n'ai pas pu trouver de réponse spécifique à votre question."
    
    if (data.sources && data.sources.length > 0) {
      formattedResponse += "\n\n📚 Sources consultées :"
      data.sources.forEach((source, index) => {
        formattedResponse += `\n• ${source}`
      })
    }
    
    if (data.confidence !== undefined) {
      formattedResponse += `\n\n🎯 Confiance : ${Math.round(data.confidence * 100)}%`
    }
    
    return formattedResponse
    
  } catch (error) {
    console.error('❌ Erreur lors de la communication avec l\'API RAG:', error)
    console.error('🔍 Détails de l\'erreur:', {
      message: error.message,
      name: error.name,
      stack: error.stack
    })
    
    // Réponses de fallback pour les cas d'erreur
    const lowerMessage = userMessage.toLowerCase()
    
    if (lowerMessage.includes('bonjour') || lowerMessage.includes('salut') || lowerMessage.includes('salam')) {
      return "Salam alaikum ! 👋 Je suis votre chef marocain. Je peux vous aider avec toutes les recettes de la cuisine marocaine : tajines, couscous, pastillas, harira, et bien plus encore. Quelle recette vous intéresse ?"
    }
    
    if (lowerMessage.includes('merci') || lowerMessage.includes('chokran')) {
      return "Afwan ! (De rien) 🍽️ N'hésitez pas à revenir pour d'autres recettes marocaines. B'saha ! (Bon appétit !)"
    }
    
    if (lowerMessage.includes('aide') || lowerMessage.includes('help')) {
      return "Je peux vous aider avec toutes les recettes marocaines : tajines (poulet, agneau, poisson), couscous, pastillas, harira, briouates, makouda, et bien d'autres plats traditionnels. Quelle recette souhaitez-vous préparer ?"
    }
    
    if (lowerMessage.includes('au revoir') || lowerMessage.includes('bye') || lowerMessage.includes('besslama')) {
      return "Besslama ! (Au revoir) 👋 Revenez bientôt pour découvrir de nouvelles recettes marocaines. B'saha !"
    }
    
    return "Désolé, je ne peux pas accéder à ma base de connaissances pour le moment. Pouvez-vous reformuler votre question ou réessayer plus tard ?"
  }
}

// Créer un nouveau message
export const createMessage = (content: string, sender: 'user' | 'bot'): Message => ({
  id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
  content,
  sender,
  timestamp: new Date()
})

// Vérifier si le message est valide
export const isValidMessage = (message: string): boolean => {
  return message.trim().length > 0 && message.trim().length <= 1000
}

// Tester la connexion à l'API RAG
export const testApiConnection = async (): Promise<boolean> => {
  try {
    console.log('🧪 Test de connexion à l\'API RAG...')
    
    const response = await fetch('http://127.0.0.1:8000/query', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        question: "test"
      })
    })

    console.log('📡 Test API - Status:', response.status)
    
    if (response.ok) {
      const data = await response.json()
      console.log('✅ API RAG fonctionnelle:', data)
      return true
    } else {
      console.log('❌ API RAG répond mais avec erreur:', response.status)
      return false
    }
    
  } catch (error) {
    console.error('❌ Erreur de connexion à l\'API RAG:', error)
    return false
  }
} 