# 演習 7: Azure Repos から Slack への通知設定

## 📋 概要

Azure DevOps の Service Hooks を使用して、リポジトリのイベント（コミット、PR作成、ビルド完了など）を Slack に自動通知する方法を学習します。

### 🎯 学習目標

- Slack Incoming Webhook の作成方法を理解する
- Azure DevOps Service Hooks の設定方法を習得する
- チーム コラボレーションのベスト プラクティスを学ぶ
- AZ-400 試験で求められる通知設定スキルを身につける

### ⏱️ 所要時間

約 20-30 分

---

## 📚 前提条件

- Azure DevOps の Organization とプロジェクトへのアクセス権
- Slack ワークスペースへのアクセス権（アプリ追加権限）
- 本リポジトリのクローン完了

---

## 🚀 演習手順

### ステップ 1: Slack で Incoming Webhook を作成

#### 1.1 Slack App Directory にアクセス

1. **Slack ワークスペース**にログイン

2. **App Directory** を開く：
   ```
   https://<your-workspace>.slack.com/apps
   ```
   または、Slack アプリで **「Apps」** → **「App Directory」** をクリック

#### 1.2 Incoming WebHooks をインストール

1. 検索ボックスに **「Incoming WebHooks」** と入力

2. **「Incoming WebHooks」** アプリをクリック

3. **「Add to Slack」** ボタンをクリック

#### 1.3 Webhook の設定

1. **通知先のチャンネル**を選択：
   - 既存チャンネルを選択（例: `#devops-notifications`）
   - または新しいチャンネルを作成

2. **「Add Incoming WebHooks integration」** をクリック

3. **Webhook URL** をコピーして保存：
   ```
   https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
   ```
   ⚠️ このURLは機密情報です。安全に管理してください。

4. **カスタマイズ**（オプション）：
   - **Customize Name**: `Azure DevOps Bot`
   - **Customize Icon**: Azure DevOps のアイコンをアップロード
   - **Descriptive Label**: `Azure Repos Notifications`

5. **「Save Settings」** をクリック

#### ✅ 確認ポイント

- [ ] Webhook URL を安全な場所にコピーした
- [ ] Slack チャンネルに Incoming Webhook の追加メッセージが表示された

---

### ステップ 2: Azure DevOps で Service Hook を設定

#### 2.1 Project Settings にアクセス

1. **Azure DevOps** プロジェクトを開く：
   ```
   https://dev.azure.com/<your-organization>/<your-project>
   ```

2. 左下の **⚙️ Project Settings** をクリック

3. **Service hooks** セクションをクリック

#### 2.2 Slack Service Hook を作成

1. **「+ Create subscription」** ボタンをクリック

2. **Select a Service** で **「Slack」** を選択 → **「Next」**

#### 2.3 トリガー設定（例: コードプッシュ通知）

1. **Trigger on this type of event**: **「Code pushed」** を選択

2. **フィルター設定**:
   - **Repository**: 通知したいリポジトリを選択（または `All` for all repositories）
   - **Branch**: `main` または `All branches`
   - **Pushed by member of group**: `[Any]`
   - **Pushed by**: `[Any]`

3. **「Next」** をクリック

#### 2.4 アクション設定

1. **Slack Webhook URL**: ステップ1.3でコピーしたURLを貼り付け

2. **Message format**: 
   - **Compact**: 簡潔なメッセージ
   - **Detailed**: 詳細なメッセージ（推奨）

3. **「Test」** ボタンをクリックしてテスト通知を送信

4. Slack チャンネルでテストメッセージを確認

5. **「Finish」** をクリック

#### ✅ 確認ポイント

- [ ] Service Hook が作成された（Enabled 状態）
- [ ] Test 通知が Slack に届いた

---

### ステップ 3: 他のイベント通知を設定（推奨）

#### 3.1 Pull Request 作成通知

**Service Hook の追加**:
1. **「+ Create subscription」** → **「Slack」**
2. **Trigger**: **「Pull request created」**
3. **Repository**: `All`
4. **Target branch**: `main`
5. **Webhook URL**: 同じURLまたは別チャンネル用のURL
6. **Finish**

**用途**: PRレビュー依頼の自動通知

#### 3.2 ビルド失敗通知

**Service Hook の追加**:
1. **「+ Create subscription」** → **「Slack」**
2. **Trigger**: **「Build completed」**
3. **Build status**: **「Failed」** のみ選択
4. **Webhook URL**: 重要なアラート用チャンネル
5. **Finish**

**用途**: CI/CD パイプラインのエラー監視

#### 3.3 リリース デプロイ通知

**Service Hook の追加**:
1. **「+ Create subscription」** → **「Slack」**
2. **Trigger**: **「Release deployment completed」**
3. **Environment**: `Production`
4. **Webhook URL**: 本番環境デプロイ通知用チャンネル
5. **Finish**

**用途**: 本番環境への変更追跡

---

### ステップ 4: 動作確認

#### 4.1 テストコミットを作成

PowerShell で実行：

```powershell
# リポジトリのルートディレクトリに移動
cd C:\Users\bell9\github\az400-handson3-final

# 空のコミットを作成（ファイル変更なし）
git commit --allow-empty -m "Test: Slack notification integration"

# main ブランチにプッシュ
git push origin main
```

#### 4.2 Slack で通知を確認

Slack チャンネルで以下のような通知を確認：

```
🔵 Azure DevOps Bot  12:34 PM
────────────────────────────
📦 Code pushed
👤 bell9 pushed to main

Repository: az400-handson3-final
Branch: main
Commit: Test: Slack notification integration

🔗 View commit
```

#### ✅ 確認ポイント

- [ ] Slack にコミット通知が届いた
- [ ] 通知内容が正確（ユーザー名、ブランチ、コミットメッセージ）
- [ ] リンクから Azure DevOps のコミット詳細にアクセスできる

---

## 🎯 推奨される通知パターン

### パターン 1: 開発チーム向け（#dev-main）

| イベント | 設定 | 用途 |
|---------|------|------|
| Code pushed | Branch: `main` | メインブランチの変更監視 |
| Pull request created | Target: `main` | レビュー依頼の通知 |
| Pull request updated | Target: `main` | PR更新の追跡 |

### パターン 2: アラート専用（#build-alerts）

| イベント | 設定 | 用途 |
|---------|------|------|
| Build completed | Status: `Failed` | ビルド失敗の即時通知 |
| Build completed | Status: `Partially succeeded` | 警告の監視 |

### パターン 3: 本番環境監視（#production）

| イベント | 設定 | 用途 |
|---------|------|------|
| Release deployment started | Environment: `Production` | デプロイ開始の通知 |
| Release deployment completed | Environment: `Production` | デプロイ完了の確認 |

---

## 🔧 高度な設定

### オプション 1: Azure Logic Apps 経由でのカスタマイズ

**メリット**:
- 条件分岐（特定のファイルが変更された場合のみ通知）
- メッセージのカスタマイズ（@mention追加、絵文字、フォーマット）
- 複数のアクション（Slack + Email + Teams など）

**設定手順**:
1. Azure Portal で Logic App を作成
2. トリガー: HTTP Request（Azure DevOps Webhook）
3. アクション: Slack - Post message
4. Azure DevOps で Web Hooks Service Hook を作成
5. URL: Logic App の HTTP トリガーURL

### オプション 2: メンション付き通知

Slack Webhook でメンションを含める：

```json
{
  "text": "@channel New PR created by John Doe\n<https://dev.azure.com/...| View PR>"
}
```

Logic Apps で実装可能。

---

## 🛠️ トラブルシューティング

### 問題 1: 通知が届かない

**確認項目**:
1. **Service Hook の状態**:
   - Azure DevOps → Project Settings → Service hooks
   - 該当の Hook が **Enabled** になっているか確認

2. **Webhook URL**:
   - Slack で Webhook 設定を確認
   - URLが正しくコピーされているか

3. **テスト送信**:
   - Service Hook の編集画面で **「Test」** をクリック
   - エラーメッセージを確認

4. **Slack チャンネル**:
   - チャンネルがアーカイブされていないか
   - Webhook が正しいチャンネルに設定されているか

**解決方法**:
```powershell
# Azure DevOps CLI で Service Hook を確認
az devops service-endpoint list --project az400-handson3-final
```

### 問題 2: 通知が多すぎる

**対策**:
1. **フィルター条件を追加**:
   - 特定のブランチのみ（`main`, `develop`）
   - 特定のユーザーのみ

2. **通知の統合**:
   - 複数の小さなコミットを1つの通知にまとめる
   - Batch notifications（Logic Apps で実装）

3. **チャンネルの分離**:
   - 重要度別にチャンネルを分ける
   - `#dev-all`: すべての通知
   - `#dev-critical`: 失敗・エラーのみ

### 問題 3: 通知が遅い

**原因**:
- Azure DevOps の Service Hook は非同期処理
- 通常 5秒～1分程度の遅延

**確認方法**:
1. Azure DevOps → Service hooks → 該当の Hook
2. **History** タブで実行履歴を確認
3. **Response** で Slack API のレスポンスを確認

---

## ✅ 演習の完了チェックリスト

- [ ] Slack Incoming Webhook を作成した
- [ ] Azure DevOps で Code pushed 通知を設定した
- [ ] テストコミットで通知が届くことを確認した
- [ ] PR作成通知を設定した（オプション）
- [ ] ビルド失敗通知を設定した（オプション）
- [ ] 通知パターンのベストプラクティスを理解した

---

## 📚 参考資料

### 公式ドキュメント

- [Azure DevOps Service Hooks](https://learn.microsoft.com/ja-jp/azure/devops/service-hooks/overview)
- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks)
- [Azure Logic Apps](https://learn.microsoft.com/ja-jp/azure/logic-apps/logic-apps-overview)

### AZ-400 試験との関連

**スキル測定領域**:
- コラボレーション プラットフォームの構成（15-20%）
- コミュニケーション戦略の実装
- DevOps プラクティスの促進

**重要な概念**:
- ✅ イベント駆動型通知
- ✅ チームの可視化
- ✅ フィードバック ループ
- ✅ ChatOps の基礎

---

## 🎓 追加の学習課題

### 課題 1: 複数チャンネルへの通知設定

**目標**: 用途別に3つのチャンネルを作成し、適切なイベントを振り分ける

1. `#dev-commits`: すべてのコミット
2. `#dev-prs`: PR関連のみ
3. `#dev-alerts`: ビルド失敗のみ

### 課題 2: Microsoft Teams への通知設定

**目標**: Slack と同様に Microsoft Teams への通知を設定

1. Teams で Incoming Webhook を作成
2. Azure DevOps で Service Hook を設定（Teams を選択）
3. 通知をテスト

### 課題 3: カスタムメッセージの作成（上級）

**目標**: Azure Logic Apps を使用してカスタムメッセージを送信

1. Logic App を作成
2. HTTP トリガーを追加
3. Slack への POST アクションを追加（カスタムJSON）
4. Azure DevOps で Web Hook を設定

---

## 📝 まとめ

この演習で学んだこと：

✅ **Slack Incoming Webhook** を使用した外部サービスとの統合
✅ **Azure DevOps Service Hooks** によるイベント駆動型通知
✅ **チーム コラボレーション**のためのベストプラクティス
✅ **AZ-400 試験**で求められる DevOps 通知スキル

次の演習では、Azure Monitor と Application Insights を使用したアプリケーション監視を学習します。

---

**演習お疲れさまでした！** 🎉
