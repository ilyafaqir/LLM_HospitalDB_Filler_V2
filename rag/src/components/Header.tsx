import React from 'react'
import { Bot, Settings, HelpCircle } from 'lucide-react'
import ThemeToggle from './ThemeToggle'
import ApiStatus from './ApiStatus'
import { testApiConnection } from '../utils/chatbot'

const Header: React.FC = () => {
  return (
    <header className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700 transition-colors duration-300">
      <div className="container mx-auto px-4 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
              <Bot className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900 dark:text-gray-100">Assistant Hôpitaux</h1>
              <p className="text-sm text-gray-500 dark:text-gray-400">Informations sur les hôpitaux et services de santé au Maroc</p>
            </div>
          </div>
          
          <div className="flex items-center space-x-3">
            <ApiStatus onTestApi={testApiConnection} />
            <ThemeToggle />
            <button className="p-2 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
              <HelpCircle className="w-5 h-5" />
            </button>
            <button className="p-2 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
              <Settings className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>
    </header>
  )
}

export default Header 