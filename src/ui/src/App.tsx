import { useState, useEffect } from 'react'
import './App.css'
import { incrementCounter, getCurrentTime, sendMessageToZig, isBridgeAvailable } from './lib/zigBridge'

function App() {
  const [count, setCount] = useState(0)
  const [zigCount, setZigCount] = useState(0)
  const [currentTime, setCurrentTime] = useState<number | null>(null)
  const [message, setMessage] = useState('')
  const [response, setResponse] = useState('')
  const [bridgeAvailable, setBridgeAvailable] = useState(false)

  // Check if the bridge is available on component mount
  useEffect(() => {
    setBridgeAvailable(isBridgeAvailable())
  }, [])

  // Handle incrementing the counter in Zig
  const handleZigIncrement = async () => {
    try {
      const result = await incrementCounter(zigCount)
      setZigCount(result)
    } catch (error) {
      console.error('Failed to increment counter in Zig:', error)
    }
  }

  // Handle getting the current time from Zig
  const handleGetTime = async () => {
    try {
      const timestamp = await getCurrentTime()
      setCurrentTime(timestamp)
    } catch (error) {
      console.error('Failed to get current time from Zig:', error)
    }
  }

  // Handle sending a message to Zig
  const handleSendMessage = async () => {
    if (!message) return

    try {
      const result = await sendMessageToZig(message)
      setResponse(result.message)
    } catch (error) {
      console.error('Failed to send message to Zig:', error)
      setResponse('Error: Failed to send message')
    }
  }

  return (
    <div className="container">
      <h1>Zig-React Bridge Demo</h1>

      {!bridgeAvailable && (
        <div className="warning">
          <p>⚠️ Zig bridge is not available. Make sure you're running the app through the Zig WebView.</p>
        </div>
      )}

      <div className="card">
        <h2>React Counter (Client-side only)</h2>
        <p>This counter is managed by React state only</p>
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
      </div>

      <div className="card">
        <h2>Zig Counter (Bridge Demo)</h2>
        <p>This counter is incremented by the Zig backend</p>
        <button onClick={handleZigIncrement} disabled={!bridgeAvailable}>
          Zig count is {zigCount}
        </button>
      </div>

      <div className="card">
        <h2>Get Current Time from Zig</h2>
        <button onClick={handleGetTime} disabled={!bridgeAvailable}>
          Get Current Timestamp
        </button>
        {currentTime !== null && (
          <p>Current timestamp from Zig: {currentTime}</p>
        )}
      </div>

      <div className="card">
        <h2>Send Message to Zig</h2>
        <div className="input-group">
          <input
            type="text"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Enter a message to send to Zig"
            disabled={!bridgeAvailable}
          />
          <button onClick={handleSendMessage} disabled={!bridgeAvailable || !message}>
            Send
          </button>
        </div>
        {response && (
          <p>Response: {response}</p>
        )}
      </div>
    </div>
  )
}

export default App
