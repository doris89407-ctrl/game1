# 小小夢魔｜星星存錢夢

一款以 Godot 製作、可部署到 GitHub Pages 或 Netlify 的繁體中文生活理財教育遊戲。玩家陪著披黃斗篷的夢魔走過兩段夢境，完成互動挑戰、取得鑰匙，並比較冒險前後對理財概念的理解。

## 遊戲內容

- **夢境一：星星銀行**：練習分辨需要與想要，安排必要支出、儲蓄和預備金。
- **夢境二：月光市集**：認識分散投資、風險和預備金；遊戲清楚說明分散不能保證獲利。
- 每關有獨立分數；答錯可再試，使用提示或多次嘗試會影響該關分數。
- 開始與結尾各有兩題相同的概念題，成果畫面顯示前後答對比例及百分點變化。
- 支援鍵盤數字 1–3、滑鼠與觸控，含音效開關、減少動態效果及手機版排版。
- 遊戲不要求登入，最佳成績僅存在玩家目前的瀏覽器裝置。
- 以 Godot 4.7.2 的 Web 單執行緒範本匯出，避免網站主機需設定跨來源隔離標頭。
- 遊戲場景載入 Blender 製作的 Momo 3D 角色；可在 Blender 編輯 `assets/momo.blend`，網頁使用 `assets/momo.glb`。

所有星星、商店與情境皆為虛構教學模擬。遊戲不是投資建議；真實投資可能損失本金。

## 本機預覽

遊玩已匯出的網頁版，可用瀏覽器開啟根目錄 `index.html` 或本機伺服器預覽。修改 Godot 專案請以 Godot 4.7.2 開啟 `project.godot`；修改角色請用 Blender 開啟 `assets/momo.blend`，重新匯出 GLB 後再從 Godot Web preset 匯出。

若要以本機伺服器預覽已匯出的網頁版：

```sh
python3 -m http.server 8000
```

然後開啟 `http://localhost:8000`。

## 發佈到 GitHub Pages

此儲存庫已包含 GitHub Actions Pages 工作流程（`.github/workflows/pages.yml`）。推送到 `main` 後會自動部署根目錄的靜態網站。

首次發佈時，請到 GitHub 儲存庫的 **Settings → Pages → Build and deployment**，將 **Source** 設為 **GitHub Actions**。工作流程完成後，網址會是：

`https://doris89407-ctrl.github.io/game1/`

## 檔案

- `project.godot`、`main.tscn`、`main.gd`：Godot 遊戲專案與互動邏輯
- `export_presets.cfg`：Godot Web 單執行緒匯出設定
- `index.html`、`index.js`、`index.wasm`、`index.pck`：GitHub Pages 使用的 Godot Web 匯出檔
- `assets/momo.blend`、`assets/momo.glb`：Blender 可編輯場景與網頁角色模型
- `assets/dream-bank.png`、`assets/moon-market.png`：為本遊戲原創生成的場景美術
- `assets/ASSET-CREDITS.md`：美術來源與用途說明
