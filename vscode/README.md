# ai-workflow-hub-spoke（VS Code Copilot 版）

## 2026-08-06: 這方式派出的spoke subagent有嚴重問題，先暫時不要使用。以下是說明

VS Code派出的subagent經測試和檢視log後，發現context會塞滿90%以上的和要作的事無關的context，有很大一部份是VS Code內建的一大串，然後會繼承整個專案的`AGENTS.md`這有可能浪費token、造成context污染之外，也會拖慢整個執行效率，甚至會觸發rate limit(TPM)的情況。

---

一套給 **VS Code Copilot Agent Mode** 使用的 AI 協作流程規範，以「主從形態（hub-spoke）」組織「規劃 → 實作 → 驗收」的完整開發流程。

> **模型配置**：DeepSeek V4 Pro 當 Hub，DeepSeek V4 Flash 為 spoke 預設，GPT-5.6 Luna 為備援
> **無需額外擴充套件**：VS Code Copilot 原生 subagent + custom agent + skill 機制

## 核心理念

> 規劃書是決策過程的有損投影；誰持有活脈絡，誰做那件事就便宜。

規劃與裁決留在有脈絡的 hub（長對話），執行下放到工單制的 spoke（獨立 sub-agent），品質裁決交給數字。

## 角色分工

| 角色 | Copilot 對應 | 模型 | 職責 |
|------|-------------|------|------|
| **使用者** | 你 | — | 做不做、目標、狀態變更 |
| **hub** | `Hub` custom agent | DeepSeek V4 Pro | 討論聚焦、寫規劃、發工單、派 sub-agent、融合回報 |
| **spoke** | sub-agent（平行執行） | DeepSeek V4 Flash / GPT-5.6 Luna | 唯讀審查，產出「觀察＋依據」，不產裁決 |

## 流程總覽

```
0. 使用者切換到 Hub agent → 討論 → decision 文件
1. Hub 依必答檢查撰寫 plan → 使用者審定
2. （可選）Hub 依規劃書範圍決定派 1–N 個 hole-finder sub-agent 審查
3. 實作 → test/lint/tsc/build 全綠 → report＋runbook
4. 使用者照 runbook 手測＋diff 過目 → commit/PR
```

## 目錄結構

```
專案根目錄/
├── AGENTS.md                                ← 流程規範
├── .vscode/
│   ├── settings.json                        ← 關閉 auto-compact
│   └── chatLanguageModels.json              ← BYOK 模型 token 上限
└── .github/
    ├── agents/
    │   ├── hub.agent.md                     ← Hub coordinator（DeepSeek V4 Pro）
    │   ├── explore-flash.agent.md           ← 探索型 sub-agent（DeepSeek V4 Flash）
    │   ├── hole-finder-feasibility.agent.md ← 可行性 lens（DeepSeek V4 Flash）
    │   ├── hole-finder-safety.agent.md      ← 安全/併發 lens（GPT-5.6 Luna）
    │   ├── hole-finder-cost.agent.md        ← 成本閘門 lens（DeepSeek V4 Flash）
    │   └── dispatch-broker.agent.md         ← 外派委託窗口（DeepSeek V4 Flash）
    └── skills/
        └── wrap/
            └── SKILL.md                     ← 收尾 skill（/wrap）
```

## 模型配置（含 fallback）

`model` 欄位支援陣列，依序嘗試直到找到可用模型。Spoke 預設用 DeepSeek V4 Flash，不可用時依序降級：

| 角色 | 優先 | 備援 1 | 備援 2 |
|------|------|--------|--------|
| Hub | DeepSeek V4 Pro | — | — |
| hole-finder-safety | GPT-5.6 Luna | DeepSeek V4 Pro | — |
| hole-finder-feasibility | DeepSeek V4 Flash | DeepSeek V4 Pro | GPT-5.6 Luna |
| hole-finder-cost | DeepSeek V4 Flash | DeepSeek V4 Pro | GPT-5.6 Luna |
| explore-flash | DeepSeek V4 Flash | DeepSeek V4 Pro | GPT-5.6 Luna |
| dispatch-broker | DeepSeek V4 Flash | Gemini 3.1 Flash Lite | — |

> 三個 hole-finder 只是工具箱範本，Hub 視範圍自行決定派幾個。你可以增刪 `.github/agents/` 下的檔案，並在 Hub 的 `agents:` 白名單調整。

## 接 Claude Code 的外派委託（dispatch-broker）

`dispatch-broker` 不在 Hub 的白名單內，兩者是平行角色：本端獨立作業走 Hub，接外部委託走 broker。它存在的理由是**跨供應商的異質視角**——Claude Code 的 subagent 一律跑在 Anthropic 模型上，要拿 DeepSeek／Gemini 的乾淨視角只能外派過來。

它的 `tools` 只有 `['agent']`，**連 read 都沒有**：它握有的一切來自對話窗，結構上不可能去翻 `_docs/`。它只做三件事——派 spoke、形式稽核、原文回收，不看內容、不下判斷。

使用方式：

1. 在 Claude Code 那端跑 `/find-holes`，選「外派模式」，hub 會產出一段自包含工單文字
2. VS Code Chat 切換到 **dispatch-broker**，整段貼進去
3. broker 平行派 hole-finder、稽核、回收，輸出「稽核表＋各 spoke 原文」
4. 整段貼回 Claude Code，由 hub 融合判讀、交使用者裁決

> **稽核的界線**：spoke 有 `['read','search']`，範圍是整個 workspace，VS Code 端沒有路徑白名單機制。broker 只能事後從「回報引用的路徑」與「spoke 自陳開啟過的檔案清單」抓越界——**抓得到「說了越界」，抓不到「越界了但沒說」**。隔離仍然靠 prompt 約束，broker 給的是流程監督與可稽核性，不是隔離保證。

### 報告過長時

三個 spoke 的原文加起來可能超出對話窗能穩定複製的長度。broker 預設 `tools: ['agent']` 沒有寫檔能力（這是刻意的——它因此碰不到 `_docs/`），兩個解法：

- **分段索取**：先要「稽核表 ＋ 第一個 spoke 原文」，複製完再要下一個。輸出骨架沒有規定必須一次全給，不用改任何設定。
- **臨時開寫檔**：在 `dispatch-broker.agent.md` 的 `tools` 加 `'edit'`，讓它把完整報告落檔到暫存目錄（如 `tmp/spoke/`），Claude Code 那端直接讀路徑。跑完把 `'edit'` 拿掉。

開了 `edit` 就失去「broker 碰不到檔案系統」這個硬保證——它同時獲得讀檔的路，`_docs/` 禁令降級成 prompt 約束，與 spoke 同級。落檔時要明確指定路徑並交代**不得寫入 `_docs/`、不得修改既有檔案**，落檔目錄也應進 `.gitignore`：spoke 回報不是文件版本，不該進版控。

## 使用方式

1. 將以下檔案複製到目標專案根目錄：
   - `.vscode/settings.json` → 關閉 auto-compact
   - `.vscode/chatLanguageModels.json` → BYOK 模型宣告與 token 上限
   - `.github/agents/` → Hub + 三個 hole-finder spoke + 外派委託窗口（dispatch-broker）
   - `.github/skills/wrap/` → 收尾 skill（`/wrap`）
   - `AGENTS.md` → 流程規範
2. 調整 `.vscode/settings.json` 中的模型名稱（若 Copilot 模型清單名稱不同）
3. 在 VS Code Chat 切換到 **Hub** agent（agents 下拉選單）
4. 開始討論、產出 decision → plan 文件
5. 說「要準備派出spoke(hole-finder) 進行審查 _docs/auth/plan_login.md，先決定劃分lens和要派多少個後，停手等我確認」→ Hub 自動平行 spawn hole-finder
6. 審查結果回收、融合、使用者裁決（第5、6步可以視情況循環來回操作，決定要再審什麼加派然後再回收修訂文件）
7. 和hub討論工作階段劃分，說「要開始開新對話session進實作，給我第一階段工單提示詞」
8. 實作完成後，如果有需要可以打 `/wrap` 或說「準備交接收尾」→ 自動四綠檢查＋產出驗收包（通常只有單一階段不一定需要，建議實作時用context長度能到 1M 的模型）

## `.vscode/settings.json` 與 `chatLanguageModels.json` 說明

- **`settings.json`** → `summarizeAgentConversationHistory.enabled: false`
  關閉 Copilot 的自動對話歷史壓縮。hub-spoke 流程不依賴 auto-compact。

- **`chatLanguageModels.json`** → BYOK 模型宣告
  新版 Copilot 改由此獨立設定檔管理自備模型。宣告 DeepSeek V4 Pro、Flash、
  GPT-5.6 Luna 三個模型及其 token 配額。

## 用內建 Explore 跑便宜模型

`explore-flash` 是預設就建好的探索型 sub-agent，已用 `model: 'DeepSeek V4 Flash (deepseek)'` 鎖死便宜模型，也在 Hub 的白名單內。

使用方式：需要探索 codebase 時，叫 Hub 改用 `explore-flash` 而非內建的 `Explore`。開場 prompt 加一句：

```
If you need to use the Explore subagent, use the explore-flash agent instead.
```

或是直接說改用哪個模型：

```
If you need to use the Explore subagent, switch to the DeepSeek V4 Flash model.
```

## 設計要點

- **版本只從 hub 出**：spoke 產出永遠不直接成為文件版本
- **平行執行、獨立 context**：每個 sub-agent 有自己的 context window，只拿到 need-to-know 段落
- **裁決權在使用者**：Hub 不自行改規劃書狀態欄
- **跨 provider 混搭**：Hub 用 DeepSeek V4 Pro，spoke 預設 Flash，備援 GPT-5.6 Luna
