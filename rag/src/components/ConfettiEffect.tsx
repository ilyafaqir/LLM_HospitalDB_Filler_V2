import React, { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

interface ConfettiPiece {
  id: number
  x: number
  y: number
  color: string
  rotation: number
  scale: number
}

interface ConfettiEffectProps {
  trigger: boolean
  onComplete?: () => void
}

const ConfettiEffect: React.FC<ConfettiEffectProps> = ({ trigger, onComplete }) => {
  const [confetti, setConfetti] = useState<ConfettiPiece[]>([])

  const colors = [
    '#3B82F6', // Bleu
    '#8B5CF6', // Violet
    '#06B6D4', // Cyan
    '#10B981', // Vert
    '#F59E0B', // Orange
    '#EF4444', // Rouge
    '#EC4899', // Rose
    '#84CC16'  // Lime
  ]

  useEffect(() => {
    if (trigger) {
      const pieces: ConfettiPiece[] = []
      
      // Créer 50 morceaux de confettis
      for (let i = 0; i < 50; i++) {
        pieces.push({
          id: i,
          x: Math.random() * window.innerWidth,
          y: -10,
          color: colors[Math.floor(Math.random() * colors.length)],
          rotation: Math.random() * 360,
          scale: Math.random() * 0.8 + 0.4
        })
      }
      
      setConfetti(pieces)
      
      // Nettoyer après l'animation
      const timer = setTimeout(() => {
        setConfetti([])
        onComplete?.()
      }, 3000)
      
      return () => clearTimeout(timer)
    }
  }, [trigger, onComplete])

  return (
    <AnimatePresence>
      {confetti.length > 0 && (
        <div className="fixed inset-0 pointer-events-none z-50">
          {confetti.map((piece) => (
            <motion.div
              key={piece.id}
              initial={{
                x: piece.x,
                y: piece.y,
                rotate: piece.rotation,
                scale: piece.scale,
                opacity: 1
              }}
              animate={{
                y: window.innerHeight + 100,
                rotate: piece.rotation + 720,
                x: piece.x + (Math.random() - 0.5) * 200,
                opacity: 0
              }}
              transition={{
                duration: 3,
                ease: "easeOut",
                delay: Math.random() * 0.5
              }}
              className="absolute w-2 h-2 rounded-sm"
              style={{
                backgroundColor: piece.color,
                boxShadow: `0 0 6px ${piece.color}`
              }}
            />
          ))}
        </div>
      )}
    </AnimatePresence>
  )
}

export default ConfettiEffect
