# Lab 3: Azure Artifacts パッケージ管理

## 🎯 目的
このLabでは、Azure Artifacts を使用したパッケージ管理を学び、Feed、Views、NuGet パッケージの発行と利用方法を習得します。

## ⏱️ 所要時間
約60分

## 📋 前提条件
- Lab 0 の環境準備が完了していること
- .NET SDK 8.0 がインストールされていること
- Azure DevOps プロジェクト（az400-handson3）
- 本リポジトリ（az400-handson3-lab2）をクローン済み
- リポジトリパス: `C:\Users\bell9\github\az400-handson3-lab2`

## 📁 本演習でのリポジトリ構成

この演習では、既存のリポジトリに以下のプロジェクトを追加します：

```
az400-handson3-lab2/
├── WebApp/                          # Lab 2 で作成済み
├── WebApp.Tests/                    # Lab 2 で作成済み
├── Az400.Utils/                     # ← Exercise 2 で作成（クラスライブラリ）
├── Az400.Consumer/                  # ← Exercise 5 で作成（コンソールアプリ）
├── azure-pipelines.yml              # Lab 2 で作成済み
├── azure-pipelines-package.yml      # ← Exercise 6 で作成（パッケージ発行用）
└── WebApp.slnx                      # ソリューションファイル
```

**メリット:**
- ✅ 統合的なDevOpsプラクティスを学習
- ✅ すべてのLabを1つのプロジェクトで管理
- ✅ Azure Pipelines、Artifacts、Boardsの連携を体験

## 🎓 学習内容

### 重要ポイント（試験頻出）
✅ **Feed の概念**
- パッケージを保存・管理するコンテナ
- NuGet、npm、Maven、Python などに対応

✅ **Views の種類**
- **@Local**: Feed 内のすべてのパッケージ
- **@Prerelease**: プレリリース版
- **@Release**: 正式リリース版

✅ **BACPAC vs DACPAC**
- **BACPAC**: schema + data（データ移行用）
- **DACPAC**: schema only（スキーマのみ）

## 📝 演習内容

### Exercise 1: Azure Artifacts Feed の作成

#### 1.1 Feed の作成

1. Azure DevOps → Artifacts → 「+ Create Feed」をクリック
2. 以下を入力：
   - Name: `az400-handson3-package-feed`
   - Visibility: 
     - ✅ Members of bell999（組織内のみ）
   - Upstream sources:
     - ✅ Include packages from common public sources
     - nuget.org, npmjs.com, PyPI などを含める
3. 「Create」をクリック

#### 1.2 Feed の Views 確認

Feed 作成直後は「Connect to the feed to get started」画面が表示されます。Views を確認するには：

**手順:**
1. 画面右上の **⚙️（歯車アイコン）** をクリック
2. ドロップダウンメニューから **「Feed settings」** を選択
3. 左側のナビゲーションメニューで **「Views」** をクリック
4. 以下の3つのビューが自動的に作成されていることを確認：
   - ✅ `@Local` - Feed 内のすべてのパッケージ
   - ✅ `@Prerelease` - プレリリース版パッケージ
   - ✅ `@Release` - 正式リリース版パッケージ

```
Feed 詳細画面
  ↓
右上の ⚙️ をクリック
  ↓
Feed settings
  ↓
左メニューの「Views」
```

**注意:** パッケージを1つ以上発行すると、画面上部に「Packages」「Views」タブが表示されるようになります。

#### 1.3 Azure CLI での確認（オプション）

Azure CLI で Feed の存在を確認する場合、まず Azure DevOps 拡張機能をインストールします：

```powershell
# Azure DevOps 拡張機能をインストール
az extension add --name azure-devops

# 拡張機能のバージョンを確認
az extension show --name azure-devops --query version

# Feed の一覧を確認（Web UIでの確認を推奨）
# 注: NuGet Feed の場合、Azure Portal または Azure DevOps Web UI での確認が推奨されます
```

**推奨:** Feed の確認は Azure DevOps の Web UI（Artifacts メニュー）で行うのが最も確実です。

### Exercise 2: NuGet パッケージの作成

#### 2.1 クラスライブラリプロジェクトの作成

```powershell
# 本リポジトリのルートディレクトリに移動
Set-Location C:\Users\bell9\github\az400-handson3-lab2

# クラスライブラリを作成
dotnet new classlib -n Az400.Utils

# プロジェクトディレクトリに移動
Set-Location Az400.Utils

# ソリューションに追加
Set-Location ..
dotnet sln WebApp.slnx add Az400.Utils\Az400.Utils.csproj
```

#### 2.2 サンプルコードの追加

`StringHelper.cs` を作成：

```csharp
namespace Az400.Utils;

public static class StringHelper
{
    /// <summary>
    /// 文字列を逆順にします
    /// </summary>
    public static string Reverse(string input)
    {
        if (string.IsNullOrEmpty(input))
            return input;
        
        char[] charArray = input.ToCharArray();
        Array.Reverse(charArray);
        return new string(charArray);
    }
    
    /// <summary>
    /// 文字列が回文かどうかを判定します
    /// </summary>
    public static bool IsPalindrome(string input)
    {
        if (string.IsNullOrEmpty(input))
            return false;
        
        string normalized = input.ToLower().Replace(" ", "");
        return normalized == Reverse(normalized);
    }
}
```

#### 2.3 プロジェクトファイルの更新

`Az400.Utils.csproj` を編集：

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    
    <!-- パッケージ情報 -->
    <PackageId>Az400.Utils</PackageId>
    <Version>1.0.0</Version>
    <Authors>Your Name</Authors>
    <Company>AZ400 Training</Company>
    <Description>AZ-400 ハンズオン用のユーティリティライブラリ</Description>
    <PackageTags>az400;utils;training</PackageTags>
  </PropertyGroup>

</Project>
```

#### 2.4 パッケージのビルド

```powershell
# Az400.Utils プロジェクトディレクトリに移動
Set-Location C:\Users\bell9\github\az400-handson3-lab2\Az400.Utils

# パッケージを作成
dotnet pack --configuration Release

# 出力先を確認
Get-ChildItem bin\Release\

# 結果: Az400.Utils.1.0.0.nupkg が作成される
```

#### 2.5 .gitignore の更新（オプション）

```powershell
# Az400.Utils のビルド成果物を .gitignore に追加
Set-Location C:\Users\bell9\github\az400-handson3-lab2
Add-Content .gitignore "`nAz400.Utils/bin/`nAz400.Utils/obj/`nAz400.Consumer/bin/`nAz400.Consumer/obj/"
```

### Exercise 3: Azure Artifacts への発行

#### 3.1 認証情報の設定

**🔐 推奨方法: Azure Artifacts Credential Provider（自動認証）**

```powershell
# Azure Artifacts Credential Provider のインストール（Windows）
Invoke-WebRequest -Uri https://aka.ms/install-artifacts-credprovider.ps1 -OutFile install-artifacts-credprovider.ps1
.\install-artifacts-credprovider.ps1
```

- ✅ **推奨**: 一度インストールすれば自動的に Azure DevOps 認証を処理
- ✅ **安全**: PAT を手動管理する必要なし
- ✅ **永続的**: インストール後は毎回設定不要

**⚠️ 代替方法: 環境変数による一時的な認証（非推奨）**

```powershell
# PowerShell セッション中のみ有効（一時的）
# 注意: この環境変数はファイルに保存しないでください（セキュリティリスク）
$env:VSS_NUGET_EXTERNAL_FEED_ENDPOINTS = @"
{
  "endpointCredentials": [
    {
      "endpoint": "https://pkgs.dev.azure.com/bell999/_packaging/az400-handson3-package-feed/nuget/v3/index.json",
      "password": "your-personal-access-token"
    }
  ]
}
"@
```

- ⚠️ **一時的**: PowerShell ターミナルを閉じると消える
- ⚠️ **手動管理**: 毎回設定が必要
- ❌ **ファイルに保存禁止**: PAT 漏洩のリスク（Git コミット、共有など）

**💡 ヒント**: 初回実行時は Credential Provider が推奨されます。環境変数は学習目的やトラブルシューティング時のみ使用してください。

#### 3.2 NuGet ソースの追加

1. Azure DevOps → Artifacts → Feed を開く
2. 「Connect to Feed」をクリック
3. 「**dotnet**」を選択（左側のメニュー）
4. Project setup 内の `value` 属性（ソース URL）をコピー（例）：
   ```
   https://pkgs.dev.azure.com/bell999/_packaging/az400-handson3-package-feed/nuget/v3/index.json
   ```

**✅ 推奨：Credential Provider 使用時（認証自動、PAT 不要）**

```powershell
# NuGet ソースを追加（Credential Provider がインストール済みの場合）
dotnet nuget add source `
  https://pkgs.dev.azure.com/bell999/_packaging/az400-handson3-package-feed/nuget/v3/index.json `
  --name Az400Feed

# ソースが追加されたことを確認
dotnet nuget list source
```

**⚠️ 代替方法：PAT を直接指定（非推奨）**

```powershell
# PAT を直接指定する場合（your-PAT はプレースホルダー：実際の Personal Access Token に置き換える）
dotnet nuget add source `
  https://pkgs.dev.azure.com/bell999/_packaging/az400-handson3-package-feed/nuget/v3/index.json `
  --name Az400Feed `
  --username any `
  --password your-PAT `
  --store-password-in-clear-text

# 📌 PAT を Azure Key Vault に保存している場合の取得例
$pat = az keyvault secret show --vault-name your-keyvault-name --name AzureDevOpsPAT --query value -o tsv
dotnet nuget add source `
  https://pkgs.dev.azure.com/bell999/_packaging/az400-handson3-package-feed/nuget/v3/index.json `
  --name Az400Feed `
  --username any `
  --password $pat `
  --store-password-in-clear-text
```

**💡 重要:** Exercise 3.1 で Credential Provider をインストール済みなので、`--password` オプションは不要です。

#### 3.3 パッケージの発行

```powershell
# Az400.Utils プロジェクトディレクトリから発行
Set-Location C:\Users\bell9\github\az400-handson3-lab2\Az400.Utils

# パッケージを Azure Artifacts に発行
dotnet nuget push `
  bin\Release\Az400.Utils.1.0.0.nupkg `
  --source Az400Feed `
  --api-key az
```

#### 3.4 発行の確認

1. Azure DevOps → Artifacts → Feed を開く
2. `Az400.Utils` パッケージが表示されることを確認
3. Version: `1.0.0`
4. View: `@Local` に配置されていることを確認

### Exercise 4: Views の管理

#### 4.1 Prerelease View への昇格

1. パッケージ `Az400.Utils` をクリック
2. 「Promote」ボタンをクリック
3. View: `@Prerelease` を選択
4. 「Promote」をクリック

#### 4.2 Release View への昇格

1. 再度「Promote」ボタンをクリック
2. View: `@Release` を選択
3. 「Promote」をクリック

#### 4.3 Views の使い分け（試験重要）

| View | 用途 | 例 |
|------|------|-----|
| @Local | すべてのパッケージ | 開発中のすべてのバージョン |
| @Prerelease | プレリリース版 | ベータテスト用（1.0.0-beta） |
| @Release | 正式リリース版 | 本番環境で使用（1.0.0） |

### Exercise 5: パッケージの利用

#### 5.1 新しいコンソールアプリの作成

```powershell
# 本リポジトリのルートディレクトリに移動
Set-Location C:\Users\bell9\github\az400-handson3-lab2

# コンソールアプリを作成
dotnet new console -n Az400.Consumer

# プロジェクトディレクトリに移動
Set-Location Az400.Consumer

# ソリューションに追加
Set-Location ..
dotnet sln WebApp.slnx add Az400.Consumer\Az400.Consumer.csproj
```

#### 5.2 パッケージの追加

```powershell
# Az400.Consumer プロジェクトディレクトリに移動
Set-Location C:\Users\bell9\github\az400-handson3-lab2\Az400.Consumer

# Azure Artifacts からパッケージをインストール（Feed URL を直接指定）
dotnet add package Az400.Utils --version 1.0.0 --source https://pkgs.dev.azure.com/bell999/az400-handson3/_packaging/az400-handson3-package-feed/nuget/v3/index.json

# または、登録済みソース名を使用（プロジェクトディレクトリで実行）
# dotnet add package Az400.Utils --version 1.0.0 --source Az400Feed
```

#### 5.3 パッケージの使用

`Program.cs` を編集：

```csharp
using Az400.Utils;

Console.WriteLine("=== Az400.Utils パッケージのテスト ===");

// 文字列の逆順
string original = "Hello, AZ-400!";
string reversed = StringHelper.Reverse(original);
Console.WriteLine($"Original: {original}");
Console.WriteLine($"Reversed: {reversed}");

// 回文チェック
string[] words = { "racecar", "hello", "level", "world" };
foreach (var word in words)
{
    bool isPalindrome = StringHelper.IsPalindrome(word);
    Console.WriteLine($"{word} is palindrome: {isPalindrome}");
}
```

#### 5.4 実行

```powershell
# ビルドして実行
dotnet build
dotnet run

# 期待される出力:
# === Az400.Utils パッケージのテスト ===
# Original: Hello, AZ-400!
# Reversed: !004-ZA ,olleH
# racecar is palindrome: True
# hello is palindrome: False
# level is palindrome: True
# world is palindrome: False
```

### Exercise 6: パイプラインでのパッケージ発行

#### 6.0 プロジェクト名とフィード名の確認

パイプラインで `publishVstsFeed` を設定する前に、正しい値を確認します:

**方法1: NuGet ソースから確認**
```powershell
dotnet nuget list source
```

出力例:
```
https://pkgs.dev.azure.com/bell999/az400-handson3/_packaging/az400-handson3-package-feed/nuget/v3/index.json
                                └─組織名──┘ └──プロジェクト名──┘          └────────────フィード名──────────────┘
```

**方法2: Azure DevOps UI で確認**
1. Azure DevOps → Artifacts → Feed を開く
2. Feed 設定 (⚙️) → Connect to feed → dotnet
3. XML の `value` 属性から確認

**publishVstsFeed の形式**: `{プロジェクト名}/{フィード名}`

例: `az400-handson3/az400-handson3-package-feed`

#### 6.1 パイプライン YAML の作成

リポジトリのルートに `azure-pipelines-package.yml` を作成：

```powershell
# リポジトリのルートに移動
Set-Location C:\Users\bell9\github\az400-handson3-lab2

# YAMLファイルを作成（次のセクションの内容を使用）
New-Item -ItemType File -Name azure-pipelines-package.yml
```

`azure-pipelines-package.yml` の内容：

```yaml
# azure-pipelines-package.yml
trigger:
  branches:
    include:
    - main
  tags:
    include:
    - v*

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'
  packageVersion: '1.0.$(Build.BuildId)'

stages:
- stage: Build
  displayName: 'Build and Pack'
  jobs:
  - job: BuildJob
    steps:
    - task: UseDotNet@2
      displayName: 'Use .NET 8.0'
      inputs:
        version: '8.0.x'
    
    # Azure Artifacts への認証
    - task: NuGetAuthenticate@1
      displayName: 'Authenticate to Azure Artifacts'
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'
        feedsToUse: 'select'
        vstsFeed: 'az400-handson3/az400-handson3-package-feed'
    
    - task: DotNetCoreCLI@2
      displayName: 'Build'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-restore'
    
    # パッケージを作成
    - task: DotNetCoreCLI@2
      displayName: 'Pack NuGet Package'
      inputs:
        command: 'pack'
        packagesToPack: '**/Az400.Utils.csproj'
        versioningScheme: 'byEnvVar'
        versionEnvVar: 'packageVersion'
        configuration: '$(buildConfiguration)'
    
    # Azure Artifacts に発行
    - task: NuGetCommand@2
      displayName: 'Push to Azure Artifacts'
      inputs:
        command: 'push'
        packagesToPush: '$(Build.ArtifactStagingDirectory)/**/*.nupkg'
        publishVstsFeed: 'az400-handson3/az400-handson3-package-feed'
        allowPackageConflicts: false
```

#### 6.2 作成したファイルをリポジトリに反映

```powershell
# リポジトリのルートに移動
Set-Location C:\Users\bell9\github\az400-handson3-lab2

# .gitignore に追加（既に実施済みの場合はスキップ）
Add-Content .gitignore "`n# Azure Artifacts projects`nAz400.Utils/bin/`nAz400.Utils/obj/`nAz400.Consumer/bin/`nAz400.Consumer/obj/`n*.nupkg"

# 変更をステージング
git add Az400.Utils/ Az400.Consumer/ azure-pipelines-package.yml WebApp.slnx .gitignore

# コミット
git commit -m "Add Azure Artifacts projects (Az400.Utils, Az400.Consumer) and package pipeline"

# プッシュ（ブランチポリシーがある場合は feature ブランチを使用）
git checkout -b feature/add-artifacts-projects
git push origin feature/add-artifacts-projects

# プルリクエストを作成
```

#### 6.2.1 Key Vault の PAT を使用した Azure CLI 認証

Azure CLI でプルリクエストを作成する際に認証エラーが出る場合、Key Vault に格納した PAT を使用します:

**前提条件: Key Vault とシークレットの確認**

```powershell
# Key Vault の一覧を確認
az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table

# シークレットの一覧を確認
az keyvault secret list --vault-name kv-az400-bell9 --query "[].name" -o table
```

**プルリクエスト作成手順:**

```powershell
# 1. Key Vault から PAT を取得
$retrievedPat = az keyvault secret show `
  --vault-name kv-az400-bell9 `
  --name azure-devops-pat `
  --query value `
  -o tsv

# 2. 環境変数に設定（Azure DevOps CLI 拡張機能が使用）
$env:AZURE_DEVOPS_EXT_PAT = $retrievedPat

# 3. プルリクエスト作成コマンドを実行
az repos pr create `
  --source-branch feature/add-artifacts-projects `
  --target-branch main `
  --title "Fix: Add Azure Artifacts feed authentication to all pipelines" `
  --description "Azure Artifacts からの NuGet パッケージ復元エラー (NU1101) を修正。すべてのパイプラインに NuGetAuthenticate タスクと feedsToUse/vstsFeed を追加。" `
  --repository az400-handson3-lab2-pipeline `
  --project az400-handson3

# 4. セキュリティのため、使用後は環境変数をクリア
Remove-Item Env:\AZURE_DEVOPS_EXT_PAT
```

**📝 環境固有の値:**
- Key Vault 名: `kv-az400-bell9`（環境に応じて変更）
- シークレット名: `azure-devops-pat`（Exercise 2.3 で作成した名前）
- リソースグループ: `rg-az400-handson3`
- リポジトリ名: `az400-handson3-lab2-pipeline`
- プロジェクト名: `az400-handson3`

**⚠️ セキュリティ注意事項:**
- `$env:AZURE_DEVOPS_EXT_PAT` は現在の PowerShell セッションのみで有効
- PAT は機密情報なので画面に表示しない（`-o tsv` で値のみ取得）
- 使用後は必ず環境変数をクリア (`Remove-Item Env:\AZURE_DEVOPS_EXT_PAT`)
- コマンド履歴に残る可能性があるため、機密操作後はセッションを閉じる

**よくあるエラーと対処法:**

| エラー | 原因 | 解決方法 |
|--------|------|----------|
| `insufficient permissions` | PAT が設定されていない | 上記手順で環境変数を設定 |
| `user authentication` | PAT の権限が不足 | Code (Read & Write) 権限を確認 |
| `個人アカウントでサインインできません` | 組織アカウントが必要 | PAT を使用（上記手順） |
| `Failed to resolve` | Key Vault が存在しない | Key Vault 名を確認、または Exercise 2.3 で作成 |
| `Secret not found` | シークレット名が違う | `az keyvault secret list` で確認 |

---

#### 6.2.2 Azure DevOps UI でプルリクエストを作成

**方法A: プッシュ後に表示される URL を使用**

1. ターミナルに表示された URL をクリック（プッシュ後に表示される）
   ```
   remote: Create a pull request for 'feature/add-artifacts-projects' on Azure DevOps by visiting:
   remote:      https://dev.azure.com/bell999/az400-handson3/_git/az400-handson3-lab2-pipeline/pullrequestcreate?sourceRef=feature/add-artifacts-projects
   ```

**方法B: Azure DevOps で手動作成**

1. Azure DevOps で手動作成:
   - Azure DevOps → Repos → Pull requests
   - 「New pull request」をクリック
   - Source branch: `feature/add-artifacts-projects`
   - Target branch: `main`
   - Title: `Add Azure Artifacts projects and package pipeline`
   - Description: 以下を入力
     ```
     ## 変更内容
     - Az400.Utils クラスライブラリを追加（StringHelper）
     - Az400.Consumer コンソールアプリを追加
     - azure-pipelines-package.yml パイプラインを追加
     - .gitignore にビルド成果物を追加
     
     ## 確認事項
     - [ ] Az400.Utils のビルドが成功すること
     - [ ] Az400.Consumer でパッケージが利用できること
     - [ ] パイプライン YAML が正しく構成されていること
     ```
   - 「Create」をクリック

2. レビュー後にマージ:
   - 「Approve」をクリック
   - 「Complete」→ 「Complete merge」をクリック
   - Merge type: `Merge (no fast-forward)` を選択
   - 「Complete merge」をクリック

---

#### 6.2.3 プルリクエストをスキップ（ブランチポリシーがない場合のみ）

```powershell
# main ブランチに直接プッシュ（ブランチポリシーがない場合のみ）
git checkout main
git merge feature/add-artifacts-projects
git push origin main
```



#### 6.3 Azure DevOps でパイプラインを作成

1. Azure DevOps → Pipelines → 「New pipeline」
2. Azure Repos Git → リポジトリ選択
3. Existing Azure Pipelines YAML file
4. Path: `/azure-pipelines-package.yml`
5. 「Run」をクリック

#### 6.4 パイプライン実行の確認

- ✅ ビルドが成功すること
- ✅ パッケージが作成されること
- ✅ Azure Artifacts Feed にパッケージが発行されること

#### 6.5 トラブルシューティング: Az400.Utils パッケージが見つからないエラー

**エラー例:**
```
error NU1101: Unable to find package Az400.Utils. No packages exist with this id in source(s): NuGetOrg
```

**原因:**
- パイプラインが Azure Artifacts Feed を参照していない
- Restore タスクが公開の nuget.org のみを使用している

**解決方法:**

`azure-pipelines-package.yml` に以下の修正を適用：

1. **NuGetAuthenticate タスクを追加**（Restore の前）
2. **Restore タスクに Feed を指定**

```yaml
    - task: UseDotNet@2
      displayName: 'Use .NET 8.0'
      inputs:
        version: '8.0.x'
    
    # Azure Artifacts への認証（追加）
    - task: NuGetAuthenticate@1
      displayName: 'Authenticate to Azure Artifacts'
    
    - task: DotNetCoreCLI@2
      displayName: 'Restore'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'
        feedsToUse: 'select'                              # ← 追加
        vstsFeed: 'az400-handson3/az400-handson3-package-feed'  # ← 追加
    
    - task: DotNetCoreCLI@2
      displayName: 'Build'
      inputs:
        command: 'build'
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration) --no-restore'  # ← --no-restore 追加
```

**ポイント:**
- `NuGetAuthenticate@1`: Azure Artifacts への認証を自動的に処理
- `feedsToUse: 'select'`: カスタム Feed を使用
- `vstsFeed`: プロジェクト名/フィード名の形式で指定
- `--no-restore`: Restore 後の Build で不要な復元を防ぐ

### Exercise 7: Azure SQL の BACPAC と DACPAC（試験重要）

> ⚠️ **注意**: この Exercise は**オプション（試験知識の確認用）**です。
> 既存の Azure SQL Database がない場合は、以下の選択肢があります：
> 
> **選択肢 1: この Exercise をスキップ**
> - BACPAC/DACPAC の違いと使用方法を理解していれば OK
> - 試験では概念と用途の違いが問われます
> 
> **選択肢 2: サンプル DB を作成して実習**
> - [Exercise 7.0](#70-サンプル-azure-sql-database-の作成オプション) を参照
> - 無料枠/評価版で作成可能（Basic tier: 約 ¥500/月）
> 
> **選択肢 3: ローカル SQL Server で代替**
> - SQL Server Express（無料）をインストール
> - SqlPackage.exe でローカル DB から DACPAC を作成

#### 7.0 サンプル Azure SQL Database の作成（オプション）

既存の Azure SQL Database がない場合、以下のコマンドでサンプル DB を作成できます：

```powershell
# 変数定義
$resourceGroup = "rg-az400-handson3"
$location = "japaneast"
$serverName = "sql-az400-handson3-$env:USERNAME"  # グローバルで一意な名前
$databaseName = "sampledb"
$adminUser = "sqladmin"
$adminPassword = "P@ssw0rd1234!"  # 本番環境では Key Vault を使用

# 1. Azure SQL Server を作成（サーバーがない場合）
az sql server create `
  --resource-group $resourceGroup `
  --name $serverName `
  --location $location `
  --admin-user $adminUser `
  --admin-password $adminPassword

# 2. ファイアウォールルールを追加（自分のIPアドレスを許可）
az sql server firewall-rule create `
  --resource-group $resourceGroup `
  --server $serverName `
  --name AllowMyIP `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0  # Azure CLIが自動的に現在のIPを設定

# 3. サンプルデータベースを作成（Basic tier: 最小コスト）
az sql db create `
  --resource-group $resourceGroup `
  --server $serverName `
  --name $databaseName `
  --service-objective Basic `
  --sample-name AdventureWorksLT  # サンプルデータを含むDB

Write-Host "✅ サンプル DB 作成完了: $serverName.database.windows.net/$databaseName"
Write-Host "💰 コスト: Basic tier 約 ¥500/月（使用後は削除推奨）"
```

**使用後のクリーンアップ（重要）**:
```powershell
# データベースを削除（課金を停止）
az sql db delete `
  --resource-group $resourceGroup `
  --server $serverName `
  --name $databaseName `
  --yes

# サーバー全体を削除する場合
az sql server delete `
  --resource-group $resourceGroup `
  --name $serverName `
  --yes
```

#### 7.1 BACPAC と DACPAC の違い

| 項目 | BACPAC | DACPAC |
|------|--------|--------|
| 含まれる内容 | **schema + data** | **schema のみ** |
| 用途 | データベース移行 | スキーマのデプロイ |
| ファイル拡張子 | `.bacpac` | `.dacpac` |
| 作成コマンド | `SqlPackage.exe /a:Export` | `SqlPackage.exe /a:Extract` |
| 復元コマンド | `SqlPackage.exe /a:Import` | `SqlPackage.exe /a:Publish` |

#### 7.2 BACPAC のエクスポート（Azure CLI）

> 💡 **前提条件**: Azure SQL Database が必要です。ない場合は [Exercise 7.0](#70-サンプル-azure-sql-database-の作成オプション) を参照してください。

```powershell
# ストレージアカウントがない場合は作成
$storageAccountName = "staz400$env:USERNAME"  # 小文字・数字のみ、グローバルで一意
az storage account create `
  --name $storageAccountName `
  --resource-group rg-az400-handson3 `
  --location japaneast `
  --sku Standard_LRS

# ストレージアカウントキーを取得
$storageKey = az storage account keys list `
  --resource-group rg-az400-handson3 `
  --account-name $storageAccountName `
  --query "[0].value" `
  -o tsv

# Blob コンテナを作成
az storage container create `
  --name bacpac `
  --account-name $storageAccountName `
  --account-key $storageKey

# Azure SQL Database から BACPAC をエクスポート
az sql db export `
  --resource-group rg-az400-handson3 `
  --server sql-az400-handson3-$env:USERNAME `
  --name sampledb `
  --admin-user sqladmin `
  --admin-password "P@ssw0rd1234!" `
  --storage-key-type StorageAccessKey `
  --storage-key $storageKey `
  --storage-uri "https://$storageAccountName.blob.core.windows.net/bacpac/sampledb.bacpac"

Write-Host "✅ BACPAC エクスポート完了"
Write-Host "📦 ファイル: https://$storageAccountName.blob.core.windows.net/bacpac/sampledb.bacpac"
```

**エクスポート後の確認**:
```powershell
# BACPAC ファイルの存在確認
az storage blob list `
  --container-name bacpac `
  --account-name $storageAccountName `
  --account-key $storageKey `
  --output table
```

#### 7.3 DACPAC の作成（SqlPackage.exe）

> 💡 **前提条件**: 
> - SqlPackage.exe が必要です（[Azure Data Studio](https://learn.microsoft.com/ja-jp/azure-data-studio/download-azure-data-studio) または [SQL Server Data Tools](https://learn.microsoft.com/ja-jp/sql/ssdt/download-sql-server-data-tools-ssdt) に含まれます）
> - Azure SQL Database または ローカル SQL Server が必要です

```powershell
# DACPAC をエクスポート（スキーマのみ）
SqlPackage.exe /a:Extract `
  /ssn:sql-az400-handson3-$env:USERNAME.database.windows.net `
  /sdn:sampledb `
  /su:sqladmin `
  /sp:"P@ssw0rd1234!" `
  /tf:sampledb.dacpac

Write-Host "✅ DACPAC エクスポート完了: sampledb.dacpac"
```

**代替方法: Azure Data Studio を使用**:
1. Azure Data Studio を開く
2. サーバーに接続: `sql-az400-handson3-<username>.database.windows.net`
3. データベース `sampledb` を右クリック → 「データ層アプリケーションの抽出」
4. `.dacpac` ファイルを保存

**SqlPackage.exe のパス確認**:
```powershell
# SqlPackage.exe の場所を確認（Azure Data Studio インストール済みの場合）
$sqlPackagePath = Get-ChildItem -Path "$env:LOCALAPPDATA\Programs\Azure Data Studio" -Filter "SqlPackage.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
if ($sqlPackagePath) {
    Write-Host "✅ SqlPackage.exe: $sqlPackagePath"
} else {
    Write-Host "❌ SqlPackage.exe が見つかりません。Azure Data Studio または SSDT をインストールしてください。"
}
```

#### 7.4 ユースケース

**BACPAC を使用する場合:**
- 開発環境から本番環境へのデータ移行
- データベースのバックアップ
- データを含むテスト環境の構築

**DACPAC を使用する場合:**
- CI/CD パイプラインでのスキーマデプロイ
- データベーススキーマのバージョン管理
- スキーマの変更を追跡

### Exercise 8: Upstream Sources の活用

#### 8.1 Upstream Source の確認

**前提条件: Upstream Sources の有効化**

1. Azure DevOps → Artifacts → Feed Settings を開く
   ```
   https://dev.azure.com/bell999/az400-handson3/_artifacts/feed/az400-handson3-package-feed/settings/upstreams
   ```
2. 「**Upstream sources**」タブを開く
3. **nuget.org** が有効になっているか確認
   - ✅ 有効な場合: "nuget.org" が一覧に表示される
   - ❌ 無効な場合: 以下の手順で追加
4. Upstream Sources を追加（無効な場合のみ）:
   - **Add upstream source** をクリック
   - **Public source** を選択
   - **nuget.org** を選択
   - **Add** をクリック

**デフォルトで有効な Upstream Sources**:
- nuget.org (NuGet パッケージ)
- npmjs.com (npm パッケージ)
- PyPI (Python パッケージ)

> 💡 **注意**: Feed 作成時に Upstream Sources が自動的に有効化されますが、手動で無効化されている場合は再度有効化が必要です。

#### 8.2 動作確認

> ⚠️ **重要**: [Exercise 8.1](#81-upstream-source-の確認) で Upstream Sources が有効になっていることを確認してください。

**Upstream Sources の仕組み**:
- Azure Artifacts が nuget.org からパッケージをキャッシュするには、**Feed を明示的に指定**する必要があります
- `--source` オプションを指定せずに実行すると、nuget.org から直接ダウンロードされ、Feed にキャッシュされません

```powershell
# Az400.Consumer プロジェクトに移動
cd C:\Users\bell9\github\az400-handson3-lab2\Az400.Consumer

# ✅ 正しい方法: Azure Artifacts Feed を明示的に指定
# Upstream Sources 経由で nuget.org からダウンロードされ、Feed にキャッシュされる
dotnet add package Newtonsoft.Json `
  --source https://pkgs.dev.azure.com/bell999/az400-handson3/_packaging/az400-handson3-package-feed/nuget/v3/index.json

# または、名前付きソースを使用（事前に登録済みの場合）
dotnet nuget add source `
  https://pkgs.dev.azure.com/bell999/az400-handson3/_packaging/az400-handson3-package-feed/nuget/v3/index.json `
  --name Az400FeedOnly

dotnet add package Newtonsoft.Json --source Az400FeedOnly

# ❌ 間違った方法: --source を指定しない
# → nuget.org から直接ダウンロードされ、Feed にキャッシュされない
# dotnet add package Newtonsoft.Json

# インストール成功を確認
dotnet list package
```

**Azure Artifacts で Upstream パッケージを検索・保存**:

> 💡 **重要**: Upstream Sources からダウンロードしたパッケージは、**自動的には Feed に表示されません**。明示的に検索して保存する必要があります。

1. Azure DevOps → Artifacts → Feed を開く
   ```
   https://dev.azure.com/bell999/az400-handson3/_artifacts/feed/az400-handson3-package-feed
   ```

2. ページ上部の **"Search upstream sources"** ボタンをクリック

3. ドロップダウンから **"NuGet"** を選択

4. 検索ボックスに **"Newtonsoft.Json"** を入力して検索

5. 検索結果から **Newtonsoft.Json** パッケージを選択
   - パッケージ詳細ページが開く
   - Source: **"nuget.org"** と表示される
   - 利用可能なバージョン一覧が表示される

6. **Upstream パッケージを Feed に保存する**（推奨）:
   - バージョン一覧の右端にある **三点メニュー（...）** をクリック
   - **"Save to feed"** を選択
   - パッケージが Feed に永続的に保存される
   - **@Local View** に移動すると、保存したパッケージが表示される

7. **@Local View で確認**:
   - Feed ページに戻る
   - View ドロップダウンで **@Local** を選択
   - **Az400.Utils** と **Newtonsoft.Json** の両方が表示される ✅

**View フィルタの説明**:
| View | 説明 | 表示されるパッケージ |
|------|------|----------------------|
| **@Local** | Feed に直接公開または保存されたパッケージ | ✅ Az400.Utils（直接公開）<br>✅ Newtonsoft.Json（Upstream から保存） |
| **@Prerelease** | プレリリース版のみ | バージョンに `-preview` などが含まれるパッケージ |
| **@Release** | リリース版のみ | 安定版のみ（デフォルト） |

> 📝 **Upstream パッケージの動作**:
> - `dotnet restore` で Upstream Sources 経由でダウンロードしただけでは、**Feed の一覧に表示されません**
> - **"Search upstream sources"** で検索すると、Upstream からパッケージを確認できます
> - 三点メニュー（...）→ **"Save to feed"** を実行すると、**@Local View に表示されます** ✅
> - 保存されたパッケージは、Feed に永続的にキャッシュされます
> - チーム全体で同じパッケージバージョンを使用でき、外部ソース（nuget.org）が利用できない場合でも復元可能になります

**トラブルシューティング**:
| エラー/問題 | 原因 | 解決策 |
|--------|------|--------|
| `パッケージに使用できるバージョンがありません` | Upstream Sources が無効 | [Exercise 8.1](#81-upstream-source-の確認) で nuget.org を有効化 |
| Feed に Upstream パッケージが表示されない | 自動的には表示されない仕様 | **"Search upstream sources"** ボタンで検索 |
| Feed にパッケージが表示されない | Feed を経由せずにインストール | `dotnet remove package Newtonsoft.Json` → Feed URL を明示的に指定して再インストール |
| 認証エラー | Azure Artifacts の認証が切れている | `dotnet nuget list source` で認証状態を確認 |

#### 8.3 Upstream Sources の利点

**Upstream Sources を使用することで、以下の利点が得られます**：

1. **パッケージの高速ダウンロード（キャッシュ）**
   - 一度 "Save to feed" したパッケージは、Feed に永続的にキャッシュされる
   - チームメンバー全員が同じキャッシュからダウンロードするため、高速化される
   - 外部ソース（nuget.org）へのアクセスが減り、ネットワーク負荷が軽減される

2. **外部パッケージの可用性向上**
   - nuget.org がダウンしても、Feed にキャッシュされたパッケージは利用可能
   - ネットワークが制限されている環境でも、一度保存すれば使用できる
   - CI/CD パイプラインの安定性が向上する

3. **パッケージのバージョン固定と管理**
   - "Save to feed" で保存したバージョンは、Feed から削除されない限り利用可能
   - チーム全体で同じバージョンを使用することを保証できる
   - 外部ソースからパッケージが削除されても、Feed に保存されていれば継続使用可能

4. **セキュリティとコンプライアンス**
   - Feed に保存されたパッケージは、組織の管理下に置かれる
   - パッケージの使用状況を追跡できる
   - 承認されたパッケージのみを使用するポリシーを適用できる

**まとめ**: "Save to feed" により、外部パッケージを組織の Feed に取り込み、安定性・セキュリティ・パフォーマンスを向上させることができます。

### Exercise 9: リポジトリの最終構成確認

#### 9.1 作成されたファイルの確認

```powershell
# リポジトリのルートに移動
Set-Location C:\Users\bell9\github\az400-handson3-lab2

# ディレクトリ構造を確認
Get-ChildItem -Recurse -Directory | Where-Object { $_.Name -notmatch '^(bin|obj|\.git)$' } | Select-Object FullName
```

#### 9.2 ソリューションの確認

```powershell
# ソリューションに含まれるプロジェクトを確認
dotnet sln WebApp.slnx list

# 期待される出力:
# WebApp\WebApp.csproj
# WebApp.Tests\WebApp.Tests.csproj
# Az400.Utils\Az400.Utils.csproj
# Az400.Consumer\Az400.Consumer.csproj
```

#### 9.3 最終的なリポジトリ構成

```
az400-handson3-lab2/
├── .git/
├── .github/
│   └── copilot-instructions.md
├── docs/
│   ├── handson/
│   │   ├── 02-Azure-Pipelines-基礎.md
│   │   └── 03-Azure-Artifacts-パッケージ管理.md
├── WebApp/                          # Lab 2: Web API プロジェクト
│   ├── Program.cs
│   └── WebApp.csproj
├── WebApp.Tests/                    # Lab 2: テストプロジェクト
│   └── WebApp.Tests.csproj
├── Az400.Utils/                     # ✅ Lab 3: クラスライブラリ
│   ├── StringHelper.cs
│   └── Az400.Utils.csproj
├── Az400.Consumer/                  # ✅ Lab 3: コンソールアプリ
│   ├── Program.cs
│   └── Az400.Consumer.csproj
├── pipelines/
│   └── templates/
│       ├── build-template.yml
│       └── base-pipeline.yml
├── azure-pipelines.yml              # Lab 2: メインパイプライン
├── azure-pipelines-package.yml      # ✅ Lab 3: パッケージ発行パイプライン
├── azure-pipelines-use-template.yml
├── azure-pipelines-extends.yml
├── WebApp.slnx                      # ソリューションファイル
└── .gitignore
```

## 📊 演習のまとめ

### Feed 作成から利用までのフロー

```
1. Feed 作成
   ↓
2. パッケージをビルド (dotnet pack)
   ↓
3. パッケージを発行 (dotnet nuget push)
   ↓
4. Views で管理 (@Local → @Prerelease → @Release)
   ↓
5. 他のプロジェクトで利用 (dotnet add package)
```

### Views の昇格パス

```
@Local (すべて)
  ↓ Promote
@Prerelease (プレリリース)
  ↓ Promote
@Release (正式版)
```

## ✅ 確認問題

### Q1: データとスキーマの両方を含むSQL Server移行ファイル形式は？
- [ ] A. DACPAC
- [ ] B. BACPAC
- [ ] C. MDF
- [ ] D. LDF

<details>
<summary>解答</summary>

**正解: B**

説明:
- BACPAC: schema + data（データベース移行用）
- DACPAC: schema only（スキーマのみ）
- MDF/LDF: SQL Server のデータファイル
</details>

### Q2: Azure Artifacts で正式リリース版を管理するViewは？
- [ ] A. @Local
- [ ] B. @Prerelease
- [ ] C. @Release
- [ ] D. @Production

<details>
<summary>解答</summary>

**正解: C**

説明:
- @Local: すべてのパッケージ
- @Prerelease: プレリリース版
- @Release: 正式リリース版
</details>

### Q3: NuGet パッケージを Azure Artifacts に発行するコマンドは？
- [ ] A. dotnet publish
- [ ] B. dotnet nuget push
- [ ] C. dotnet pack
- [ ] D. dotnet deploy

<details>
<summary>解答</summary>

**正解: B**

説明:
- `dotnet pack`: パッケージを作成（.nupkg）
- `dotnet nuget push`: パッケージを Feed に発行
</details>

## 🔍 トラブルシューティング

### パッケージの発行に失敗
```powershell
# 認証エラーの場合
# PAT を再作成して環境変数を設定

# Feed の権限を確認
# Feed Settings → Permissions → 自分が Contributor 以上か確認
```

### パッケージが見つからない
```powershell
# NuGet ソースを確認
dotnet nuget list source

# ソースを削除して再追加
dotnet nuget remove source Az400Feed
dotnet nuget add source {feed-url} --name Az400Feed
```

## 📚 参考リンク
- [Azure Artifacts ドキュメント](https://learn.microsoft.com/azure/devops/artifacts/)
- [NuGet パッケージの作成](https://learn.microsoft.com/nuget/create-packages/creating-a-package)
- [SqlPackage.exe](https://learn.microsoft.com/sql/tools/sqlpackage/)
- [BACPAC と DACPAC](https://learn.microsoft.com/sql/relational-databases/data-tier-applications/data-tier-applications)

## ➡️ 次のステップ
Lab 3 が完了したら、[Lab 4: セキュリティとコンプライアンス](./04-セキュリティとコンプライアンス.md) に進んでください。

---

**Fantastic! You've mastered Azure Artifacts! 📦**
