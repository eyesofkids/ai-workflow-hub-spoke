# ai-workflow-hub-spoke（VS Code Copilot 版）

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
│   └── settings.json                        ← 專案級 Copilot 設定
└── .github/
    ├── agents/
    │   ├── hub.agent.md                     ← Hub coordinator（DeepSeek V4 Pro）
    │   ├── explore-flash.agent.md           ← 探索型 sub-agent（DeepSeek V4 Flash）
    │   ├── hole-finder-feasibility.agent.md ← 可行性 lens（DeepSeek V4 Flash）
    │   ├── hole-finder-safety.agent.md      ← 安全/併發 lens（GPT-5.6 Luna）
    │   └── hole-finder-cost.agent.md        ← 成本閘門 lens（DeepSeek V4 Flash）
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

> 三個 hole-finder 只是工具箱範本，Hub 視範圍自行決定派幾個。你可以增刪 `.github/agents/` 下的檔案，並在 Hub 的 `agents:` 白名單調整。

## 使用方式

1. 將以下檔案複製到目標專案根目錄：
   - `.vscode/settings.json` → 專案級 Copilot 設定（關閉 auto-compact + 自訂模型 token 上限）
   - `.github/agents/` → Hub + 三個 hole-finder spoke
   - `.github/skills/wrap/` → 收尾 skill（`/wrap`）
   - `AGENTS.md` → 流程規範
2. 調整 `.vscode/settings.json` 中的模型名稱（若 Copilot 模型清單名稱不同）
3. 在 VS Code Chat 切換到 **Hub** agent（agents 下拉選單）
4. 開始討論、產出 decision → plan
5. 說「幫我審查 _docs/auth/plan_login.md」→ Hub 自動平行 spawn hole-finder
6. 審查結果回收、融合、使用者裁決
7. 實作完成後打 `/wrap` 或說「收尾」→ 自動四綠檢查＋產出驗收包

## `.vscode/settings.json` 說明

專案級 VS Code Copilot 設定，只對該專案生效：

- **`summarizeAgentConversationHistory.enabled: false`**
  關閉 Copilot 的自動對話歷史壓縮。hub-spoke 流程不依賴 auto-compact，
  context 吃緊時改走手動交接（寫 handoff 文件 → 開新 session 冷啟動）。

- **`customModels`**
  宣告 DeepSeek V4 Pro、Flash 及 GPT-5.6 Luna 三個模型，並設定 DeepSeek V4 的 token 配額：
  616K 輸入 + 384K 輸出（輸入 = 1M 總長 − 384K 輸出上限）。

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
