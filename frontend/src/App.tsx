import { useEffect, useState } from 'react'

// API の応答の形（backend の TaskModels と対応）
type Card = { id: number; text: string }
type Column = { id: number; name: string; cards: Card[] }
type Board = { id: number; name: string; columns: Column[] }

type State =
  | { status: 'loading' }
  | { status: 'error'; message: string }
  | { status: 'ok'; board: Board }

// S-01 タスク管理ボード画面（F-01 ボード表示）。表示のみで、書き込み機能は別 Issue。
function App() {
  const [state, setState] = useState<State>({ status: 'loading' })

  useEffect(() => {
    const controller = new AbortController()
    fetch('/api/board', { signal: controller.signal })
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`)
        return res.json() as Promise<Board>
      })
      .then((board) => setState({ status: 'ok', board }))
      .catch((e: unknown) => {
        if (controller.signal.aborted) return
        setState({ status: 'error', message: e instanceof Error ? e.message : String(e) })
      })
    return () => controller.abort()
  }, [])

  return (
    <main className="app">
      <h1>タスク管理ボード</h1>
      {state.status === 'loading' && <p className="notice">読み込み中…</p>}
      {state.status === 'error' && (
        <p className="notice error">サーバーに接続できません（{state.message}）</p>
      )}
      {state.status === 'ok' && (
        <div className="board">
          {state.board.columns.map((column) => (
            <section key={column.id} className="column">
              <h2>{column.name}</h2>
              <ul className="cards">
                {column.cards.map((card) => (
                  <li key={card.id} className="card">
                    {card.text}
                  </li>
                ))}
              </ul>
            </section>
          ))}
        </div>
      )}
    </main>
  )
}

export default App
