// Script de test pour l'API RAG
const testApi = async () => {
  console.log('🧪 Test de l\'API RAG...')
  
  try {
    const response = await fetch('http://127.0.0.1:8000/query', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        question: "parler de master mlaim machine learning and multimidia donner les module etudie?"
      })
    })

    console.log('📡 Status:', response.status)
    console.log('📡 Status Text:', response.statusText)
    
    if (response.ok) {
      const data = await response.json()
      console.log('✅ Réponse reçue:', data)
    } else {
      console.log('❌ Erreur HTTP:', response.status)
      const errorText = await response.text()
      console.log('❌ Détails:', errorText)
    }
    
  } catch (error) {
    console.error('❌ Erreur de connexion:', error.message)
    console.error('❌ Type d\'erreur:', error.name)
    
    if (error.code === 'ECONNREFUSED') {
      console.log('💡 Le serveur RAG n\'est probablement pas lancé sur le port 8000')
    }
  }
}

// Exécuter le test
testApi() 