import React from 'react';
import { motion } from 'framer-motion';
import { Info } from 'lucide-react';

type QuickQuestionsProps = {
  onQuestionClick: (question: string) => void;
};

function QuickQuestions({ onQuestionClick }: QuickQuestionsProps) {
  const questions = [
    "Comment préparer un tajine de poulet aux olives et citron ?",
    "Quelle est la recette traditionnelle du couscous marocain ?",
    "Comment faire une pastilla (b'stilla) marocaine ?",
    "Recette de la harira marocaine traditionnelle",
    "Comment préparer des briouates au poulet ?",
    "Recette du tajine d'agneau aux pruneaux et amandes",
  ];

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4 mb-4 transition-colors duration-300">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
        Questions fréquentes
      </h3>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.05 }}
        className="bg-orange-50 dark:bg-amber-900/20 rounded-xl p-3 border border-orange-200 dark:border-amber-800"
      >
        <div className="flex items-center space-x-2 text-orange-700 dark:text-orange-400 font-medium mb-3">
          <Info className="w-5 h-5" />
          <span>🍽️ Recettes populaires</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {questions.map((question, questionIndex) => (
            <button
              key={questionIndex}
              onClick={() => onQuestionClick(question)}
              className="block w-full text-left p-3 text-xs md:text-sm text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-orange-100 dark:hover:bg-amber-900/30 hover:text-orange-800 dark:hover:text-orange-300 rounded-lg transition-colors border border-transparent hover:border-orange-300 dark:hover:border-amber-700 shadow-sm"
            >
              {question}
            </button>
          ))}
        </div>
      </motion.div>
    </div>
  );
}

export default QuickQuestions;