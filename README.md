# Hookfy

一个使用 Flutter 开发的 Android 通知监测应用，支持 Webhook 推送功能。

## 功能特性

1. **通知监测** - 监测 Android 手机上的所有应用通知
2. **Webhook 推送** - 当监测到新通知时，自动发送 HTTP 请求到指定的 Webhook URL
3. **后台运行** - 支持后台持续运行，即使应用关闭也能继续监测
4. **应用筛选** - 可以选择监测所有应用或仅监测特定应用
5. **本地存储** - 所有通知都会保存到本地数据库
6. **易于扩展** - 使用 Flutter 开发，后续可轻松扩展到 iOS 平台

## 系统要求

- Android 6.0 (API 23) 或更高版本
- 需要授予通知访问权限

## 下载 APK

### 从 GitHub Releases 下载（推荐）

前往 [Releases](../../releases) 页面下载最新版本的 APK 文件，直接安装到 Android 设备即可。

## 开发者指南

### 自动构建和发布

本项目配置了 GitHub Actions CI/CD，可自动构建和发布 APK。详见 [RELEASE.md](RELEASE.md)。

**快速发布新版本**：
```bash
# 1. 更新版本号（编辑 pubspec.yaml）
# 2. 创建并推送 tag
git tag v1.0.1
git push origin v1.0.1
# 3. GitHub Actions 会自动构建并发布 APK
```

### 从源码构建

### 1. 克隆项目

```bash
git clone <repository-url>
cd hookfy
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行应用

```bash
flutter run
```

### 4. 授予权限

首次运行时，应用会提示您授予通知访问权限。请按照以下步骤操作：

1. 点击"Grant Permission"按钮
2. 在系统设置中找到"Hookfy"
3. 开启通知访问权限

### 5. 配置 Webhook

1. 打开应用设置页面
2. 输入您的 Webhook URL（例如：`https://your-server.com/webhook`）
3. 开启"Enable Webhook"开关
4. 可选：点击"Test Webhook"测试连接

## Webhook 数据格式

当检测到新通知时，应用会发送以下格式的 JSON 数据到您的 Webhook URL：

```json
{
  "type": "notification",
  "timestamp": "2025-11-17T12:34:56.789Z",
  "data": {
    "packageName": "com.example.app",
    "appName": "Example App",
    "title": "Notification Title",
    "text": "Notification text content",
    "subText": "Optional sub text",
    "bigText": "Optional big text",
    "timestamp": 1700227696789,
    "timestampISO": "2025-11-17T12:34:56.789Z"
  }
}
```

## 应用筛选

### 监测所有应用

默认情况下，应用会监测所有应用的通知。

### 监测特定应用

1. 进入设置页面
2. 关闭"Monitor All Apps"开关
3. 点击"Select Apps"
4. 选择您想要监测的应用

## 后台运行

应用支持后台持续运行：

1. 在设置中开启"Run in Background"
2. 应用会在通知栏显示一个前台服务通知
3. 即使关闭应用，通知监测仍会继续

## 项目结构

```
lib/
├── models/           # 数据模型
│   ├── notification_model.dart
│   └── app_config.dart
├── services/         # 服务层
│   ├── notification_service.dart
│   ├── database_service.dart
│   ├── preferences_service.dart
│   ├── webhook_service.dart
│   └── background_service.dart
├── providers/        # 状态管理
│   ├── settings_provider.dart
│   └── app_config_provider.dart
├── pages/           # UI 页面
│   ├── home_page.dart
│   ├── settings_page.dart
│   └── app_selection_page.dart
└── main.dart        # 入口文件

android/
└── app/src/main/kotlin/com/lazyrhythm/hookfy/
    ├── MainActivity.kt
    ├── NotificationListener.kt  # 通知监听服务
    └── BootReceiver.kt         # 开机自启动
```

## 技术栈

- **Flutter** - 跨平台 UI 框架
- **Provider** - 状态管理
- **SQLite** - 本地数据库
- **SharedPreferences** - 配置存储
- **HTTP** - Webhook 请求
- **WorkManager & Foreground Task** - 后台服务

## 权限说明

应用需要以下权限：

- **通知访问权限** - 用于监测其他应用的通知
- **网络权限** - 用于发送 Webhook 请求
- **前台服务权限** - 用于后台持续运行
- **开机自启动权限** - 用于系统重启后自动启动服务

## 隐私和安全

- 所有通知数据仅存储在本地设备
- Webhook URL 和配置信息存储在本地
- 应用不会收集或上传任何用户数据到第三方服务器
- 通知数据仅在启用 Webhook 功能时发送到用户指定的 URL

## 开发计划

- [ ] iOS 版本支持
- [ ] 自定义 Webhook 请求头
- [ ] 通知过滤规则
- [ ] 数据导出功能
- [ ] 通知统计和分析

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！