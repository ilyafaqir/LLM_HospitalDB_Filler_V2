import React from 'react'
import { motion } from 'framer-motion'

interface WaveAnimationProps {
  isActive: boolean
  className?: string
}

const WaveAnimation: React.FC<WaveAnimationProps> = ({ isActive, className = '' }) => {
  const waveVariants = {
    animate: {
      scale: [1, 1.2, 1],
      opacity: [0.7, 0.3, 0.7],
      transition: {
        duration: 1.5,
        repeat: Infinity,
        ease: "easeInOut"
      }
    },
    inactive: {
      scale: 1,
      opacity: 0.3,
      transition: {
        duration: 0.3
      }
    }
  }

  return (
    <div className={`relative flex items-center justify-center ${className}`}>
      {[0, 1, 2].map((index) => (
        <motion.div
          key={index}
          className="absolute w-3 h-3 bg-blue-500 rounded-full"
          variants={waveVariants}
          animate={isActive ? "animate" : "inactive"}
          style={{
            animationDelay: `${index * 0.2}s`
          }}
        />
      ))}
    </div>
  )
}

export default WaveAnimation
