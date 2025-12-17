export interface Message {
  id: string
  content: string
  sender: 'user' | 'bot'
  timestamp: Date
  isTyping?: boolean
}

export interface ChatState {
  messages: Message[]
  isLoading: boolean
  error: string | null
}

export interface ChatbotConfig {
  name: string
  personality: string
  welcomeMessage: string
  maxMessages: number
} 