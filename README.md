## アプリ概要
このアプリは、家族間のTODO管理や情報共有を目的としたスマートフォンアプリです。
（ここに、あなたがアプリで実現したい全体像を簡潔に記述してください。例: 古い写真を見返す「ふぉとぱっく！」のような体験を、家族のTODO管理に応用する、など）

## 実装したい必要最低限の機能 (MVP)
- トップ画面（完了）
- お父さん機能
    - お父さんのTODOリスト（TODOの追加、完了、削除、リアルタイム同期）
    - プロンプトコピー
    - デバッグ機能
- お母さん機能（「Coming Soon」画面でOK）
- 共通機能（「Coming Soon」画面でOK）
    - お願いごと機能（TODOリストと同様の形式で、お気に入り機能とリアルタイム同期）
    - メッセージ機能（「Coming Soon」画面でOK）
- Firebaseとの連携（匿名認証、Firestoreでのデータ永続化）

## 技術仕様
- **フロントエンド:** Flutter
- **バックエンド:** Google Firebase (Firestore, Authentication)
- **状態管理:** シンプルな `setState` または `Provider` (必要に応じてAIが提案)
- **データ構造:**
    - プライベートデータ: `artifacts/{appId}/users/{userId}/{collectionName}`
    - パブリックデータ: `artifacts/{appId}/public/data/{collectionName}`
    - コレクション名やフィールド名は、各機能の実装時にAIが提案。
- **外部ライブラリ:**
    - `firebase_core`, `firebase_auth`, `cloud_firestore`
    - `clipboard` (プロンプトコピー機能用)
    - `image_picker` (プロンプトコピー機能用)
    - `flutter_datetime_picker_plus` (TODO/お願いごと詳細画面用)
- **エラーハンドリング:** `try/catch` ブロックによる非同期処理のエラー捕捉。ユーザーへの通知は `ScaffoldMessenger.of(context).showSnackBar` を使用。

## AIへの指示ルール
- **命名規則:** Dartの標準的な命名規則に従う (camelCase, PascalCaseなど)。
- **コメント:** 各クラス、メソッド、主要なロジックには、日本語で分かりやすいコメントを付与すること。
- **テストコード:** 現段階では不要。機能実装が安定した後、必要に応じて指示する。
- **UI/UX:** 各機能のUI/UX仕様（以前提供済み）を最大限考慮すること。特に、以下を遵守すること。
    - シンプルな縦並びのボタンレイアウト。
    - 各ボタンは視認性の高い色とテキストで構成。
    - タップ時の視覚フィードバック（`ElevatedButton` のデフォルトでOK）。
    - TODOリストは `FlatList` (Flutterでは `ListView.builder`) で効率的にレンダリング。
    - 完了したTODOにはテキストに打ち消し線が適用される視覚的フィードバック。
    - TODOが0件の場合は「TODOはまだありません。」と表示。
    - Toastメッセージによる操作フィードバック（追加、完了、削除）。
    - 削除前の確認ダイアログ (`showDialog`) を使用。
- **最適化:** パフォーマンスに配慮し、不要な再描画や重い処理は避けること。