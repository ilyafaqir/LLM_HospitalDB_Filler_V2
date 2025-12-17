import React from 'react'
import { motion } from 'framer-motion'
import WaveAnimation from './WaveAnimation'

const TypingIndicator: React.FC = () => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20, scale: 0.95 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -10, scale: 0.95 }}
      transition={{ duration: 0.3, ease: "easeOut" }}
      className="flex justify-start mb-4"
    >
      <div className="flex items-start space-x-3 max-w-[70%]">
        <motion.div 
          className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 text-white flex items-center justify-center flex-shrink-0 shadow-lg"
          animate={{ 
            rotate: [0, 5, -5, 0],
            scale: [1, 1.05, 1]
          }}
          transition={{ 
            duration: 2, 
            repeat: Infinity,
            ease: "easeInOut"
          }}
        >
          <motion.div 
            className="w-4 h-4"
            animate={{ rotate: [0, 360] }}
            transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
          >
            <svg viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
            </svg>
          </motion.div>
        </motion.div>
        
        <motion.div 
          className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-gray-700 dark:to-gray-600 border border-blue-200 dark:border-gray-600 rounded-xl px-4 py-3 shadow-sm backdrop-blur-sm relative overflow-hidden"
          animate={{ 
            boxShadow: [
              "0 1px 3px rgba(0,0,0,0.1)",
              "0 4px 12px rgba(59, 130, 246, 0.15)",
              "0 1px 3px rgba(0,0,0,0.1)"
            ]
          }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          <div className="flex items-center space-x-2">
            <WaveAnimation isActive={true} />
            <motion.span 
              className="text-sm text-blue-600 dark:text-blue-400 font-medium"
              animate={{ opacity: [0.7, 1, 0.7] }}
              transition={{ duration: 2, repeat: Infinity }}
            >
              Assistant FSDM écrit...
            </motion.span>
          </div>
          
          {/* Effet de brillance */}
          <motion.div
            className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent"
            animate={{ x: ['-100%', '100%'] }}
            transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
            style={{ width: '50%', height: '100%' }}
          />
        </motion.div>
      </div>
    </motion.div>
  )
}

export default TypingIndicator 