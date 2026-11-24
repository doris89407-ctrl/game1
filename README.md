# 小小夢魔｜星星存錢夢

一款繁體中文、手機和桌面皆可玩的生活理財教育遊戲。玩家陪著披黃斗篷的夢魔走過兩段夢境，完成互動挑戰、取得鑰匙，並比較冒險前後對理財概念的理解。

## 遊戲內容

- **夢境一：星星銀行**：練習分辨需要與想要，安排必要支出、儲蓄和預備金。
- **夢境二：月光市集**：認識分散投資、風險和預備金；遊戲清楚說明分散不能保證獲利。
- 每關有獨立分數；答錯可再試，使用提示或多次嘗試會影響該關分數。
- 開始與結尾各有兩題相同的概念題，成果畫面顯示前後答對比例及百分點變化。
- 支援鍵盤數字 1–3、滑鼠與觸控，含音效開關、減少動態效果及手機版排版。
- 遊戲不要求登入，最佳成績僅存在玩家目前的瀏覽器裝置。

所有星星、商店與情境皆為虛構教學模擬。遊戲不是投資建議；真實投資可能損失本金。

## 本機預覽

直接以瀏覽器開啟 `index.html`，或在專案資料夾執行：

```sh
python3 -m http.server 8000
```

然後開啟 `http://localhost:8000`。

## 發佈到 GitHub Pages

此儲存庫已包含 GitHub Actions Pages 工作流程（`.github/workflows/pages.yml`）。推送到 `main` 後會自動部署根目錄的靜態網站。

首次發佈時，請到 GitHub 儲存庫的 **Settings → Pages → Build and deployment**，將 **Source** 設為 **GitHub Actions**。工作流程完成後，網址會是：

`https://doris89407-ctrl.github.io/game1/`

## 檔案

- `index.html`：遊戲畫面結構
- `style.css`：介面、場景效果、響應式與減少動態效果
- `game.js`：關卡互動、計分、前後測及成果紀錄
- `assets/dream-bank.png`、`assets/moon-market.png`：為本遊戲原創生成的場景美術
- `assets/ASSET-CREDITS.md`：美術來源與用途說明
