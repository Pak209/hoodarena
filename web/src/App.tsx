import { Navigate, Route, Routes } from 'react-router-dom'
import { Header } from './components/Header'
import { Home } from './pages/Home'
import { Stake } from './pages/Stake'
import { Resolved } from './pages/Resolved'
import { Race } from './pages/Race'
import { How } from './pages/How'
import { Packs } from './pages/Packs'
import { Cards } from './pages/Cards'
import { Squad } from './pages/Squad'
import { Match } from './pages/Match'

export default function App() {
  return (
    <div className="app-shell">
      <Header />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/stake/:id" element={<Stake />} />
        <Route path="/resolved" element={<Resolved />} />
        <Route path="/race" element={<Race />} />
        <Route path="/how" element={<How />} />
        <Route path="/packs" element={<Packs />} />
        <Route path="/cards" element={<Cards />} />
        <Route path="/squad" element={<Squad />} />
        <Route path="/match" element={<Match />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </div>
  )
}
