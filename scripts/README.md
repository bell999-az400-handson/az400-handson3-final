# Work Items 自動作成スクリプト - 使い方

## 📋 前提条件

1. **Azure CLI がインストールされていること**
   ```powershell
   az --version
   ```

2. **Azure にログインしていること**
   ```powershell
   az login
   ```

3. **Azure DevOps プロジェクトが作成されていること**
   - https://dev.azure.com にアクセス
   - Organization を選択または作成
   - プロジェクト `az400-handson3-final` を作成（Agile プロセス）

## 🚀 使い方

### ステップ1: Azure DevOps の Organization 名を確認

https://dev.azure.com にアクセスして、URLを確認してください：

```
https://dev.azure.com/YOUR_ORG_NAME
                        ^^^^^^^^^^^^
                        これが Organization 名
```

### ステップ2: スクリプトを実行

```powershell
# Organization 名を指定して実行
.\scripts\create-work-items.ps1 -Organization "YOUR_ORG_NAME"

# または、プロジェクト名もカスタマイズ
.\scripts\create-work-items.ps1 -Organization "YOUR_ORG_NAME" -Project "my-project"
```

### ステップ3: 結果を確認

スクリプトが成功すると、以下のWork Itemsが作成されます：

```
Epic (1件)
 └─ Microservices Application Development

Features (4件)
 ├─ Backend API Development
 ├─ Frontend UI Development
 ├─ CI/CD Pipeline Setup
 └─ Monitoring and Alerts

User Stories (5件)
 ├─ AB#612: Create User API endpoint
 ├─ AB#613: Implement authentication
 ├─ AB#614: Create login page
 ├─ AB#615: Setup build pipeline
 └─ AB#616: Configure Application Insights
```

Azure DevOps で確認：
```
https://dev.azure.com/YOUR_ORG_NAME/az400-handson3-final/_workitems
```

## ❌ トラブルシューティング

### エラー: "The resource cannot be found. Operation returned a 404 status code."

**原因**:
- Organization 名が間違っている
- プロジェクトが存在しない
- Azure DevOps にログインしていない

**解決方法**:

1. **Organization 名を確認**
   ```powershell
   # 現在の設定を確認
   az devops configure --list
   
   # Organization 一覧を表示
   az devops project list
   ```

2. **プロジェクトが存在するか確認**
   ```powershell
   az devops project show --project "az400-handson3-final"
   ```

3. **プロジェクトを作成**
   
   手動作成:
   - https://dev.azure.com/YOUR_ORG_NAME にアクセス
   - **New project** をクリック
   - 名前: `az400-handson3-final`
   - Process: `Agile`
   - **Create**

### エラー: "ERROR: Please run 'az login' to setup account."

**解決方法**:
```powershell
az login
```

### エラー: "extension 'azure-devops' is not installed"

**解決方法**:
```powershell
az extension add --name azure-devops
```

### エラー: "Failed to create Epic"

**原因**: プロジェクトのプロセステンプレートが Agile ではない可能性

**解決方法**:
1. Azure DevOps → Project Settings → Overview を確認
2. Process が `Agile` になっているか確認
3. Scrum や CMMI の場合、Work Item Type が異なります：
   - Agile: Epic → Feature → User Story
   - Scrum: Epic → Feature → Product Backlog Item
   - CMMI: Epic → Feature → Requirement

## 📝 手動作成の方法

スクリプトが動作しない場合、手動で作成できます：

### CSVインポート

1. `work-items-import.csv` を開く
2. Azure DevOps → Boards → Work items
3. **...** (More actions) → **Import Work Items**
4. CSVファイルを選択
5. インポート後、親子関係を手動で設定

### Azure DevOps CLI（個別作成）

```powershell
# デフォルト設定
az devops configure --defaults `
  organization=https://dev.azure.com/YOUR_ORG `
  project=az400-handson3-final

# Epic を作成
az boards work-item create `
  --title "Microservices Application Development" `
  --type Epic `
  --description "フロントエンドとバックエンドのマイクロサービス開発"

# Feature を作成（Epic の ID を指定）
az boards work-item create `
  --title "Backend API Development" `
  --type Feature

# 親子関係を追加
az boards work-item relation add `
  --id <FEATURE_ID> `
  --relation-type parent `
  --target-id <EPIC_ID>
```

## 🔍 デバッグモード

詳細なログを表示する場合：

```powershell
$VerbosePreference = "Continue"
.\scripts\create-work-items.ps1 -Organization "YOUR_ORG_NAME" -Verbose
```

## 💡 ヒント

### Organization 名が分からない場合

1. https://dev.azure.com にアクセス
2. ログイン
3. URLバーを確認: `https://dev.azure.com/YOUR_ORG_NAME`

### プロジェクト一覧を確認

```powershell
az devops project list --output table
```

### Work Item を確認

```powershell
# すべての Work Items を表示
az boards work-item list --output table

# 特定の Work Item を表示
az boards work-item show --id 101
```

## 📚 関連ドキュメント

- [Azure DevOps CLI リファレンス](https://learn.microsoft.com/cli/azure/boards/work-item)
- [Azure Boards ドキュメント](https://learn.microsoft.com/azure/devops/boards/)
- [Work Items インポート](https://learn.microsoft.com/azure/devops/boards/queries/import-work-items-from-csv)
