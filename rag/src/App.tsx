
import Chatbot from './components/Chatbot'
import Header from './components/Header'
import { ThemeProvider } from './contexts/ThemeContext'

function App() {
  return (
    <ThemeProvider>
      <div className="h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800 transition-colors duration-300 flex flex-col overflow-hidden">
        <Header />
        <main className="flex-1 w-full px-2 py-2 overflow-hidden">
          <Chatbot />
        </main>
      </div>
    </ThemeProvider>
  )
}

export default App 