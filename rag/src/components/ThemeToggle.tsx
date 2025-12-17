import React from 'react'
import { motion } from 'framer-motion'
import { Sun, Moon } from 'lucide-react'
import { useTheme } from '../contexts/ThemeContext'

const ThemeToggle: React.FC = () => {
  const { theme, toggleTheme } = useTheme()

  return (
    <motion.button
      onClick={toggleTheme}
      className="relative p-2 rounded-lg bg-white/10 hover:bg-white/20 transition-colors backdrop-blur-sm border border-white/20"
      whileHover={{ scale: 1.05 }}
      whileTap={{ scale: 0.95 }}
      transition={{ type: "spring", stiffness: 300 }}
      title={`Basculer vers le mode ${theme === 'light' ? 'sombre' : 'clair'}`}
    >
      <div className="relative w-6 h-6">
        <motion.div
          className="absolute inset-0 flex items-center justify-center"
          initial={false}
          animate={{
            rotate: theme === 'dark' ? 180 : 0,
            scale: theme === 'dark' ? 0.8 : 1,
            opacity: theme === 'dark' ? 0 : 1
          }}
          transition={{ duration: 0.3, ease: "easeInOut" }}
        >
          <Sun className="w-5 h-5 text-yellow-400" />
        </motion.div>
        
        <motion.div
          className="absolute inset-0 flex items-center justify-center"
          initial={false}
          animate={{
            rotate: theme === 'light' ? -180 : 0,
            scale: theme === 'light' ? 0.8 : 1,
            opacity: theme === 'light' ? 0 : 1
          }}
          transition={{ duration: 0.3, ease: "easeInOut" }}
        >
          <Moon className="w-5 h-5 text-blue-300" />
        </motion.div>
      </div>
      
      {/* Effet de brillance */}
      <motion.div
        className="absolute inset-0 rounded-lg bg-gradient-to-r from-transparent via-white/20 to-transparent"
        animate={{ x: ['-100%', '100%'] }}
        transition={{ duration: 2, repeat: Infinity, ease: "linear" }}
        style={{ width: '50%', height: '100%' }}
      />
    </motion.button>
  )
}

export default ThemeToggle
