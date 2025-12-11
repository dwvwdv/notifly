# Hookfy - Claude AI 開發參考

> 本文檔為 Claude AI 助手提供項目開發索引。

## 項目簡介

**Hookfy** - Flutter Android 通知監測應用，支援 Webhook 推送。

- **版本**: 1.1.1+7
- **技術棧**: Flutter + Kotlin + SQLite + Provider

## 文檔索引

詳細開發文檔位於 `docs/` 目錄：

| 文檔 | 說明 |
|------|------|
| [docs/codebase_summary.md](docs/codebase_summary.md) | 代碼庫總結、核心功能、最近更新、開發命令 |
| [docs/file_reference.md](docs/file_reference.md) | 目錄結構、關鍵文件說明 |
| [docs/architecture_overview.md](docs/architecture_overview.md) | 技術架構、數據流、數據庫結構 |

## 外部資源

- **GitHub**: https://github.com/dwvwdv/hookfy
- **DeepWiki**: https://deepwiki.com/dwvwdv/hookfy

## 快速開始

```bash
flutter pub get    # 安裝依賴
flutter run        # 運行應用
flutter analyze    # 代碼分析
```

## 開發規範

### 版本管理 ⚠️ 重要

**每次進行功能調整或修復都必須更新版本號！**

版本號格式：`major.minor.patch+build`（例如：`1.0.3+4`）

更新版本時需要同步修改三個文件：`pubspec.yaml`、`lib/pages/settings_page.dart`、`CLAUDE.md`。詳細的版本更新流程、驗證步驟和常見問題請參考：

**📖 詳細流程**: 見 [.claude/skills/version-update.md](.claude/skills/version-update.md)

## 核心文件

- `lib/pages/home_page.dart` - 通知列表 UI（含滑動刪除）
- `lib/services/database_service.dart` - SQLite 操作
- `lib/services/notification_service.dart` - 通知事件管理
- `android/.../NotificationListener.kt` - 原生通知監聽

---
**最後更新**: 2025-11-21
