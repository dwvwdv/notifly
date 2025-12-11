# Hookfy - Claude AI 開發參考

> 本文檔為 Claude AI 助手提供項目開發索引。

## 項目簡介

**Hookfy** - Flutter Android 通知監測應用，支援 Webhook 推送。

- **版本**: 1.2.0+8
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

#### 版本更新流程

1. **更新版本號**
   - 修改 `pubspec.yaml` 中的 `version` 欄位
   - 新功能：增加 `minor` 版本號（1.0.x → 1.1.x）
   - Bug 修復或小改進：增加 `patch` 版本號（1.0.3 → 1.0.4）
   - 每次更新都要增加 `build` 號（+3 → +4）

2. **同步版本資訊**
   - 更新 `lib/pages/settings_page.dart` 中的版本顯示
   - 更新 `CLAUDE.md` 頂部的版本號
   - 三處版本號必須保持一致！

3. **提交訊息**
   ```bash
   git commit -m "chore: 更新版本號至 x.x.x+x"
   ```

#### 範例

```dart
// pubspec.yaml
version: 1.0.4+5

// settings_page.dart
subtitle: Text('1.0.4+5'),

// CLAUDE.md
- **版本**: 1.0.4+5
```

## 核心文件

- `lib/pages/home_page.dart` - 通知列表 UI（含滑動刪除）
- `lib/services/database_service.dart` - SQLite 操作
- `lib/services/notification_service.dart` - 通知事件管理
- `android/.../NotificationListener.kt` - 原生通知監聽

---
**最後更新**: 2025-11-21
