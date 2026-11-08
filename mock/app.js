const COLUMNS = [
  { id: "todo", name: "未着手" },
  { id: "doing", name: "進行中" },
  { id: "done", name: "完了" },
];

let nextId = 4;
const cards = [
  { id: 1, column: "todo", text: "要件定義書を読み直す" },
  { id: 2, column: "doing", text: "画面モックを作る" },
  { id: 3, column: "done", text: "リポジトリを作成する" },
];

const board = document.getElementById("board");
let draggingId = null;

function render() {
  board.textContent = "";
  COLUMNS.forEach((col) => board.appendChild(renderColumn(col)));
}

function renderColumn(col) {
  const el = document.createElement("section");
  el.className = "column";

  const h = document.createElement("h2");
  h.textContent = col.name;
  el.appendChild(h);

  const list = document.createElement("div");
  list.className = "cards";
  cards.filter((c) => c.column === col.id).forEach((c) => list.appendChild(renderCard(c)));
  el.appendChild(list);

  // ドロップ先
  el.addEventListener("dragover", (e) => { e.preventDefault(); el.classList.add("drag-over"); });
  el.addEventListener("dragleave", (e) => { if (!el.contains(e.relatedTarget)) el.classList.remove("drag-over"); });
  el.addEventListener("drop", (e) => {
    e.preventDefault();
    const card = cards.find((c) => c.id === draggingId);
    if (card && card.column !== col.id) { card.column = col.id; }
    draggingId = null;
    render();
  });

  // 入力欄・追加ボタン・エラー表示
  const form = document.createElement("div");
  form.className = "add";
  const input = document.createElement("input");
  input.type = "text";
  input.placeholder = "タスクを入力";
  const btn = document.createElement("button");
  btn.textContent = "追加";
  form.append(input, btn);
  el.appendChild(form);

  const err = document.createElement("div");
  err.className = "error-msg";
  el.appendChild(err);

  const add = () => {
    const text = input.value.trim();
    if (!text) {
      input.classList.add("error");
      err.textContent = "タスクの内容を入力してください";
      return;
    }
    cards.push({ id: nextId++, column: col.id, text });
    render();
  };
  btn.addEventListener("click", add);
  input.addEventListener("keydown", (e) => { if (e.key === "Enter" && !e.isComposing) add(); });
  input.addEventListener("input", () => { input.classList.remove("error"); err.textContent = ""; });

  return el;
}

function renderCard(c) {
  const el = document.createElement("div");
  el.className = "card";
  el.draggable = true;
  el.textContent = c.text;

  const del = document.createElement("button");
  del.className = "del";
  del.textContent = "×";
  del.title = "削除";
  del.addEventListener("click", () => {
    cards.splice(cards.findIndex((x) => x.id === c.id), 1);
    render();
  });
  el.appendChild(del);

  el.addEventListener("dragstart", () => { draggingId = c.id; setTimeout(() => el.classList.add("dragging"), 0); });
  el.addEventListener("dragend", () => el.classList.remove("dragging"));
  return el;
}

render();
