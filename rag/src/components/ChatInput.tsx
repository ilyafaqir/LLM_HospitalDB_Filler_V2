import React, { useState, useRef, useEffect } from 'react'
import { Send, Paperclip, Smile } from 'lucide-react'

interface ChatInputProps {
  onSendMessage: (message: string) => void
  isLoading: boolean
  disabled?: boolean
}

const ChatInput: React.FC<ChatInputProps> = ({ onSendMessage, isLoading, disabled = false }) => {
  const [message, setMessage] = useState('')
  const textareaRef = useRef<HTMLTextAreaElement>(null)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (message.trim() && !isLoading && !disabled) {
      onSendMessage(message.trim())
      setMessage('')
    }
  }

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSubmit(e)
    }
  }

  // Auto-resize textarea
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto'
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 120)}px`
    }
  }, [message])

  return (
    <form onSubmit={handleSubmit} className="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 p-4 transition-colors duration-300">
      <div className="flex items-end space-x-3">
        <div className="flex-1 relative">
          <textarea
            ref={textareaRef}
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Tapez votre message..."
            disabled={isLoading || disabled}
            className="w-full resize-none border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 dark:disabled:bg-gray-600 disabled:text-gray-500 dark:disabled:text-gray-400 placeholder-gray-500 dark:placeholder-gray-400"
            rows={1}
            maxLength={1000}
          />
          <div className="absolute bottom-2 right-2 flex items-center space-x-2">
            <button
              type="button"
              className="p-1 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
              disabled={isLoading || disabled}
            >
              <Paperclip className="w-4 h-4" />
            </button>
            <button
              type="button"
              className="p-1 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
              disabled={isLoading || disabled}
            >
              <Smile className="w-4 h-4" />
            </button>
          </div>
        </div>
        
        <button
          type="submit"
          disabled={!message.trim() || isLoading || disabled}
          className="bg-blue-500 text-white p-3 rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:bg-gray-300 dark:disabled:bg-gray-600 disabled:cursor-not-allowed transition-colors"
        >
          <Send className="w-5 h-5" />
        </button>
      </div>
      
      {message.length > 0 && (
        <div className="mt-2 text-xs text-gray-500 dark:text-gray-400 text-right">
          {message.length}/1000 caractères
        </div>
      )}
    </form>
  )
}

export default ChatInput 