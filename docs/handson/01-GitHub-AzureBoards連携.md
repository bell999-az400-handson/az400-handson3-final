# Lab 1: GitHub ↔ Azure Boards 連携

## 🎯 目的
このLabでは、GitHub と Azure Boards の連携方法を学び、特に AB# による Work Item リンクの動作仕様を理解します。

## ⏱️ 所要時間
約60分

## 📋 前提条件
- Lab 0 の環境準備が完了していること
- GitHub アカウント
- Azure DevOps Organization とプロジェクト

## 🎓 学習内容

### 重要ポイント（試験頻出）
✅ **AB# が認識される場所**
- ✔️ Pull Request の **title**
- ✔️ Pull Request の **description**
- ❌ Pull Request の **comment**（認識されない）
- ❌ Issue の **label**（認識されない）

この違いを実際に試して理解することが重要です！

## 📝 演習内容

### Exercise 1: GitHub リポジトリの作成

#### 1.1 GitHub Organization にリポジトリを作成

**方法1: Web ブラウザで作成**

1. [GitHub](https://github.com/) にログイン
2. 左上の組織メニューから「bell999-az400-handson」を選択
3. 「Repositories」タブをクリック
4. 「New repository」をクリック
5. 以下を入力：
   - Repository name: `az400-handson3`
   - Description: `AZ-400 Lab 1: Azure Boards Integration`
   - Visibility: Public または Private（どちらでも可）
   - ⚠️ **Initialize with README のチェックは外す**（既存のローカルリポジトリを使用するため）
6. 「Create repository」をクリック
7. リポジトリ URL をメモ（例: `https://github.com/bell999-az400-handson/az400-handson3.git`）

**方法2: GitHub CLI (gh) で作成（推奨）**

```powershell
# GitHub CLIでログイン（初回のみ）
gh auth login

# Organization配下にパブリックリポジトリを作成
gh repo create bell999-az400-handson/az400-handson3 `
  --description "AZ-400 Lab 1: Azure Boards Integration" `
  --public

# または、プライベートリポジトリとして作成する場合
gh repo create bell999-az400-handson/az400-handson3 `
  --description "AZ-400 Lab 1: Azure Boards Integration" `
  --private

# リポジトリが作成されたことを確認
gh repo view bell999-az400-handson/az400-handson3
```

**GitHub CLI のインストール（未インストールの場合）**
```powershell
# Windows (winget を使用)
winget install --id GitHub.cli

# または Chocolatey を使用
choco install gh

# インストール確認
gh --version
```

#### 1.2 ローカルリポジトリをリモートにプッシュ

```powershell
# 既存のローカルリポジトリに移動
Set-Location c:\Users\bell9\github\az400-handson3

# リモートリポジトリを追加
git remote add origin https://github.com/bell999-az400-handson/az400-handson3.git

# リモートリポジトリの確認
git remote -v

# 既存の変更をコミット（必要に応じて）
git add .
git commit -m "Initial commit for AZ-400 Lab 1"

# リモートリポジトリにプッシュ
git push -u origin main

# プッシュが成功したことを確認
# ブラウザで https://github.com/bell999-az400-handson/az400-handson3 にアクセス
```

#### 1.3 デフォルトブランチをmainに変更（重要）

GitHubのベストプラクティスとして、デフォルトブランチ名を `master` から `main` に変更します。

**ローカルとリモートのブランチをmainに統一:**

```powershell
# 現在のブランチ状態を確認
git branch -a

# ローカルのmasterブランチをmainにリネーム
git branch -m master main

# リモートにmainブランチをプッシュ
git push -u origin main

# GitHubのデフォルトブランチをmainに変更（GitHub CLI使用）
gh repo edit bell999-az400-handson/az400-handson3 --default-branch main

# リモートのmasterブランチを削除
git push origin --delete master

# リモートHEADポインタを更新
git remote set-head origin -a

# 変更を確認
git branch -a
# 出力: * main
#       remotes/origin/main
```

**💡 ポイント:**
- `git branch -m` でローカルブランチ名を変更
- `gh repo edit --default-branch` でGitHubのデフォルトブランチを変更
- 古いmasterブランチは削除して混乱を避ける
- すべてのコマンドはローカルとリモート両方を同期する

**⚠️ 注意:**
既にリモートリポジトリにmainブランチが存在する場合は、この手順は不要です。新規作成時や既存のmasterブランチからの移行時のみ実行してください。

### Exercise 2: Azure Boards の準備

#### 2.1 Work Item の作成

1. [Azure DevOps](https://dev.azure.com/) にアクセス
2. Organization → `az400-handson3` プロジェクトを開く
3. 左メニュー「Boards」→「Work items」をクリック
4. 「+ New Work Item」→「User Story」を選択
5. 以下を入力：
   - Title: `Implement login feature`
   - Description: `ユーザー認証機能を実装する`
   - State: New
6. 「Save & Close」をクリック
7. **Work Item ID をメモ**（例: #123）

#### 2.2 追加の Work Item を作成

同様に以下の Work Item を作成：
- User Story: `Add unit tests` (#124)
- Bug: `Fix login button alignment` (#125)

### Exercise 3: Azure Boards と GitHub の連携設定

#### 3.1 GitHub 接続の追加

**方法1: Web UI で接続（基本）**

1. Azure DevOps プロジェクトで「Project Settings」（左下の歯車アイコン）をクリック
2. 左メニュー「Boards」→「GitHub connections」を選択
3. 「Connect your GitHub account」をクリック
4. GitHub にリダイレクトされたら「Authorize」をクリック
5. 接続が成功したことを確認

**方法2: Azure DevOps CLI で接続（推奨）**

```powershell
# 前提: GitHub Personal Access Token (PAT) の作成
# 1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# 2. "Generate new token (classic)" をクリック
# 3. Scopes を選択:
#    - repo (Full control of private repositories)
#    - admin:repo_hook (Full control of repository hooks)
# 4. トークンをコピーして安全に保存

# 環境変数にトークンを設定（セッション内で一時的に保存）
$env:GITHUB_PAT = "ghp_YourPersonalAccessTokenHere"

# Azure DevOps にログイン
az login
az devops configure --defaults organization=https://dev.azure.com/bell999 project=az400-handson3

# GitHub Service Endpoint を作成
az devops service-endpoint github create `
  --name "GitHub-Connection" `
  --github-url "https://github.com/bell999-az400-handson/az400-handson3" `
  --github-token $env:GITHUB_PAT `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3

# 作成された Service Endpoint を確認
az devops service-endpoint list `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3 `
  --output table

# Azure Boards 用の GitHub 接続を有効化
# 注意: Azure Boards と GitHub の連携は Web UI での初回承認が必要な場合があります
```

**💡 ポイント:**
- GitHub PAT には `repo` と `admin:repo_hook` スコープが必要
- PAT は安全に保管し、環境変数や Azure Key Vault に保存
- Service Endpoint は CI/CD パイプラインでも使用可能
- Azure Boards の GitHub 連携は、初回のみ Web UI での OAuth 承認が必要な場合があります

**⚠️ セキュリティベストプラクティス:**

**オプション1: セッション後に環境変数をクリア**
```powershell
# PAT をセッション後にクリア
Remove-Item Env:\GITHUB_PAT
```

**オプション2: Azure Key Vault に保存（推奨）**

Azure Key Vault を使用すると、PAT を安全に保管・管理できます。

**Step 1: リソースグループと Key Vault を作成**
```powershell
# 1. リソースグループを作成（存在しない場合）
az group create `
  --name "rg-az400-handson3" `
  --location "japaneast"

# 2. 一意な Key Vault 名を生成
# Key Vault 名はグローバルに一意である必要があるため、ユーザー名を含める
$kvName = "kv-az400-$($env:USERNAME)"
Write-Host "Key Vault name: $kvName"

# 3. Key Vault を作成
az keyvault create `
  --name $kvName `
  --resource-group "rg-az400-handson3" `
  --location "japaneast" `
  --enable-rbac-authorization true

# 4. 自分に Key Vault Secrets Officer 権限を付与
$userId = az ad signed-in-user show --query id -o tsv
$subscriptionId = az account show --query id -o tsv

az role assignment create `
  --role "Key Vault Secrets Officer" `
  --assignee $userId `
  --scope "/subscriptions/$subscriptionId/resourceGroups/rg-az400-handson3/providers/Microsoft.KeyVault/vaults/$kvName"

# 権限の伝播を待つ（30秒程度）
Write-Host "Waiting for RBAC propagation..."
Start-Sleep -Seconds 30
```

**Step 2: GitHub PAT を Key Vault に保存**
```powershell
# GitHub PAT を Key Vault に保存
az keyvault secret set `
  --vault-name $kvName `
  --name "github-pat" `
  --value $env:GITHUB_PAT

Write-Host "✅ GitHub PAT saved to Key Vault: $kvName"
```

**Step 3: Key Vault から PAT を取得して使用**
```powershell
# Key Vault から PAT を取得
$env:GITHUB_PAT = az keyvault secret show `
  --vault-name $kvName `
  --name "github-pat" `
  --query value -o tsv

# Service Endpoint を作成（Key Vault から取得した PAT を使用）
az devops service-endpoint github create `
  --name "GitHub-Connection" `
  --github-url "https://github.com/bell999-az400-handson/az400-handson3" `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3

# セッション終了時にクリア（オプション）
Remove-Item Env:\GITHUB_PAT
```

**💡 Key Vault を使うメリット:**
- 🔒 PAT を平文ファイル（.env）に保存する必要がない
- 🔒 Azure RBAC でアクセス制御が可能
- 🔒 監査ログで誰がいつアクセスしたか記録される
- 🔒 自動ローテーション（有効期限管理）が可能
- 🔒 チームメンバーと安全に共有できる

**📝 Key Vault 名の確認**
```powershell
# 作成した Key Vault 名を確認
az keyvault list `
  --resource-group "rg-az400-handson3" `
  --query "[].name" -o tsv

# シークレット一覧を確認
az keyvault secret list `
  --vault-name $kvName `
  --query "[].name" -o tsv
```

#### 3.2 リポジトリの追加

**方法1: Web UI で追加**

1. 「+ Add GitHub repositories」をクリック
2. `az400-handson3` リポジトリを選択
3. 「Save」をクリック

**方法2: Azure DevOps REST API で追加（コマンドライン）**

```powershell
# 前提: Service Endpoint ID を取得
$serviceEndpointId = az devops service-endpoint list `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3 `
  --query "[?name=='GitHub-Connection'].id" -o tsv

# GitHub リポジトリを Azure Boards に接続
# 注意: Azure Boards 専用の GitHub 接続は REST API での自動化が制限されています
# Web UI での初回承認後、以下のコマンドで確認可能

# GitHub 接続済みリポジトリを確認
az repos list `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3 `
  --output table
```

**💡 Azure Boards と GitHub の統合に関する重要な注意:**

Azure Boards の GitHub 接続は、**Service Endpoint** とは異なる専用の接続方式を使用します：

1. **Service Endpoint** (上記 3.1 で作成):
   - Azure Pipelines で GitHub リポジトリにアクセスするために使用
   - `az devops service-endpoint` コマンドで管理可能
   - CI/CD パイプラインで参照

2. **Azure Boards GitHub Connection**:
   - Work Item と Pull Request をリンクするために使用
   - **初回は Web UI での OAuth 承認が必須**
   - Project Settings → Boards → GitHub connections で管理

**推奨アプローチ:**
- **初回セットアップ**: Web UI で OAuth 承認を完了（3.1 の方法1）
- **以降の管理**: CLI や REST API でリポジトリを追加・削除

#### 確認方法
```powershell
# Azure DevOps CLI で Service Endpoint を確認
az devops service-endpoint list `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3 `
  --output table

# GitHub CLI でリポジトリの接続状態を確認
gh repo view bell999-az400-handson/az400-handson3 --json url,name

# Azure Boards の Work Item から GitHub リンクをテスト（後のExerciseで実施）
```

### Exercise 4: AB# の動作確認（title での認識）

#### 4.1 新しいブランチを作成

```powershell
Set-Location c:\Users\bell9\github\az400-handson3

# feature ブランチを作成
git checkout -b feature/login-implementation

# コードを変更
"function login() { return true; }" | Add-Content src/app.js
git add app.js
git commit -m "Implement basic login function"
git push origin feature/login-implementation
```

#### 4.2 Pull Request を作成（title に AB# を含める）

1. GitHub リポジトリのページにアクセス
2. 「Compare & pull request」ボタンをクリック
3. **重要: Title に AB# を含める**
   ```
   Title: AB#574: Implement login feature
   Description: 
   This PR implements the basic login functionality.
   
   Changes:
   - Add login function
   - Update app.js
   ```
4. 「Create pull request」をクリック

#### 4.3 Azure Boards で確認

1. Azure DevOps → Boards → Work items
2. Work Item #574 を開く
3. 「Development」セクションを確認
4. ✅ **Pull Request へのリンクが表示されることを確認**

### Exercise 5: AB# の動作確認（description での認識）

#### 5.1 新しい Pull Request を作成

```powershell
# 別のブランチを作成
git checkout main
git checkout -b feature/add-tests

# ファイルを追加
"// Test placeholder" | Out-File src/app.test.js -Encoding utf8
git add src/app.test.js
git commit -m "Add test file"
git push origin feature/add-tests
```

#### 5.2 Pull Request を作成（description に AB# を含める）

1. GitHub で「Compare & pull request」をクリック
2. **重要: Description に AB# を含める**
   ```
   Title: Add unit tests
   Description:
   This PR adds unit tests for the login feature.
   Related Work Item: AB#575
   ```
3. 「Create pull request」をクリック

#### 5.3 確認

1. Azure Boards で Work Item #575 を開く
2. ✅ **Pull Request へのリンクが表示されることを確認**

### Exercise 6: AB# が認識されない場所の確認

#### 6.1 Comment に AB# を追加（認識されない例）

1. 既存の Pull Request を開く
2. Comment に以下を追加：
   ```
   AB#125 にも関連する変更です。
   ```
3. Comment を投稿

#### 6.2 確認

1. Azure Boards で Work Item #125 を開く
2. ❌ **Comment からのリンクは作成されないことを確認**

#### 結論
- ✅ Title に AB# → リンクされる
- ✅ Description に AB# → リンクされる
- ❌ Comment に AB# → リンクされない

### Exercise 7: GitHub Notifications 設定

#### 7.1 通知設定の確認

**方法1: Web UI でアクセス**

1. GitHub画面右上の**プロフィールアイコン**（自分のアバター）をクリック
2. ドロップダウンメニューから「**Settings**」を選択
3. 左サイドバーから「**Notifications**」を選択
4. 通知設定ページが表示されます

**方法2: 直接URLでアクセス**

ブラウザで以下のURLにアクセス：
```
https://github.com/settings/notifications
```

**💡 ポイント:**
- **リポジトリ設定**（Repository Settings）ではなく、**個人アカウント設定**（User Settings）から行います
- プロフィールアイコンは画面右上にあります
- 直接URLでアクセスするのが最も早い方法です

**📋 GitHub通知設定ページの構成（2026年5月時点）**

通知設定ページには主に以下のセクションがあります：
1. **Default notification email**: 通知を受け取るメールアドレス
2. **Subscriptions**: 通知の管理
   - **Watching**: Watch中のリポジトリからの通知設定
   - **Participating, @mentions and custom**: 自分が参加・メンションされた際の通知
3. **Customize email updates**: メール通知の詳細設定
4. **Ignored repositories**: 無視するリポジトリの管理
5. **System**: システム通知（Actions、Dependabotなど）

#### 7.2 最適な設定（試験重要ポイント）

**❗ 重要な変更（2025年5月23日以降）**

GitHub は **2025年5月23日** に以下の機能を**正式に廃止**しました：
- ❌ **Automatically watch repositories**（リポジトリの自動ウォッチ）
- ❌ **Automatically watch teams**（チームの自動ウォッチ）

**廃止の理由（GitHub公式）:**
- 通知ノイズを減らすため
- 大規模Organization参加時に大量の不要なウォッチが発生する問題を解消
- ユーザーが「自分で選んでウォッチする」モデルへ移行

参考: [GitHub Blog - Sunset notice for automatic watching](https://github.blog/changelog/2025-04-14-sunset-notice-for-automatic-watching-of-repositories-and-teams/)

**⚠️ 重要:**
- 廃止前に自動ウォッチされていたリポジトリはそのまま維持されます
- しかし、**新規に自動ウォッチされることはもうありません**
- 今後はリポジトリを**手動でウォッチ**する必要があります

#### 現在の推奨設定（2026年5月時点）

**自動ウォッチ機能が廃止されたため、以下の方法で通知を管理します：**

**1. 既にウォッチしているリポジトリを確認・解除**

```
手順:
1. https://github.com/watching にアクセス
2. Watch中のリポジトリ一覧が表示されます
3. 不要なリポジトリの「Unwatch」ボタンをクリック
4. または「Custom」を選択して通知レベルを調整
```

**通知レベルの種類:**
- **All Activity**: すべてのアクティビティを通知（通知が多い）
- **Ignore**: 通知を受け取らない
- **Participating and @mentions**: 自分が参加・メンションされた場合のみ通知（推奨）
- **Custom**: Issue、PR、Releaseなどを個別に設定

**2. 通知方法を調整**

https://github.com/settings/notifications で以下を確認：

```
Subscriptions セクション:
- Watching: 「Notify me on GitHub, Email」（推奨: GitHub のみ）
- Participating: 「Notify me on GitHub, Email」（推奨: 両方 ON）
```

**💡 実務での推奨アプローチ:**
- 重要なリポジトリのみ手動でWatch
- CODEOWNERS + Branch Protection Rulesでレビュー依頼を自動化
- GitHub → Teams/Slack 連携で通知を集約

**📌 AZ-400 試験対策のポイント:**
- 2025年5月以前の試験問題では「Automatically watch」の設定が出題される可能性がありますが、**現在は廃止済み**です
- 試験では「廃止された」という選択肢があるかもしれません
- 実務では**手動ウォッチ管理**が標準になっています

### Exercise 8: Azure Repos への通知設定

#### 8.1 Service Hooks の設定

1. Azure DevOps → Project Settings → Service hooks
2. 「+ Create subscription」をクリック
3. サービスを選択: 
   - **Web Hooks** (推奨: 汎用的なHTTP通知)
   - **Slack** (Slack統合)
   - ~~**Teams**~~ (非推奨: Teams側から設定する方式に変更)
   - その他: Azure Service Bus, Azure Storage, Jenkins など

**💡 ポイント:**
- Microsoft Teams 統合は **Teams側のアプリ管理から設定** (8.2参照)
- Web Hooks を使えば任意のエンドポイント（Teams Incoming Webhookを含む）に通知可能

#### 8.2 Teams 通知の設定（オプション）

**⚠️ 重要な変更（2026年時点）**

Azure DevOps の Service Hooks で **Microsoft Teams** を選択すると、以下のメッセージが表示されます：

```
Subscriptions for this service are managed by the consumer service. 
To create a new subscription visit Microsoft Teams.
```

**現在の推奨方法: Teams側からAzure DevOps Appを追加**

1. **Microsoft Teams** を開く
2. 通知を受け取りたいチャネルを選択
3. チャネル名の横の「…」→ **「コネクタ」** または **「アプリを管理」** をクリック
4. **「Azure DevOps」** アプリを検索して追加
5. **「構成」** をクリック
6. 以下を設定：
   - Organization: `https://dev.azure.com/bell999`
   - Project: `az400-handson3`
   - Event type: **Pull request created**, **Pull request merged** など
   - Repository: 対象リポジトリを選択
7. **「保存」** をクリック

**💡 ポイント:**
- 2026年現在、Azure DevOps → Teams の通知設定は **Teams側から行う方式に変更**
- Azure DevOps の Service Hooks では Web Hooks または他のサービスを使用
- Teams統合はより強力な機能（Work Item更新、ビルド結果など）を提供

**代替方法: Incoming Webhook（従来の方法）**

Teams で Incoming Webhook を使いたい場合：

1. Teams チャネルで「…」→「コネクタ」→「Incoming Webhook」を追加
2. Webhook URL をコピー
3. Azure DevOps → Service Hooks → **Web Hooks** を選択（Teams ではない）
4. Trigger: **Pull request created** を選択
5. URL に Teams の Webhook URL を貼り付け
6. 「Finish」をクリック

#### 8.3 Slack 通知の設定（Teams の代替）

**💡 Teams が個人版でアプリを追加できない場合は Slack を使用**

Slack と Azure DevOps の統合には2つの方法があります。

**前提: Slack Workspace の作成（初回のみ）**

**⚠️ 重要（2026年版）**: Slack の新UIでは**アプリ内から新規ワークスペースを作成できません**。Web から作成する必要があります。

1. **Slack 新規ワークスペース作成ページを開く**
   - ブラウザで以下のURLにアクセス:
   ```
   https://slack.com/get-started#/createnew
   ```

2. **メールアドレスを入力**
   - Slack から確認コードが送信されます

3. **確認コードを入力**
   - メールに届いた6桁のコードを入力

4. **ワークスペース名を入力**
   - 例: `az400-handson`、`devops-lab`、`project-2026` など
   - 後から変更可能

5. **プロジェクト名を入力（任意）**
   - スキップも可能

6. **メンバー招待（スキップ可）**
   - 後から招待できるのでスキップしてOK

7. **ワークスペース完成**
   - ブラウザで Slack Workspace が開きます
   - Slack デスクトップアプリを再起動すると、左側に新しいワークスペースが自動的に追加されます

**💡 ポイント:**
- **2024〜2026年の UI 刷新により、アプリ内の「別のワークスペースを追加」ボタンは削除されました**
- ワークスペース作成は必ず Web から行う必要があります
- 作成後は Slack アプリに自動的に同期されます

**方法1: Slack Workspace から Azure DevOps アプリを追加**

**⚠️ 注意（2026年5月時点）**: Slack App Directory で「Azure DevOps」アプリが見つからない場合があります。以下の順で試してください：

1. **Slack Workspace** を開く
2. 左サイドバーで **「アプリ」** をクリック
3. **「アプリを検索」** で以下の名称を順に検索：
   - **「Azure DevOps」**
   - **「Azure Pipelines」** (Azure DevOpsの機能の一部として提供されている場合)
   - **「Azure Boards」**
   - **「Microsoft Azure DevOps」**

**アプリが見つかった場合：**
4. アプリを選択して **「追加」** をクリック
5. **「Azure DevOps に接続」** をクリック

**⚠️ サインイン時の注意（個人アカウントエラーの対処法）**

サインイン時に「ここに個人アカウントでサインインすることはできません。代わりに職場または学校アカウントをご利用ください。」と表示される場合：

**原因:**
- Azure DevOps Organization の設定で個人の Microsoft アカウント（@outlook.com、@gmail.com など）での OAuth アクセスが無効化されている

**解決方法（いずれか1つを選択）:**

**方法A: Azure DevOps で個人アカウントのアクセスを許可（推奨）**

1. Azure DevOps で **Organization Settings**（左下の歯車アイコン）を開く
2. 左メニューの **「Policies」** をクリック
3. **「Third-party application access via OAuth」** を **ON** に設定
4. **「Save」** をクリック
5. **ブラウザのキャッシュをクリア**（重要）
   - Ctrl + Shift + Delete でブラウザの履歴を削除
   - または、シークレット/プライベートウィンドウで再度試す
6. Slack の設定画面に戻り、再度サインインを試す

**⚠️ それでも失敗する場合:**
- Organization の **Azure AD テナント設定** で外部アプリケーションのアクセスが制限されている可能性があります
- この場合は **方法C（Service Hooks）** を使用してください（最も確実です）

**方法B: 職場/学校アカウントを使用**

- Microsoft Entra ID（旧 Azure AD）のアカウントでサインイン
- 例: `user@contoso.onmicrosoft.com` または会社のドメイン `user@company.com`

**方法C: Service Hooks を使用（最も確実）**

- この方法1をスキップして、下記の **方法2（Service Hooks）** を使用
- OAuth 認証が不要なため、アカウント種別に関係なく動作します

---

6. Azure DevOps へのサインインを求められるのでサインイン
   - 上記のエラーが表示された場合は、**方法A〜C** のいずれかで対処してください
7. Organization と Project を承認
8. Slack で通知を受け取りたいチャネルを選択
9. 以下のコマンドで購読を設定：
   ```
   /azdevops subscribe https://dev.azure.com/bell999/az400-handson3
   ```
10. 通知したいイベントを選択：
    - Pull requests created
    - Pull requests merged
    - Work items created
    - Builds completed
    など

**❌ アプリが見つからない場合、またはサインインに失敗する場合：**
- **方法2（Service Hooks）** に進んでください（こちらの方が確実です）
- OAuth認証が不要なため、アカウント種別やテナント設定に関係なく動作します

---

**方法2: Service Hooks で Slack を設定（確実な方法・推奨）**

**✅ この方法は以下のすべてのケースで動作します:**
- Azure DevOps アプリが見つからない
- OAuth サインインでエラーが出る
- 個人アカウントでのアクセスが制限されている
- Organization 管理者権限がない

**手順:**

1. **Slack Workspace で Incoming Webhook を設定：**
   
   a. Slack Workspace を開く
   
   b. 左下の **「設定と管理」** → **「アプリを管理」** をクリック
      - または、直接 `https://[your-workspace].slack.com/apps` にアクセス
   
   c. 検索ボックスで **「Incoming Webhooks」** を検索
   
   d. **「Incoming Webhooks」** を選択して **「Slack に追加」** をクリック
   
   e. 通知を受け取りたいチャネルを選択（例: `#azure-devops`）
      - チャネルが存在しない場合は事前に作成してください
   
   f. **「Incoming Webhook インテグレーションの追加」** をクリック
   
   g. **Webhook URL** が表示されるのでコピー
      ```
      例: https://hooks.slack.com/services/T0B3FATDT34/B07XXXXXXXX/XXXXXXXXXXXXXXXXXXXX
      ```
   
   h. （オプション）カスタマイズ:
      - 名前を変更（例: `Azure DevOps Notifier`）
      - アイコンを変更（Azure DevOps のロゴなど）
      - 「設定を保存する」をクリック

2. **Azure DevOps で Service Hook を作成：**
   
   a. Azure DevOps で対象プロジェクトを開く
      ```
      https://dev.azure.com/bell999/az400-handson3
      ```
   
   b. 左下の **「Project Settings」** をクリック
   
   c. 左メニューの **「Service hooks」** をクリック
   
   d. **「+ Create subscription」** をクリック
   
   e. Service: **「Slack」** を選択 → **「Next」**
   
   f. Trigger を選択（例: **「Pull request created」**）
      - 他のオプション:
        - Pull request updated
        - Pull request merge attempted
        - Work item created
        - Work item updated
        - Build completed
        - Release deployment started
        など
      
      - Repository を指定する場合は選択
      
      - **「Next」** をクリック
   
   g. Action の設定:
      - **Slack Webhook URL**: コピーした Webhook URL を貼り付け
      - **Message format**: **「Detailed」** を選択（推奨）
        - Compact: 簡潔な通知
        - Detailed: 詳細な通知（PR の説明、変更内容など含む）
      
      - **「Test」** ボタンをクリックして Slack にテスト通知が届くか確認
      
      - **「Finish」** をクリック

3. **複数のイベントを購読する場合：**
   
   同じ手順を繰り返して、異なる Trigger で複数の Service Hook を作成できます：
   - Pull request created
   - Pull request merged
   - Work item created
   - Work item state changed
   - Build completed
   など

**💡 ポイント:**
- **2026年5月時点**: Slack App Directory で「Azure DevOps」アプリが見つからない場合があります
- **方法2（Service Hooks + Incoming Webhooks）** の方が確実で、すべてのケースで動作します
- **方法1**（Azure DevOps アプリ）は機能が豊富で双方向のコミュニケーションが可能ですが、アプリの提供状況に依存します
- **方法2**（Incoming Webhook）はシンプルで確実ですが、通知のみ（Azure DevOps への操作はできない）
- Slack は無料プランでも Incoming Webhooks を利用可能
- **AZ-400 試験対策としては方法2を理解していれば十分**

**動作確認:**

1. GitHub で新しい Pull Request を作成
2. Slack チャネルに通知が届くことを確認
3. 通知に PR のタイトル、作成者、リンクが含まれていることを確認

**❗ トラブルシューティング（Slack 通知が届かない場合）:**

1. **Webhook URL が正しいか確認：**
   - Slack の Incoming Webhooks 設定画面で URL を再確認
   - Azure DevOps の Service Hook 設定で URL が正しく貼り付けられているか確認

2. **Service Hook のテスト：**
   - Azure DevOps → Project Settings → Service hooks
   - 作成した Slack への Service Hook を選択
   - 「Test」ボタンをクリック
   - Slack にテスト通知が届くか確認
   - エラーが表示される場合はメッセージを確認

3. **Trigger の条件を確認：**
   - Repository が指定されている場合、対象のリポジトリで操作しているか確認
   - Branch filter が設定されている場合、対象のブランチか確認

4. **Slack チャネルのアクセス権限：**
   - Incoming Webhook が追加されたチャネルにアクセスできるか確認
   - プライベートチャネルの場合、自分が招待されているか確認

5. **Service Hook の履歴を確認：**
   - Azure DevOps → Project Settings → Service hooks
   - 作成した Subscription を選択
   - 「History」タブで実行履歴とエラーログを確認
   - Status が「Failed」の場合、詳細をクリックしてエラー内容を確認

### Exercise 9: Pull Request のマージと確認

#### 9.1 Pull Request をマージ

1. GitHub で Pull Request を開く
2. 「Merge pull request」をクリック
3. 「Confirm merge」をクリック

#### 9.2 Azure Boards で Work Item を更新

1. Azure Boards で Work Item #123 を開く
2. State を「Active」→「Resolved」に変更
3. 「Save」をクリック

#### 9.3 リンクの確認

- Development セクションに Merged PR が表示されることを確認
- Commit へのリンクも表示されることを確認

## 📊 演習のまとめ

### AB# の動作仕様（重要！）

| 場所 | AB# 認識 | 例 |
|------|----------|-----|
| PR Title | ✅ 認識される | `AB#123: Implement feature` |
| PR Description | ✅ 認識される | `Related: AB#123` |
| PR Comment | ❌ 認識されない | Comment に AB# を書いても無効 |
| Issue Label | ❌ 認識されない | Label には使用できない |
| Commit Message | ✅ 認識される | `git commit -m "Fix AB#123"` |

### GitHub 通知設定の推奨（試験重要！）

**❗ 2025年5月23日の変更点:**

| 項目 | 状態 | 説明 |
|------|------|------|
| **Automatically watch repositories** | ❌ **廃止** | GitHub公式が2025年5月23日に機能を廃止 |
| **Automatically watch teams** | ❌ **廃止** | 同上 |

**現在の推奨設定（2026年5月時点）:**

| 設定項目 | 推奨値 | 設定場所 | 説明 |
|----------|--------|----------|------|
| **Watch管理** | 手動で選択 | https://github.com/watching | 必要なリポジトリのみWatch |
| **Watching通知** | GitHub only | settings/notifications | メール通知を減らす |
| **Participating通知** | GitHub + Email | settings/notifications | 重要な通知は両方で受け取る |

**💡 実務での通知管理:**
- **自動ウォッチは廃止**されたため、リポジトリごとに手動で設定
- **Participating**（自分が参加・メンション）は自動で有効
- https://github.com/watching で一括管理が便利

### Azure DevOps と GitHub の接続方式

| 接続方式 | 用途 | 作成方法 | 認証 |
|----------|------|----------|------|
| **Service Endpoint** | CI/CD パイプライン | `az devops service-endpoint` | GitHub PAT |
| **Azure Boards GitHub Connection** | Work Item 連携（AB#） | Web UI（初回OAuth必須） | OAuth + PAT |

### Azure DevOps と Teams の統合方式（2026年時点）

| 統合方法 | 設定場所 | 推奨度 | 説明 |
|----------|----------|--------|------|
| **Teams アプリ** | Teams側（推奨） | ⭐⭐⭐ | Teams → アプリ管理 → Azure DevOps を追加 |
| **Incoming Webhook** | Azure DevOps Service Hooks | ⭐⭐ | Web Hooks経由でTeamsに通知 |
| ~~**Service Hooks - Teams**~~ | ~~Azure DevOps~~ | ❌ 非推奨 | 「Teams側から設定してください」と表示される |

**💡 ポイント:**
- **2026年現在、Teams統合はTeams側から設定する方式に変更**
- Azure DevOps の Service Hooks で "Microsoft Teams" を選択すると、Teams側での設定を促すメッセージが表示される
- Teams アプリ方式の方が機能が豊富（Work Item、ビルド、PR、リリースなど）

### Azure DevOps と Slack の統合方式

| 統合方法 | 設定場所 | 推奨度 | 説明 |
|----------|----------|--------|------|
| **Slack アプリ** | Slack Workspace（推奨） | ⭐⭐⭐ | Slack → アプリ → Azure DevOps を追加 |
| **Service Hooks - Slack** | Azure DevOps | ⭐⭐ | Service Hooks → Slack → Incoming Webhook URL |
| **Web Hooks** | Azure DevOps | ⭐ | 汎用的だが設定が煩雑 |

**💡 ポイント:**
- **Slack は無料プランでも Azure DevOps アプリが使える**（Teams個人版との違い）
- Slack アプリ方式なら `/azdevops` コマンドで双方向連携が可能
- Service Hooks 方式は通知のみだが設定がシンプル

### コマンドラインでの主要操作

```powershell
# GitHub PAT の作成（GitHub Web UI で実施）
# Scopes: repo, admin:repo_hook

# Service Endpoint の作成
az devops service-endpoint github create `
  --name "GitHub-Connection" `
  --github-url "https://github.com/ORG/REPO" `
  --github-token $env:GITHUB_PAT

# Service Endpoint の確認
az devops service-endpoint list --output table

# Azure Boards と GitHub の接続確認（Web UI）
# Project Settings → Boards → GitHub connections
```

## ✅ 確認問題

### Q1: AB# が認識される場所を2つ選んでください
- [ ] A. Pull Request の comment
- [ ] B. Pull Request の title
- [ ] C. Issue の label
- [ ] D. Pull Request の description

<details>
<summary>解答</summary>

**正解: B と D**

説明:
- AB# が認識されるのは Pull Request の **title** と **description** のみ
- Comment や Label では Work Item にリンクされない
</details>

### Q2: GitHub 通知設定に関する正しい説明を選んでください（2026年5月時点）
- [ ] A. Automatically watch repositories 設定を OFF にすることで通知を減らせる
- [ ] B. 通知を減らすには https://github.com/watching で不要なリポジトリをUnwatchする
- [ ] C. Automatically watch teams は Organization メンバーのみ設定可能
- [ ] D. すべての通知を停止するには Email notifications を OFF にする

<details>
<summary>解答</summary>

**正解: B のみ**

説明:
- **A. 誤り**: Automatically watch repositories は **2025年5月23日に GitHub が廃止**しました。現在この設定は存在しません
- **B. 正しい**: https://github.com/watching で Watch 中のリポジトリを確認・解除することで通知を減らせます（現在の推奨方法）
- **C. 誤り**: Automatically watch teams も **廃止されました**。Organization メンバーでも設定できません
- **D. 誤り**: Email notifications を完全に OFF にすると、重要な通知（Participating, @mentions）も受け取れなくなります

**💡 試験対策ポイント:**
- **2025年5月23日以降、自動ウォッチ機能は完全に廃止**
- 現在は **手動でリポジトリをウォッチ/アンウォッチ** する方式
- 古い試験問題では廃止前の設定が出題される可能性があります
- 実務では https://github.com/watching での一括管理が標準

**参考:**
[GitHub Blog - Sunset notice for automatic watching](https://github.blog/changelog/2025-04-14-sunset-notice-for-automatic-watching-of-repositories-and-teams/)
</details>

### Q3: Azure Boards と GitHub を連携するために必要な手順を正しい順序で並べてください
- [ ] A. Pull Request を作成
- [ ] B. GitHub 接続を追加
- [ ] C. Work Item を作成
- [ ] D. リポジトリを選択

<details>
<summary>解答</summary>

**正解: C → B → D → A**

説明:
1. Work Item を作成（AB# に使用するIDを取得）
2. GitHub 接続を追加（Azure DevOps と GitHub を認証）
3. リポジトリを選択（連携対象を指定）
4. Pull Request を作成（AB# でリンク）
</details>

### Q4: Azure DevOps CLI で GitHub Service Endpoint を作成する際に必要な GitHub PAT のスコープを2つ選んでください
- [ ] A. repo
- [ ] B. user
- [ ] C. admin:repo_hook
- [ ] D. workflow

<details>
<summary>解答</summary>

**正解: A と C**

説明:
- **repo**: リポジトリへのフルアクセス（プライベートリポジトリ含む）
- **admin:repo_hook**: リポジトリフックの管理（Azure Boards との連携に必要）
- user や workflow は Azure Boards 連携には不要
</details>

### Q5: Azure Boards の GitHub 連携で正しい説明を選んでください
- [ ] A. Service Endpoint と Azure Boards GitHub Connection は同じもの
- [ ] B. Azure Boards GitHub Connection の初回承認は Web UI が必須
- [ ] C. すべての操作を Azure DevOps CLI で自動化できる
- [ ] D. GitHub PAT は不要で OAuth のみで接続できる

<details>
<summary>解答</summary>

**正解: B**

説明:
- A: **誤り** - Service Endpoint（CI/CD用）と Azure Boards GitHub Connection（Work Item連携用）は異なる
- B: **正しい** - Azure Boards の GitHub 接続は初回 OAuth 承認が Web UI で必須
- C: **誤り** - Azure Boards GitHub Connection の初回承認は Web UI が必要
- D: **誤り** - Service Endpoint 作成には GitHub PAT が必要（OAuth は Web UI での承認用）
</details>

### Q6: Azure DevOps と Microsoft Teams を統合する際の正しい方法を選んでください（2026年時点）
- [ ] A. Azure DevOps の Service Hooks で Microsoft Teams を選択して設定
- [ ] B. Teams 側から Azure DevOps アプリを追加して設定
- [ ] C. Azure DevOps CLI で Teams 統合を設定
- [ ] D. GitHub から直接 Teams に通知を送る

<details>
<summary>解答</summary>

**正解: B**

説明:
- **A. 誤り**: Azure DevOps の Service Hooks で Microsoft Teams を選択すると、「Subscriptions for this service are managed by the consumer service. To create a new subscription visit Microsoft Teams.」というメッセージが表示され、設定できません
- **B. 正しい**: 2026年現在、**Teams側から Azure DevOps アプリを追加**する方式が推奨されています
  - Teams のチャネル → アプリを管理 → Azure DevOps を検索・追加
  - より強力な機能（Work Item更新、ビルド結果、PR通知など）を提供
- **C. 誤り**: Azure DevOps CLI では Teams 統合の設定はできません
- **D. 誤り**: GitHub と Teams の直接統合は別の設定であり、Azure DevOps を経由しません

**💡 代替方法:**
Azure DevOps の Service Hooks で **Web Hooks** を選択し、Teams の **Incoming Webhook URL** を指定する方法もありますが、Azure DevOps アプリの方が機能が豊富です。

</details>

### Q7: Azure DevOps と Slack を統合する際の利点として正しいものを選んでください
- [ ] A. Slack 無料プランでは Azure DevOps アプリを追加できない
- [ ] B. Slack アプリ方式なら双方向連携（通知 + コマンド実行）が可能
- [ ] C. Service Hooks で Slack を選択すると Teams と同じエラーメッセージが表示される
- [ ] D. Slack への通知には必ず Azure DevOps CLI が必要

<details>
<summary>解答</summary>

**正解: B**

説明:
- **A. 誤り**: Slack は**無料プランでも Azure DevOps アプリを追加可能**です（Teams個人版との大きな違い）
- **B. 正しい**: Slack Workspace に Azure DevOps アプリを追加すると、`/azdevops subscribe` などのコマンドで双方向連携ができます
  - 通知を受け取るだけでなく、Slackから Azure DevOps の操作も可能
  - Work Item作成、ビルド確認、承認などが Slack 上で完結
- **C. 誤り**: Service Hooks の Slack オプションは正常に動作します（Teams のようなエラーは出ない）
- **D. 誤り**: Slack Workspace のアプリ管理画面から Azure DevOps アプリを追加できます（CLI不要）

**💡 実務での推奨:**
- **Teams が使えない場合（個人版など）は Slack が最適な代替手段**
- Slack アプリ方式（推奨）> Service Hooks の Slack > Incoming Webhook
- 無料で双方向連携できるのが Slack の強み

</details>

## 🔍 トラブルシューティング

### AB# が認識されない
- Title または Description に AB# が含まれているか確認
- Azure Boards と GitHub の接続が有効か確認
- Work Item ID が正しいか確認

### GitHub 接続エラー
```powershell
# Azure DevOps CLI で接続を確認
az devops project show --org https://dev.azure.com/bell999 --project az400-handson3

# Service Endpoint の状態を確認
az devops service-endpoint list `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3 `
  --output table

# GitHub PAT の有効性を確認
gh auth status

# GitHub 接続を再認証（Web UI）
# Project Settings → GitHub connections → Re-authorize
```

### Service Endpoint のトラブルシューティング
```powershell
# Service Endpoint の詳細を確認
$endpointId = az devops service-endpoint list `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3 `
  --query "[0].id" -o tsv

az devops service-endpoint show `
  --id $endpointId `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3

# Service Endpoint の削除（再作成が必要な場合）
az devops service-endpoint delete `
  --id $endpointId `
  --org https://dev.azure.com/bell999 `
  --project az400-handson3 `
  --yes

# GitHub PAT の権限を確認（GitHub CLI）
gh auth status
gh api user -q .login

# 必要なスコープの確認
# repo, admin:repo_hook が含まれているか確認
```

### Microsoft Teams 統合のトラブルシューティング

**問題: Azure DevOps の Service Hooks で Microsoft Teams を選択すると「Subscriptions for this service are managed by the consumer service」と表示される**

<details>
<summary>解決方法</summary>

**✅ これは正常な動作です**

2026年現在、Microsoft Teams との統合は **Teams側から設定する方式** に変更されました。

**推奨される対処法:**

1. **Teams アプリを使用する方法（推奨）**
   - Microsoft Teams を開く
   - 通知を受け取りたいチャネルを選択
   - チャネル名の「…」→「アプリを管理」をクリック
   - 「Azure DevOps」を検索して追加
   - 構成で Organization とプロジェクトを指定

2. **Incoming Webhook を使用する方法（代替）**
   - Teams チャネルで「…」→「コネクタ」→「Incoming Webhook」を追加
   - Webhook URL をコピー
   - Azure DevOps → Service Hooks → **Web Hooks**（Teams ではない）を選択
   - Trigger を選択（例: Pull request created）
   - URL に Teams の Webhook URL を貼り付け

**❌ 避けるべき方法:**
- Azure DevOps の Service Hooks で "Microsoft Teams" を選択しようとすること
  → 設定できないため、上記の方法を使用してください

</details>

### GitHub通知設定のトラブルシューティング

**問題: 「Automatically watch repositories」や「Automatically watch teams」が見つからない**

<details>
<summary>解決方法</summary>

**✅ これは正常です！**

GitHub は **2025年5月23日** にこれらの機能を**正式に廃止**しました。

**廃止された機能:**
- ❌ Automatically watch repositories
- ❌ Automatically watch teams

**理由:**
- 通知ノイズを減らすため
- ユーザーが自分で選んでウォッチするモデルへ移行

**現在の対処法:**

1. **Watch中のリポジトリを管理**
   - https://github.com/watching にアクセス
   - 不要なリポジトリを「Unwatch」
   - 必要なリポジトリのみ「Watch」を維持

2. **通知設定を調整**
   - https://github.com/settings/notifications
   - 「Watching」を「Notify me on GitHub」のみに変更（メール通知を減らす）
   - 「Participating」は「GitHub + Email」を維持（重要な通知）

3. **リポジトリごとに個別設定**
   - リポジトリページで「Watch」ボタンをクリック
   - 「Participating and @mentions」を選択（推奨）

**参考:**
[GitHub Blog - Sunset notice](https://github.blog/changelog/2025-04-14-sunset-notice-for-automatic-watching-of-repositories-and-teams/)

</details>

### Slack 統合のトラブルシューティング

**問題: Slack に Azure DevOps アプリを追加したい（Teams 個人版が使えない）**

<details>
<summary>解決方法</summary>

**✅ Slack は Teams 個人版の優れた代替手段です**

**Slack のメリット:**
- ✅ **無料プランでも Azure DevOps アプリが使える**（Teams個人版との違い）
- ✅ 双方向連携（通知 + `/azdevops` コマンド実行）が可能
- ✅ Work Item作成、ビルド確認、承認などが Slack 上で完結

**設定手順:**

1. **Slack Workspace に Azure DevOps アプリを追加**
   - Slack の左サイドバーで「アプリ」をクリック
   - 「Azure DevOps」を検索して追加
   - Azure DevOps へのサインインを許可

2. **Slack チャネルで購読を設定**
   ```
   /azdevops subscribe https://dev.azure.com/bell999/az400-handson3
   ```

3. **通知したいイベントを選択**
   - Pull requests created
   - Pull requests merged
   - Builds completed
   - Work items created

**代替方法（Service Hooks）:**
- Azure DevOps → Service Hooks → Slack
- Slack Incoming Webhook URL を指定
- この方式は通知のみ（コマンド実行不可）

</details>

**問題: Slack に通知が届かない**

<details>
<summary>解決方法</summary>

**確認すべきポイント:**

1. **Azure DevOps アプリが正しく接続されているか確認**
   ```
   /azdevops signin
   ```
   - Organization と Project が正しく認証されているか確認

2. **購読が正しく設定されているか確認**
   ```
   /azdevops subscriptions
   ```
   - 購読一覧が表示される
   - 通知したいイベントが含まれているか確認

3. **Service Hooks を使用している場合**
   ```powershell
   # Azure DevOps で Service Hook の状態を確認
   az devops service-endpoint list `
     --org https://dev.azure.com/bell999 `
     --project az400-handson3
   ```
   - Webhook URL が正しいか確認
   - Trigger イベントが適切か確認

4. **Slack チャネルのアクセス権限**
   - Azure DevOps アプリがチャネルに参加しているか確認
   - プライベートチャネルの場合は明示的に招待が必要

</details>

## 📚 参考リンク

**GitHub 統合:**
- [Azure Boards と GitHub の統合](https://learn.microsoft.com/azure/devops/boards/github/)
- [AB# 参照の使用](https://learn.microsoft.com/azure/devops/boards/github/link-to-from-github)
- [GitHub 通知設定](https://docs.github.com/account-and-profile/managing-subscriptions-and-notifications-on-github/setting-up-notifications)
- [GitHub Personal Access Token の作成](https://docs.github.com/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- [GitHub Blog - 自動ウォッチ機能の廃止](https://github.blog/changelog/2025-04-14-sunset-notice-for-automatic-watching-of-repositories-and-teams/)

**Azure DevOps:**
- [Azure DevOps CLI - Service Endpoint](https://learn.microsoft.com/cli/azure/devops/service-endpoint)
- [Service Hooks の概要](https://learn.microsoft.com/azure/devops/service-hooks/overview)

**Microsoft Teams 統合:**
- [Azure DevOps と Microsoft Teams の統合](https://learn.microsoft.com/azure/devops/pipelines/integrations/microsoft-teams)
- [Teams に Azure DevOps アプリを追加する](https://learn.microsoft.com/azure/devops/service-hooks/services/teams)
- [Teams Incoming Webhook の作成](https://learn.microsoft.com/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)

**Slack 統合:**
- [Azure DevOps と Slack の統合](https://learn.microsoft.com/azure/devops/service-hooks/services/slack)
- [Slack App Directory - Azure DevOps](https://slack.com/apps/AFH4Y66N9-azure-devops)
- [Slack Incoming Webhooks の作成](https://api.slack.com/messaging/webhooks)

## ➡️ 次のステップ
Lab 1 が完了したら、[Lab 2: Azure Pipelines 基礎](./02-Azure-Pipelines-基礎.md) に進んでください。

---

**Great job! You've completed Lab 1! 🎉**
