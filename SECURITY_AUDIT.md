# セキュリティ監査レポート
**実施日時**: 2026年5月18日  
**対象リポジトリ**: az400-handson3-final  
**監査基準**: AZ-400 DevOps セキュリティベストプラクティス

---

## ✅ 合格項目（Good Practices）

### 1. シークレット管理
- ✅ **ハードコードされたシークレットなし**: コード内にパスワード、APIキー、接続文字列のハードコードなし
- ✅ **Azure Key Vault 使用**: Application Insights 接続文字列を Key Vault で管理
- ✅ **Managed Identity**: VM が Managed Identity で Key Vault と Application Insights にアクセス
- ✅ **環境変数**: 接続文字列を環境変数 `APPLICATIONINSIGHTS_CONNECTION_STRING` で管理
- ✅ **.gitignore 設定**: 秘密情報ファイル（.env, *.key, secrets.json など）を除外

### 2. 認証・認可
- ✅ **RBAC 使用**: Azure RBAC でロールベースのアクセス制御
  - Key Vault: "Key Vault Secrets User" ロール（VM用）、"Key Vault Secrets Officer" ロール（管理者用）
  - Application Insights: "Monitoring Reader" ロール（VM用）
- ✅ **SSH キー認証**: パスワード認証ではなく公開鍵認証を使用
- ✅ **Service Connection**: Azure DevOps で SSH Service Connection を使用（秘密鍵は Azure DevOps で安全に管理）

### 3. パイプラインセキュリティ
- ✅ **セキュリティステージ**: 脆弱性スキャンステージを実装
- ✅ **成果物管理**: ビルド成果物を PublishBuildArtifacts タスクで管理
- ✅ **承認プロセス**: Pull Request ベースのワークフロー
- ✅ **ブランチ保護**: main ブランチへの直接コミット防止（PR 必須）

### 4. コード品質
- ✅ **SQL インジェクション対策**: Entity Framework Core の In-Memory Database を使用（パラメータ化クエリ）
- ✅ **ロギング**: ILogger を使用した適切なログ記録
- ✅ **テレメトリ**: Application Insights で監視

### 5. 依存関係管理
- ✅ **Package Lock Files**: `RestorePackagesWithLockFile=true` で再現性のあるビルド
- ✅ **脆弱性スキャン**: Azure Pipeline でパッケージの脆弱性をスキャン

---

## ⚠️ 改善推奨項目（Recommendations）

### 🔴 高優先度（Critical）

#### 1. **NuGet パッケージの脆弱性**
**問題**: `Microsoft.Extensions.Caching.Memory 8.0.0` に **High severity** の脆弱性
```
推移的なパッケージ: Microsoft.Extensions.Caching.Memory 8.0.0
重要度: High
アドバイザリ URL: https://github.com/advisories/GHSA-qj66-m88j-hmgj
```

**対策**:
```powershell
# .NET 8.0 の最新パッチバージョンに更新
cd backend
dotnet add package Microsoft.EntityFrameworkCore.InMemory --version 8.0.11
dotnet restore
```

**理由**: この脆弱性は DoS (Denial of Service) 攻撃のリスクがあります。

---

#### 2. **Azure Pipeline の脆弱性スキャン強化**
**問題**: 現在のスキャンは推移的な依存関係を含んでいない

**現在の設定**:
```yaml
- script: |
    dotnet list backend/backend.csproj package --vulnerable
```

**推奨設定**:
```yaml
- script: |
    echo "Running security vulnerability scan..."
    dotnet list backend/backend.csproj package --vulnerable --include-transitive
    # 脆弱性が見つかった場合はビルドを失敗させる
    if dotnet list backend/backend.csproj package --vulnerable --include-transitive | grep -q "has the following vulnerable packages"; then
      echo "##vso[task.logissue type=error]Vulnerable packages detected!"
      exit 1
    fi
  displayName: 'Vulnerability Scan'
```

---

### 🟡 中優先度（Important）

#### 3. **CORS ポリシーの制限**
**問題**: AllowAnyOrigin() は本番環境では危険

**現在の設定** (backend/Program.cs):
```csharp
policy.AllowAnyOrigin()
      .AllowAnyMethod()
      .AllowAnyHeader();
```

**推奨設定**:
```csharp
// 環境に応じて CORS を設定
if (app.Environment.IsDevelopment())
{
    policy.AllowAnyOrigin()
          .AllowAnyMethod()
          .AllowAnyHeader();
}
else
{
    // 本番環境では特定のオリジンのみ許可
    policy.WithOrigins("https://yourdomain.com")
          .AllowAnyMethod()
          .AllowAnyHeader()
          .AllowCredentials();
}
```

---

#### 4. **入力検証の強化**
**問題**: UsersController でバリデーション属性が不足

**推奨**: User モデルにデータアノテーションを追加

**backend/Models/User.cs**:
```csharp
using System.ComponentModel.DataAnnotations;

namespace backend.Models;

public class User
{
    public int Id { get; set; }
    
    [Required(ErrorMessage = "ユーザー名は必須です")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "ユーザー名は3〜50文字で入力してください")]
    public required string Username { get; set; }
    
    [Required(ErrorMessage = "メールアドレスは必須です")]
    [EmailAddress(ErrorMessage = "有効なメールアドレスを入力してください")]
    public required string Email { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

**UsersController.cs** に ModelState チェックを追加:
```csharp
[HttpPost]
public ActionResult<User> CreateUser(User user)
{
    if (!ModelState.IsValid)
    {
        _logger.LogWarning("Invalid user data received");
        return BadRequest(ModelState);
    }
    
    _telemetryClient.TrackEvent("CreateUser");
    _logger.LogInformation("Creating new user: {Username}", user.Username);

    _context.Users.Add(user);
    _context.SaveChanges();

    return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
}
```

---

#### 5. **HTTPS 強制（本番環境）**
**問題**: VM では HTTP (5000番ポート) のみで動作

**推奨**:
- 本番環境では HTTPS を強制
- Let's Encrypt などで SSL/TLS 証明書を取得
- Nginx や Caddy をリバースプロキシとして使用

**nginx 設定例**:
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

#### 6. **Rate Limiting の実装**
**問題**: DDoS 攻撃やブルートフォース攻撃への対策なし

**推奨**: ASP.NET Core Rate Limiting ミドルウェアを追加

```csharp
// backend/Program.cs
using System.Threading.RateLimiting;

builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("fixed", options =>
    {
        options.PermitLimit = 100;
        options.Window = TimeSpan.FromMinutes(1);
        options.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        options.QueueLimit = 5;
    });
});

// ...

app.UseRateLimiter();
```

---

### 🟢 低優先度（Nice to Have）

#### 7. **セキュリティヘッダーの追加**
**推奨**: セキュリティヘッダーを追加して XSS、Clickjacking などを防止

```csharp
// backend/Program.cs
app.Use(async (context, next) =>
{
    context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Add("X-Frame-Options", "DENY");
    context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");
    context.Response.Headers.Add("Referrer-Policy", "no-referrer");
    context.Response.Headers.Add("Content-Security-Policy", "default-src 'self'");
    await next();
});
```

---

#### 8. **Git コミット履歴のシークレットスキャン**
**推奨**: git-secrets や TruffleHog でコミット履歴をスキャン

```powershell
# TruffleHog のインストールと実行
pip install trufflehog
trufflehog --regex --entropy=True https://github.com/bell999-az400-handson/az400-handson3-final.git
```

---

#### 9. **依存関係の自動更新**
**推奨**: Dependabot を有効化して依存関係を自動更新

**.github/dependabot.yml**:
```yaml
version: 2
updates:
  - package-ecosystem: "nuget"
    directory: "/backend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
```

---

## 📊 セキュリティスコア

| カテゴリ | スコア | 評価 |
|---------|--------|------|
| シークレット管理 | 95/100 | ✅ 優秀 |
| 認証・認可 | 90/100 | ✅ 優秀 |
| コード品質 | 75/100 | ⚠️ 改善推奨 |
| 依存関係管理 | 60/100 | ⚠️ 脆弱性あり |
| ネットワークセキュリティ | 70/100 | ⚠️ HTTPS未実装 |
| **総合スコア** | **78/100** | **⚠️ 改善推奨** |

---

## 🎯 AZ-400 試験のポイント

### ✅ 実装済みのベストプラクティス
1. **Azure Key Vault + Managed Identity** でシークレット管理
2. **RBAC** による最小権限の原則
3. **SSH 公開鍵認証** によるセキュアなデプロイ
4. **Pull Request ベース** のコードレビュー
5. **自動化されたセキュリティスキャン** (パイプライン内)

### ⚠️ AZ-400 で問われる可能性のある改善点
1. **脆弱性管理**: 推移的な依存関係を含む脆弱性スキャン
2. **入力検証**: データアノテーションとモデル検証
3. **HTTPS 強制**: 本番環境での暗号化通信
4. **Rate Limiting**: DDoS 攻撃対策
5. **Dependabot**: 依存関係の自動更新

---

## 🚀 即座に実施すべきアクション

### 1. 脆弱性の修正（最優先）
```powershell
cd backend
dotnet add package Microsoft.EntityFrameworkCore.InMemory --version 8.0.11
dotnet restore
dotnet build
git add backend/backend.csproj backend/packages.lock.json
git commit -m "AB#612: Fix vulnerability in Microsoft.Extensions.Caching.Memory"
git push origin main
```

### 2. パイプラインの強化
```yaml
# azure-pipelines.yml の Security ステージを更新
- script: |
    echo "Running security vulnerability scan..."
    dotnet list backend/backend.csproj package --vulnerable --include-transitive
    if dotnet list backend/backend.csproj package --vulnerable --include-transitive | grep -q "has the following vulnerable packages"; then
      echo "##vso[task.logissue type=error]Vulnerable packages detected!"
      exit 1
    fi
  displayName: 'Vulnerability Scan (Include Transitive)'
```

### 3. 入力検証の追加
User モデルにデータアノテーションを追加し、UsersController に ModelState 検証を追加

---

## 📝 まとめ

**全体評価**: ⚠️ **改善推奨**（78/100）

**強み**:
- Azure Key Vault + Managed Identity による優れたシークレット管理
- RBAC による適切なアクセス制御
- Pull Request ベースの安全なワークフロー

**改善が必要な領域**:
1. 🔴 **即座に修正**: NuGet パッケージの脆弱性（High severity）
2. 🟡 **近日中に実施**: 入力検証、CORS 制限、HTTPS 強制
3. 🟢 **長期的に実施**: Rate Limiting、セキュリティヘッダー、Dependabot

**AZ-400 試験の観点**: 
このリポジトリは **AZ-400 のベストプラクティスの多くを実装** していますが、**脆弱性管理** と **入力検証** の改善が必要です。
