# Lab 2: Azure Pipelines 基礎

## 🎯 目的
このLabでは、Azure Pipelines の基礎を学び、YAML パイプライン、キャッシュ、Branch Policy、デバッグ方法を習得します。

## ⏱️ 所要時間
約75分

## 📋 前提条件
- Lab 0 の環境準備が完了していること
- Azure DevOps プロジェクト
- .NET SDK がインストールされていること

## 🎓 学習内容

### 重要ポイント（試験頻出）
✅ **Cache vs Artifacts の違い**
- **Cache タスク**: 依存関係（npm、NuGet、pip など）のキャッシュに使用
- **Pipeline Artifacts**: ビルド成果物の保存・共有に使用

✅ **System.Debug 変数**
- `System.Debug = true` で詳細ログを有効化
- パイプラインのトラブルシューティングに必須

✅ **YAML テンプレート**
- `extends` でテンプレートを継承
- コードの再利用とメンテナンス性向上

## 📝 演習内容

### Exercise 1: サンプルアプリケーションの準備

#### 1.1 リポジトリの作成

```powershell
# 新しいディレクトリを作成して移動
New-Item -ItemType Directory -Path ~\github\az400-handson3-lab2 -Force
Set-Location ~\github\az400-handson3-lab2

# Git リポジトリを初期化
git init
git branch -M main
```

#### 1.2 .NET Web API プロジェクトの作成

```powershell
# .NET Web API プロジェクトを作成
dotnet new webapi -n WebApp

# 🔧 重要: .NET 10で作成された場合は.NET 8に変更
# WebApp\WebApp.csproj の TargetFramework を net8.0 に変更
# OpenApi関連のコードとパッケージを削除（.NET 8では非互換）

# テストプロジェクトを作成（ルートレベルに作成）
dotnet new xunit -n WebApp.Tests
dotnet add WebApp.Tests\WebApp.Tests.csproj reference WebApp\WebApp.csproj

# テストプロジェクトも.NET 8に変更
# WebApp.Tests\WebApp.Tests.csproj の TargetFramework を net8.0 に変更

# ソリューションファイルを作成
dotnet new sln -n WebApp
dotnet sln add WebApp\WebApp.csproj
dotnet sln add WebApp.Tests\WebApp.Tests.csproj

# ビルドして確認
dotnet build
dotnet test
```

#### 1.3 Azure Repos にプッシュ

**方法1: Azure DevOps ポータルで手動作成**

1. Azure DevOps → Repos → Files にアクセス
2. リポジトリ名: `az400-lab2-pipeline`
3. 「Clone」をクリックして URL をコピー

```powershell
# 既存のリモートリポジトリを確認
git remote -v

# 既存の origin がある場合は削除または変更
# 削除する場合:
# git remote remove origin

# URL を変更する場合:
# git remote set-url origin https://dev.azure.com/bell999/az400-handson3/_git/az400-lab2-pipeline

# リモートリポジトリを追加
git remote add origin https://dev.azure.com/bell999/az400-handson3/_git/az400-lab2-pipeline

# ファイルをコミット
git add .
git commit -m "Initial commit: .NET Web API"
git push -u origin main
```

> **⚠️ 注意**: 
> - 既に origin が設定されている場合（例: GitHub）、`git remote add` はエラーになります
> - その場合は `git remote remove origin` で削除してから追加するか、`git remote set-url origin <新しいURL>` で変更してください
> - 詳細は[トラブルシューティング](#git-リモートリポジトリのエラー)を参照

**方法2: Azure DevOps CLI で自動化（推奨）**

Azure DevOps CLI でリポジトリ操作を行うには、Personal Access Token (PAT) が必要です。  
[Lab 1: 01-Github-AzureBoards連携.md の Key Vault 連携](./01-Github-AzureBoards連携.md#オプション2-azure-key-vault-に保存推奨) と同じ方法で、PAT を安全に管理します。

**Step 1: Azure DevOps PAT を作成**

1. Azure DevOps にアクセス: `https://dev.azure.com/bell999`
2. 右上のユーザーアイコン → 「Personal access tokens」をクリック
3. 「+ New Token」をクリック
4. 以下を設定：
   - Name: `az400-handson3-pat`
   - Organization: `bell999`
   - Expiration: 30 days（または任意の期間）
   - Scopes: 「Custom defined」を選択
     - ✅ **Code**: Read, write, & manage
     - ✅ **Build**: Read & execute
     - ✅ **Project and Team**: Read, write, & manage
5. 「Create」をクリック
6. **重要**: 表示されたトークンをコピーして保存（一度しか表示されません）

**Step 2: Azure Key Vault にPATを保存**

```powershell
# Azure にログイン
az login --use-device-code

# Key Vault が存在しない場合は作成（Lab 1 で作成済みの場合はスキップ）
$kvName = "kv-az400-$($env:USERNAME)"

# 既存の Key Vault を確認
$kvExists = az keyvault list --query "[?name=='$kvName'].name" -o tsv

if (-not $kvExists) {
    Write-Host "Creating Key Vault: $kvName"
    
    # リソースグループを作成
    az group create `
      --name "rg-az400-handson3" `
      --location "japaneast"
    
    # Key Vault を作成
    az keyvault create `
      --name $kvName `
      --resource-group "rg-az400-handson3" `
      --location "japaneast" `
      --enable-rbac-authorization true
    
    # 自分に Key Vault Secrets Officer 権限を付与
    $userId = az ad signed-in-user show --query id -o tsv
    $subscriptionId = az account show --query id -o tsv
    
    az role assignment create `
      --role "Key Vault Secrets Officer" `
      --assignee $userId `
      --scope "/subscriptions/$subscriptionId/resourceGroups/rg-az400-handson3/providers/Microsoft.KeyVault/vaults/$kvName"
    
    Write-Host "Waiting for RBAC propagation..."
    Start-Sleep -Seconds 30
}

# Azure DevOps PAT を環境変数に設定（Step 1 でコピーしたトークンを貼り付け）
$env:AZURE_DEVOPS_PAT = Read-Host -Prompt "Azure DevOps PAT を入力してください" -AsSecureString | ConvertFrom-SecureString -AsPlainText

# PAT を Key Vault に保存
az keyvault secret set `
  --vault-name $kvName `
  --name "azure-devops-pat" `
  --value $env:AZURE_DEVOPS_PAT

Write-Host "✅ Azure DevOps PAT saved to Key Vault: $kvName"
```

**Step 3: Key Vault から PAT を取得してリポジトリを作成**

```powershell
# Azure DevOps CLI 拡張機能をインストール（初回のみ）
az extension add --name azure-devops

# Key Vault から PAT を取得して環境変数に設定
$kvName = "kv-az400-$($env:USERNAME)"
$env:AZURE_DEVOPS_EXT_PAT = az keyvault secret show `
  --vault-name $kvName `
  --name "azure-devops-pat" `
  --query value -o tsv

# Azure DevOps のデフォルト設定を構成
az devops configure --defaults organization=https://dev.azure.com/bell999 project=az400-handson3

# 設定を確認
az devops configure --list

# リポジトリを作成
$repoName = "az400-handson3-lab2-pipeline"
az repos create --name $repoName

# リポジトリのクローン URL を取得
$repoUrl = az repos show --repository $repoName --query "remoteUrl" -o tsv
Write-Host "Repository URL: $repoUrl"

# 既存のリモートリポジトリを確認
git remote -v

# 既存のリモートリポジトリがある場合は変更または削除
# 方法1: 既存の origin を削除して新しく追加
if (git remote | Select-String "origin") {
    Write-Host "既存のリモート origin を削除します..."
    git remote remove origin
}
git remote add origin $repoUrl

# 方法2: 既存の origin の URL を変更（代替方法）
# git remote set-url origin $repoUrl

# ファイルをコミットしてプッシュ
git add .
git commit -m "Initial commit: .NET Web API"
git push -u origin main

# プッシュ成功後、ブラウザで確認
Write-Host "`n✅ Push completed! Opening repository in browser..."
Write-Host "Repository URL: https://dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline"
Start-Process "https://dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline"
```

> **💡 ヒント**: 
> - Key Vault 名は `kv-az400-{ユーザー名}` の形式で自動生成されます
> - Lab 1 で既に Key Vault を作成済みの場合、Step 2 のKey Vault作成部分はスキップされます
> - PAT は Key Vault に安全に保存され、必要な時に取得できます

> **⚠️ 重要**: 
> - リポジトリ名は **`az400-handson3-lab2-pipeline`** です
> - ブラウザで確認する際は、正しいリポジトリを開いているか確認してください
> - Azure DevOps → Repos → リポジトリ選択ドロップダウンから **`az400-handson3-lab2-pipeline`** を選択

> **🔄 リモートリポジトリの変更**:
> - 既存のリモート origin (例: GitHub) が設定されている場合は削除または変更が必要です
> - `git remote -v` で現在のリモートリポジトリを確認できます
> - 既存の origin を削除する場合: `git remote remove origin`
> - 既存の origin のURLを変更する場合: `git remote set-url origin $repoUrl`
> - 複数のリモートを管理する場合は別名を使用: `git remote add azure $repoUrl`

> **⚠️ 注意**: 
> - `AZURE_DEVOPS_EXT_PAT` 環境変数が設定されていないと認証エラーが発生します
> - PAT のスコープに「Code: Read, write, & manage」が含まれていることを確認してください
> - PAT には有効期限があるため、期限切れの場合は再作成が必要です

> **🔒 セキュリティのベストプラクティス**:
> - PAT は必要最小限のスコープのみを許可
> - Key Vault を使用して PAT を安全に保管
> - 不要になった PAT は Azure DevOps から削除
> - 定期的に PAT をローテーション（更新）

#### 1.4 Azure Repos でリポジトリを確認

**重要**: プッシュ後、正しいリポジトリにファイルがアップロードされたか確認します。

1. ブラウザで Azure DevOps にアクセス: `https://dev.azure.com/bell999/az400-handson3`
2. 左メニューから **「Repos」** → **「Files」** をクリック
3. **リポジトリ選択ドロップダウン**（画面上部）をクリック
4. **`az400-handson3-lab2-pipeline`** を選択

![リポジトリ選択](https://via.placeholder.com/800x100?text=Repository+Dropdown+%3E+az400-handson3-lab2-pipeline)

**確認ポイント**:
- ✅ `WebApp/` フォルダが表示される
- ✅ `WebApp.Tests/` フォルダが表示される
- ✅ `WebApp.sln` ファイルが表示される
- ✅ `.gitignore` などのファイルが表示される

**❌ よくある間違い**:
- リポジトリ名 `az400-handson3` を開いている → これは別のリポジトリです
- 正しいリポジトリは `az400-handson3-lab2-pipeline` です

```powershell
# PowerShell でリポジトリを確認（オプション）
az repos list --organization https://dev.azure.com/bell999 --project az400-handson3 --query "[].{Name:name, URL:webUrl}" -o table

# 出力例:
# Name                            URL
# -----------------------------   ----------------------------------------------------------
# az400-handson3                  https://dev.azure.com/bell999/az400-handson3/_git/az400-handson3
# az400-handson3-lab2-pipeline    https://dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline
```

### Exercise 2: 基本的な YAML パイプラインの作成

#### 2.1 azure-pipelines.yml の作成

プロジェクトルートに `azure-pipelines.yml` を作成：

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  displayName: 'Build Stage'
  jobs:
  - job: BuildJob
    displayName: 'Build and Test'
    steps:
    - task: UseDotNet@2
      displayName: 'Use .NET 8.0'
      inputs:
        version: '8.0.x'
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore NuGet Packages'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build Solution'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration)'
    
    - task: DotNetCoreCLI@2
      displayName: 'Run Tests'
      inputs:
        command: 'test'
        projects: '**/*Tests.csproj'
        arguments: '--configuration $(buildConfiguration) --no-build'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish Application'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
        zipAfterPublish: true
    
    - task: PublishBuildArtifacts@1
      displayName: 'Publish Artifacts'
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
        publishLocation: 'Container'
```

#### 2.2 パイプラインの作成

1. Azure DevOps → Pipelines → Create Pipeline
2. 「Azure Repos Git」を選択
3. リポジトリ `az400-lab2-pipeline` を選択
4. 「Existing Azure Pipelines YAML file」を選択
5. Path: `/azure-pipelines.yml`
6. 「Continue」→「Run」をクリック

#### 2.3 実行結果の確認

- パイプラインが正常に実行されることを確認
- 各ステップのログを確認

### Exercise 3: Cache タスクの実装（重要）

#### 3.1 NuGet パッケージのキャッシュ

`azure-pipelines.yml` を更新：

```yaml
# azure-pipelines.yml（Cacheタスクを追加）
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  NUGET_PACKAGES: $(Pipeline.Workspace)/.nuget/packages

stages:
- stage: Build
  displayName: 'Build Stage'
  jobs:
  - job: BuildJob
    displayName: 'Build and Test'
    steps:
    - task: UseDotNet@2
      displayName: 'Use .NET 8.0'
      inputs:
        version: '8.0.x'
    
    # ✅ Cache タスクを追加（重要）
    - task: Cache@2
      displayName: 'Cache NuGet Packages'
      inputs:
        key: 'nuget | "$(Agent.OS)" | **/*.csproj'
        restoreKeys: |
          nuget | "$(Agent.OS)"
        path: $(NUGET_PACKAGES)
        cacheHitVar: CACHE_RESTORED
      
    - task: DotNetCoreCLI@2
      displayName: 'Restore NuGet Packages'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build Solution'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-restore'
    
    # ... 残りのステップは同じ
```

#### 3.2 キャッシュの動作確認

```powershell
# 変更をコミット
git add azure-pipelines.yml
git commit -m "Add NuGet cache"
git push
```

1. パイプラインが実行されることを確認
2. ログで「Cache NuGet Packages」を確認
3. 初回実行: `Cache not found`
4. 2回目実行: `Cache restored` が表示されることを確認

#### 3.3 Cache vs Artifacts の比較表（試験重要）

| 項目 | Cache タスク | Pipeline Artifacts |
|------|-------------|-------------------|
| 用途 | 依存関係のキャッシュ | ビルド成果物の保存 |
| 例 | npm packages, NuGet, pip | .zip, .dll, .exe |
| 保存期間 | 7日間（デフォルト） | 30日間（デフォルト） |
| 共有範囲 | 同じパイプライン内 | パイプライン間で共有可能 |
| タスク | `Cache@2` | `PublishBuildArtifacts@1` |

### Exercise 4: System.Debug による詳細ログ（重要）

#### 4.1 System.Debug 変数の追加

`azure-pipelines.yml` を更新：

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  NUGET_PACKAGES: $(Pipeline.Workspace)/.nuget/packages
  # ✅ System.Debug を追加（詳細ログを有効化）
  System.Debug: true

stages:
- stage: Build
  # ... 以降は同じ
```

#### 4.2 詳細ログの確認

```powershell
git add azure-pipelines.yml
git commit -m "Enable System.Debug"
git push
```

パイプライン実行ログで確認：
- ✅ 各タスクの詳細な実行ログが表示される
- ✅ 環境変数の値が表示される
- ✅ タスクの内部処理が可視化される

#### 4.3 System.Debug のユースケース

| シナリオ | System.Debug | 効果 |
|----------|--------------|------|
| 通常運用 | false | ログが簡潔で見やすい |
| トラブルシューティング | true | 詳細な情報で原因特定が容易 |
| パフォーマンス最適化 | true | 各ステップの実行時間を確認 |

### Exercise 5: YAML テンプレートの作成

#### 5.1 テンプレートファイルの作成

`pipelines/templates/build-template.yml` を作成：

```yaml
# pipelines/templates/build-template.yml
parameters:
- name: buildConfiguration
  type: string
  default: 'Release'
- name: dotnetVersion
  type: string
  default: '8.0.x'

steps:
- task: UseDotNet@2
  displayName: 'Use .NET ${{ parameters.dotnetVersion }}'
  inputs:
    version: '${{ parameters.dotnetVersion }}'

- task: Cache@2
  displayName: 'Cache NuGet Packages'
  inputs:
    key: 'nuget | "$(Agent.OS)" | **/*.csproj'
    restoreKeys: |
      nuget | "$(Agent.OS)"
    path: $(NUGET_PACKAGES)
    cacheHitVar: CACHE_RESTORED

- task: DotNetCoreCLI@2
  displayName: 'Restore NuGet Packages'
  inputs:
    command: 'restore'
    projects: '**/*.csproj'

- task: DotNetCoreCLI@2
  displayName: 'Build Solution'
  inputs:
    command: 'build'
    projects: '**/*.csproj'
    arguments: '--configuration ${{ parameters.buildConfiguration }} --no-restore'

- task: DotNetCoreCLI@2
  displayName: 'Run Tests'
  inputs:
    command: 'test'
    projects: '**/*Tests.csproj'
    arguments: '--configuration ${{ parameters.buildConfiguration }} --no-build'
```

#### 5.2 メインパイプラインでテンプレートを使用

`azure-pipelines-use-template.yml` を作成：

```yaml
# azure-pipelines-use-template.yml（新パイプライン）
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  NUGET_PACKAGES: $(Pipeline.Workspace)/.nuget/packages
  System.Debug: false  # デバッグ完了後は false に戻す

stages:
- stage: Build
  displayName: 'Build Stage'
  jobs:
  - job: BuildJob
    displayName: 'Build and Test'
    steps:
    # ✅ テンプレートを使用
    - template: pipelines/templates/build-template.yml
      parameters:
        buildConfiguration: $(buildConfiguration)
        dotnetVersion: '8.0.x'
    
    - task: DotNetCoreCLI@2
      displayName: 'Publish Application'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'
        zipAfterPublish: true
    
    - task: PublishBuildArtifacts@1
      displayName: 'Publish Artifacts'
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
```

#### 5.3 extends の使用（試験重要）

`pipelines/templates/base-pipeline.yml` を作成：

```yaml
# pipelines/templates/base-pipeline.yml
parameters:
- name: buildConfiguration
  type: string
  default: 'Release'

stages:
- stage: Build
  jobs:
  - job: BuildJob
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - template: build-template.yml
      parameters:
        buildConfiguration: ${{ parameters.buildConfiguration }}
```

`azure-pipelines-extends.yml` を作成：

```yaml
# azure-pipelines-extends.yml
# ✅ extends を使用してテンプレートを継承
extends:
  template: pipelines/templates/base-pipeline.yml
  parameters:
    buildConfiguration: 'Release'
```

### Exercise 6: Branch Policy の設定

#### 6.1 Branch Policy の有効化

1. Azure DevOps → Repos → Branches
2. `main` ブランチの「...」→「Branch policies」をクリック
3. 以下を設定：

**Require a minimum number of reviewers**
- ✅ 有効化
- Minimum number of reviewers: 1
- ✅ Allow requestors to approve their own changes（学習用にチェック）

**Check for linked work items**
- ✅ Required

**Check for comment resolution**
- ✅ Required

**Build Validation**
- ✅ 追加
- Build pipeline: `az400-lab2-pipeline`
- Trigger: Automatic
- Policy requirement: Required
- Build expiration: Immediately

#### 6.2 Status Policy の追加（SonarCloud などの外部チェック用）

```yaml
# azure-pipelines.yml に Status チェックを追加
stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    # ... ビルドステップ
    
    # ✅ Status Policy 用のチェック
    - script: |
        echo "Running quality gate check"
        # 実際には SonarCloud などの品質チェックを実行
      displayName: 'Quality Gate Check'
```

Branch Policy で「Status Check」を追加：
1. Branch policies → Status checks
2. 「+ Add status policy」をクリック
3. Status to check: `Quality Gate`
4. Policy requirement: Required

### Exercise 7: Pull Request でのパイプライン実行

#### 7.1 Feature ブランチの作成

```powershell
git checkout -b feature/add-logging

# コードを変更
"// Add logging" | Add-Content WebApp\Program.cs
git add .
git commit -m "Add logging comment"
git push origin feature/add-logging
```

#### 7.2 Pull Request の作成

1. Azure DevOps → Repos → Pull requests
2. 「New pull request」をクリック
3. Source: `feature/add-logging`
4. Target: `main`
5. Title: `Add logging feature`
6. Work Items をリンク（必須）
7. 「Create」をクリック

#### 7.3 ビルド検証の確認

- ✅ パイプラインが自動的に実行される
- ✅ ビルドが成功するまでマージできない
- ✅ すべての Policy を満たすと「Complete」ボタンが有効化

## 📊 演習のまとめ

### Cache タスクの書き方（重要）

```yaml
# NuGet の場合
- task: Cache@2
  inputs:
    key: 'nuget | "$(Agent.OS)" | **/packages.lock.json'
    path: $(NUGET_PACKAGES)

# npm の場合
- task: Cache@2
  inputs:
    key: 'npm | "$(Agent.OS)" | **/package-lock.json'
    path: $(npm_config_cache)

# pip の場合
- task: Cache@2
  inputs:
    key: 'python | "$(Agent.OS)" | requirements.txt'
    path: $(PIP_CACHE_DIR)
```

### 変数の使い方

| 変数 | 用途 | 設定値 |
|------|------|--------|
| System.Debug | 詳細ログ | `true` または `false` |
| buildConfiguration | ビルド構成 | `Debug` または `Release` |
| Build.ArtifactStagingDirectory | 成果物の出力先 | システム提供 |

## ✅ 確認問題

### Q1: npm パッケージのキャッシュに使用すべきタスクは？
- [ ] A. PublishBuildArtifacts
- [ ] B. Cache
- [ ] C. DownloadBuildArtifacts
- [ ] D. PublishPipelineArtifact

<details>
<summary>解答</summary>

**正解: B**

説明:
- npm、NuGet、pip などの依存関係のキャッシュには `Cache@2` タスクを使用
- Artifacts タスクはビルド成果物の保存に使用
</details>

### Q2: パイプラインの詳細ログを有効にする変数は？
- [ ] A. Debug
- [ ] B. System.Log
- [ ] C. System.Debug
- [ ] D. EnableDebugLog

<details>
<summary>解答</summary>

**正解: C**

説明:
- `System.Debug = true` で詳細ログを有効化
- トラブルシューティング時に非常に有用
</details>

### Q3: テンプレートを継承してパイプラインを拡張するキーワードは？
- [ ] A. template
- [ ] B. extends
- [ ] C. include
- [ ] D. import

<details>
<summary>解答</summary>

**正解: B**

説明:
- `extends` キーワードでテンプレートを継承
- コードの再利用とメンテナンス性が向上
</details>

## 🔍 トラブルシューティング

### .NET 10でプロジェクトが作成された場合のエラー

**問題**: `dotnet new webapi` で .NET 10 プロジェクトが作成され、以下のエラーが発生する：
- `AddOpenApi()` メソッドが見つからない
- `MapOpenApi()` メソッドが見つからない
- テストプロジェクトでビルドエラーが発生

**解決方法**:

1. **WebApp.csproj を .NET 8 に変更**:
```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
  <!-- net10.0 から net8.0 に変更 -->
</PropertyGroup>
```

2. **OpenApi関連のコードを削除** (Program.cs):
```csharp
// 削除: builder.Services.AddOpenApi();
// 削除: app.MapOpenApi();
```

3. **OpenApiパッケージを削除**:
```powershell
dotnet remove WebApp\WebApp.csproj package Microsoft.AspNetCore.OpenApi
```

4. **WebApp.Tests.csproj も .NET 8 に変更**:
```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

5. **クリーンビルド**:
```powershell
Remove-Item -Recurse -Force WebApp\obj, WebApp.Tests\obj
dotnet clean
dotnet build
```

### テストプロジェクトの配置エラー

**問題**: テストプロジェクトが `WebApp\WebApp.Tests` に作成され、参照エラーが発生する。

**解決方法**: テストプロジェクトはルートレベルに配置する：
```
az400-handson3-lab2/
├── WebApp/              # Web APIプロジェクト
│   └── WebApp.csproj
└── WebApp.Tests/        # テストプロジェクト（ルートレベル）
    └── WebApp.Tests.csproj
```

誤った場所に作成した場合：
```powershell
# 誤った場所のテストプロジェクトを削除
Remove-Item -Recurse -Force WebApp\WebApp.Tests

# ルートレベルに再作成
dotnet new xunit -n WebApp.Tests
dotnet add WebApp.Tests\WebApp.Tests.csproj reference WebApp\WebApp.csproj
```

### Azure DevOps CLI 認証エラー

**問題**: `az repos create` などのコマンドで以下のエラーが発生する：
```
The requested resource requires user authentication: https://dev.azure.com/bell999/_apis
```

**原因**: Azure DevOps CLI に Personal Access Token (PAT) が設定されていない。

**解決方法**:

**方法1: 環境変数に直接設定（一時的）**
```powershell
# Azure DevOps PAT を環境変数に設定
$env:AZURE_DEVOPS_EXT_PAT = "your-pat-token-here"

# コマンドを実行
az repos create --name $repoName
```

**方法2: Key Vault から取得（推奨）**
```powershell
# Key Vault から PAT を取得して環境変数に設定
$kvName = "kv-az400-$($env:USERNAME)"
$env:AZURE_DEVOPS_EXT_PAT = az keyvault secret show `
  --vault-name $kvName `
  --name "azure-devops-pat" `
  --query value -o tsv

# 環境変数が正しく設定されたことを確認
if ($env:AZURE_DEVOPS_EXT_PAT) {
    Write-Host "✅ PAT is set (length: $($env:AZURE_DEVOPS_EXT_PAT.Length))"
} else {
    Write-Host "❌ PAT is not set"
}

# コマンドを実行
az repos create --name $repoName
```

**確認ポイント**:
- ✅ PAT が Azure DevOps で作成されている
- ✅ PAT のスコープに「Code: Read, write, & manage」が含まれている
- ✅ PAT の有効期限が切れていない
- ✅ `az devops configure --list` で組織とプロジェクトが設定されている

### Git リモートリポジトリのエラー

**問題**: `git remote add origin` を実行すると以下のエラーが発生する：
```
error: remote origin already exists.
```

**原因**: 既に origin という名前のリモートリポジトリが設定されている（例: GitHub のリポジトリ）。

**確認方法**:
```powershell
# 現在のリモートリポジトリを確認
git remote -v

# 出力例:
# origin  https://github.com/bell999-az400-handson/az400-handson3.git (fetch)
# origin  https://github.com/bell999-az400-handson/az400-handson3.git (push)
```

**解決方法**:

**方法1: 既存の origin を削除して新しく追加**
```powershell
# 既存のリモート origin を削除
git remote remove origin

# 新しいリモートリポジトリを追加
git remote add origin https://bell999@dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline

# 確認
git remote -v
```

**方法2: 既存の origin の URL を変更**
```powershell
# リモートリポジトリの URL を変更
git remote set-url origin https://bell999@dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline

# 確認
git remote -v
```

**方法3: 別名で複数のリモートを管理**
```powershell
# GitHub は origin のまま残し、Azure Repos は別名で追加
git remote add azure https://bell999@dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline

# GitHub にプッシュ
git push -u origin main

# Azure Repos にプッシュ
git push -u azure main

# 確認
git remote -v
# 出力:
# origin  https://github.com/bell999-az400-handson/az400-handson3.git (fetch)
# origin  https://github.com/bell999-az400-handson/az400-handson3.git (push)
# azure   https://bell999@dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline (fetch)
# azure   https://bell999@dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline (push)
```

> **💡 推奨**: 学習環境では方法1または方法2を使用し、origin を Azure Repos に変更することを推奨します。本番環境で複数のリモートリポジトリを管理する場合は方法3が適しています。

### パイプライン実行時の .NET バージョンエラー

**問題**: Azure Pipelines でパイプラインを実行すると、以下のエラーが発生する：
```
error NETSDK1045: The current .NET SDK does not support targeting .NET 10.0.  
Either target .NET 8.0 or lower, or use a version of the .NET SDK that supports .NET 10.0.
```

**原因**: `WebApp.Tests.csproj` または `WebApp.csproj` のターゲットフレームワークが `net10.0` のままになっている。

**診断方法**:
```powershell
# プロジェクトファイルのターゲットフレームワークを確認
Select-String -Path "WebApp\WebApp.csproj" -Pattern "TargetFramework"
Select-String -Path "WebApp.Tests\WebApp.Tests.csproj" -Pattern "TargetFramework"
```

**解決方法**:

1. **両方の .csproj ファイルを .NET 8.0 に変更**:

**WebApp\WebApp.csproj**:
```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
  <!-- net10.0 ではなく net8.0 にする -->
</PropertyGroup>
```

**WebApp.Tests\WebApp.Tests.csproj**:
```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
  <!-- net10.0 ではなく net8.0 にする -->
</PropertyGroup>
```

2. **変更をコミットしてプッシュ**:
```powershell
# 変更を確認
git status

# 変更をコミット
git add WebApp/WebApp.csproj WebApp.Tests/WebApp.Tests.csproj
git commit -m "Fix: Change target framework from net10.0 to net8.0"

# Azure Repos にプッシュ
git push origin main
```

3. **ローカルでビルドテスト**（推奨）:
```powershell
# クリーンビルド
Remove-Item -Recurse -Force WebApp\obj, WebApp.Tests\obj -ErrorAction SilentlyContinue
dotnet clean
dotnet build

# テスト実行
dotnet test
```

4. **パイプラインを再実行**:
- Azure DevOps → Pipelines → 失敗したパイプラインを選択
- 「Rerun failed jobs」または「Run new」をクリック

**確認ポイント**:
- ✅ `WebApp.csproj` が `<TargetFramework>net8.0</TargetFramework>` になっている
- ✅ `WebApp.Tests.csproj` が `<TargetFramework>net8.0</TargetFramework>` になっている
- ✅ 変更が Azure Repos にプッシュされている
- ✅ ローカルで `dotnet build` が成功する
- ✅ ローカルで `dotnet test` が成功する

> **💡 ヒント**: プロジェクト作成時に .NET 10 が生成された場合、**すべての .csproj ファイル**を確認して .NET 8.0 に変更する必要があります。obj フォルダに古いビルド出力が残っている場合は削除してクリーンビルドを実行してください。

### Cache タスクで packages.lock.json が見つからないエラー

**問題**: Cache タスクで以下のエラーが発生する：
```
System.IO.FileNotFoundException: No matching files found for pattern: **/packages.lock.json
Cache NuGet Packages
```

**原因**: .NET プロジェクトでは、デフォルトでは `packages.lock.json` ファイルは生成されません。

**解決方法**:

**方法1: .csproj ファイルをキャッシュキーにする（推奨）**

Cache タスクのキーを `**/*.csproj` に変更します：

```yaml
- task: Cache@2
  displayName: 'Cache NuGet Packages'
  inputs:
    key: 'nuget | "$(Agent.OS)" | **/*.csproj'
    restoreKeys: |
      nuget | "$(Agent.OS)"
    path: $(NUGET_PACKAGES)
    cacheHitVar: CACHE_RESTORED
```

**方法2: packages.lock.json を生成する（より厳密）**

各 `.csproj` ファイルに以下を追加：

```xml
<PropertyGroup>
  <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
</PropertyGroup>
```

その後、ローカルで restore を実行：

```powershell
dotnet restore
git add **/packages.lock.json
git commit -m "Add packages.lock.json"
git push
```

**確認ポイント**:
- ✅ `NUGET_PACKAGES` 変数が定義されている
- ✅ Cache タスクの `key` が存在するファイルパターンを参照している
- ✅ `path: $(NUGET_PACKAGES)` が正しく設定されている
- ✅ Build タスクに `--no-restore` 引数が追加されている

> **💡 推奨**: 学習環境では方法1（.csproj をキーにする）の方がシンプルで十分です。本番環境で厳密な依存関係管理が必要な場合は方法2を検討してください。

### キャッシュがヒットしない
```yaml
# キーの確認
- script: |
    echo "Agent.OS: $(Agent.OS)"
    echo "Build.SourcesDirectory: $(Build.SourcesDirectory)"
  displayName: 'Debug Cache Key'
```

### パイプラインが実行されない
- Trigger の設定を確認
- Branch Policy の設定を確認
- YAML の構文エラーを確認

## 📚 参考リンク
- [Azure Pipelines YAML スキーマ](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Cache タスク](https://learn.microsoft.com/azure/devops/pipelines/tasks/utility/cache)
- [Branch Policies](https://learn.microsoft.com/azure/devops/repos/git/branch-policies)

## ➡️ 次のステップ
Lab 2 が完了したら、[Lab 3: Azure Artifacts パッケージ管理](./03-Azure-Artifacts-パッケージ管理.md) に進んでください。

---

**Excellent work! You've mastered Azure Pipelines basics! 🚀**
