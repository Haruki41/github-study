import { useEffect, useState } from 'react'

// API の応答の形（backend の TaskModels と対応）。ボード画面の実装時に整理する。
type Board = {
  id: number
  name: string
  columns: { id: number; name: string; cards: { id: number; text: string }[] }[]
}

type State =
  | { status: 'loading' }
  | { status: 'error'; message: string }
  | { status: 'ok'; board: Board }

// 環境構築の確認用の最小画面。ボード表示は別 Issue で作る。
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
    <main>
      <h1>タスク管理ボード（API 接続確認）</h1>
      {state.status === 'loading' && <p>読み込み中…</p>}
      {state.status === 'error' && <p>サーバーに接続できません（{state.message}）</p>}
      {state.status === 'ok' && (
        <p>
          接続できました：ボード「{state.board.name}」、列 {state.board.columns.length} 個、
          カード {state.board.columns.reduce((n, c) => n + c.cards.length, 0)} 枚
        </p>
      )}
    </main>
  )
}

export default App
