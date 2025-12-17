import React from 'react';
import { motion } from 'framer-motion';
import { Info } from 'lucide-react';

type QuickQuestionsProps = {
  onQuestionClick: (question: string) => void;
};

function QuickQuestions({ onQuestionClick }: QuickQuestionsProps) {
  const questions = [
    "Pour l'hôpital Mohamed V, donne-moi un résumé (type, lits, date de création).",
    "Quel est le type d'établissement de l'hôpital Mohamed V et combien de lits sont disponibles ?",
    "Depuis quand l'hôpital Mohamed V est-il en service ?",
    "Quels sont les principaux services médicaux disponibles à l'hôpital Mohamed V ?",
    "Quels équipements médicaux importants possède l'hôpital Mohamed V ?",
    "Fais une synthèse des points forts de l'hôpital Mohamed V (services, équipements, capacités, etc.).",
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
        className="bg-blue-50 dark:bg-gray-700 rounded-xl p-3 border border-blue-100 dark:border-gray-600"
      >
        <div className="flex items-center space-x-2 text-blue-600 dark:text-blue-400 font-medium mb-3">
          <Info className="w-5 h-5" />
          <span>Questions hôpital</span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {questions.map((question, questionIndex) => (
            <button
              key={questionIndex}
              onClick={() => onQuestionClick(question)}
              className="block w-full text-left p-3 text-xs md:text-sm text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-600 hover:bg-blue-100 dark:hover:bg-gray-500 hover:text-blue-700 dark:hover:text-blue-300 rounded-lg transition-colors border border-transparent hover:border-blue-200 dark:hover:border-gray-400 shadow-sm"
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