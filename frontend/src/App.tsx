import './App.css'
import { DashPlayer } from './components/DashPlayer'

function App() {
  const dashManifestUrl = '/data/index.mpd'
  
  return (
    <div className="container">
      <h1>DASH Player</h1>
      <div className="player-container">
        <DashPlayer src={dashManifestUrl} />
      </div>
      <div className="info">
        <p>dataディレクトリ内のMPDファイルを再生しています</p>
        <p>ファイルパス: {dashManifestUrl}</p>
      </div>
    </div>
  )
}

export default App
