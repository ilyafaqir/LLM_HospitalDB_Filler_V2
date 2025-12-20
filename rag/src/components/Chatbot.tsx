import React, { useState, useEffect, useRef } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Message } from '../types/chat'
import { chatbotConfig, generateBotResponse, createMessage, isValidMessage } from '../utils/chatbot'
import ChatMessage from './ChatMessage'
import ChatInput from './ChatInput'
import TypingIndicator from './TypingIndicator'
import QuickQuestions from './QuickQuestions'
import ParticleBackground from './ParticleBackground'
import { RefreshCw, Trash2 } from 'lucide-react'

const Chatbot: React.FC = () => {
  const [messages, setMessages] = useState<Message[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)

  // Charger l'historique au démarrage
  useEffect(() => {
    const saved = localStorage.getItem('chatHistory')
    if (saved) setMessages(JSON.parse(saved))
    else setMessages([createMessage(chatbotConfig.welcomeMessage, 'bot')])
  }, [])

  // Sauvegarder à chaque changement
  useEffect(() => {
    localStorage.setItem('chatHistory', JSON.stringify(messages))
  }, [messages])

  // Message de bienvenue initial
  useEffect(() => {
    const welcomeMessage = createMessage(chatbotConfig.welcomeMessage, 'bot')
    setMessages([welcomeMessage])
  }, [])

  // Auto-scroll vers le bas
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }

  useEffect(() => {
    scrollToBottom()
  }, [messages])

  const handleSendMessage = async (content: string) => {
    if (!isValidMessage(content)) {
      setError('Le message doit contenir entre 1 et 1000 caractères.')
      return
    }

    setError(null)
    setIsLoading(true)

    try {
      // Ajouter le message utilisateur
      const userMessage = createMessage(content, 'user')
      setMessages(prev => [...prev, userMessage])

      // Générer la réponse du bot
      const botResponse = await generateBotResponse(content)
      const botMessage = createMessage(botResponse, 'bot')
      setMessages(prev => [...prev, botMessage])
    } catch (err) {
      setError('Une erreur est survenue lors de la génération de la réponse.')
      console.error('Erreur chatbot:', err)
    } finally {
      setIsLoading(false)
    }
  }

  const handleClearChat = () => {
    setMessages([createMessage(chatbotConfig.welcomeMessage, 'bot')])
    setError(null)
  }

  const handleRestartChat = () => {
    setMessages([])
    setError(null)
    // Redémarrer avec le message de bienvenue
    setTimeout(() => {
      setMessages([createMessage(chatbotConfig.welcomeMessage, 'bot')])
    }, 100)
  }

  const handleQuickQuestion = (question: string) => {
    handleSendMessage(question)
  }

  return (
    <div className="w-full h-full px-2 md:px-6 py-4 bg-gradient-to-br from-orange-50 via-amber-50 to-red-50 dark:from-gray-900 dark:via-amber-950 dark:to-orange-950 flex flex-col items-center relative transition-colors duration-300 overflow-hidden">
      {/* Arrière-plan avec particules */}
      <ParticleBackground />
      
      <div className="w-full max-w-6xl bg-white dark:bg-gray-800 rounded-2xl shadow-2xl overflow-hidden border border-gray-200 dark:border-gray-700 transition-colors duration-300 flex flex-col flex-1 min-h-0">
        {/* En-tête du chat */}
        <motion.div 
          className="bg-gradient-to-r from-orange-600 via-red-600 to-amber-600 text-white p-3 md:p-4 rounded-t-2xl relative overflow-hidden shadow-lg"
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        >
          {/* Effet de brillance animé */}
          <motion.div
            className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent"
            animate={{ x: ['-100%', '100%'] }}
            transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
            style={{ width: '50%', height: '100%' }}
          />
          
          <div className="flex items-center justify-between relative z-10">
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.2, duration: 0.5 }}
              className="flex-1 min-w-0"
            >
              <motion.h2 
                className="text-lg md:text-xl font-bold truncate"
                animate={{ 
                  textShadow: [
                    "0 0 0px rgba(255,255,255,0)",
                    "0 0 10px rgba(255,255,255,0.3)",
                    "0 0 0px rgba(255,255,255,0)"
                  ]
                }}
                transition={{ duration: 2, repeat: Infinity }}
              >
                {chatbotConfig.name}
              </motion.h2>
              <p className="text-orange-100 text-xs md:text-sm truncate">{chatbotConfig.personality}</p>
              <p className="text-orange-200 text-[10px] md:text-xs mt-0.5 hidden sm:block">🍽️ Powered by RAG System - Recettes Marocaines Authentiques</p>
            </motion.div>
            
            <motion.div 
              className="flex space-x-1 md:space-x-2 flex-shrink-0 ml-2"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.3, duration: 0.5 }}
            >
              <motion.button
                onClick={handleRestartChat}
                className="p-1.5 md:p-2 hover:bg-white/20 rounded-lg transition-colors"
                title="Redémarrer la conversation"
                whileHover={{ scale: 1.1, rotate: 180 }}
                whileTap={{ scale: 0.95 }}
                transition={{ type: "spring", stiffness: 300 }}
              >
                <RefreshCw className="w-4 h-4 md:w-5 md:h-5" />
              </motion.button>
              <motion.button
                onClick={handleClearChat}
                className="p-1.5 md:p-2 hover:bg-white/20 rounded-lg transition-colors"
                title="Effacer l'historique"
                whileHover={{ scale: 1.1, rotate: 5 }}
                whileTap={{ scale: 0.95 }}
                transition={{ type: "spring", stiffness: 300 }}
              >
                <Trash2 className="w-4 h-4 md:w-5 md:h-5" />
              </motion.button>
            </motion.div>
          </div>
        </motion.div>

        {/* Zone des messages */}
        <motion.div 
          className="flex-1 overflow-y-auto p-3 md:p-4 bg-gradient-to-b from-orange-50/50 to-amber-50/30 dark:from-gray-800 dark:to-amber-950/50 relative transition-colors duration-300 min-h-0"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4, duration: 0.5 }}
        >
          <AnimatePresence mode="popLayout">
            {messages.map((message, index) => (
              <motion.div
                key={message.id}
                layout
                initial={{ opacity: 0, y: 20, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: -20, scale: 0.95 }}
                transition={{ 
                  duration: 0.4, 
                  delay: index * 0.1,
                  type: "spring",
                  stiffness: 100
                }}
              >
                <ChatMessage message={message} />
              </motion.div>
            ))}
            
            {isLoading && (
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.3 }}
              >
                <TypingIndicator />
              </motion.div>
            )}
          </AnimatePresence>
          
          {error && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4"
            >
              <p className="text-red-700 text-sm">{error}</p>
            </motion.div>
          )}
          
          {/* Afficher les questions rapides seulement si c'est le message de bienvenue */}
          {messages.length === 1 && messages[0].sender === 'bot' && (
            <QuickQuestions onQuestionClick={handleQuickQuestion} />
          )}
          
          <div ref={messagesEndRef} />
        </motion.div>

        {/* Zone de saisie */}
        <ChatInput
          onSendMessage={handleSendMessage}
          isLoading={isLoading}
          disabled={error !== null}
        />
        </div>
    </div>
  )
}

export default Chatbot 