# Release Guide

本文档说明如何使用 GitHub Actions 自动生成和发布 APK。

## 自动发布流程

### 方式一：通过 Git Tag 自动发布（推荐）

1. 更新版本号（在 `pubspec.yaml` 中）：
   ```yaml
   version: 1.0.1+2  # 格式：版本号+构建号
   ```

2. 提交更改：
   ```bash
   git add pubspec.yaml
   git commit -m "chore: bump version to 1.0.1"
   ```

3. 创建并推送 tag：
   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

4. GitHub Actions 会自动：
   - 构建 release APK
   - 创建 GitHub Release
   - 上传 APK 到 Release

### 方式二：手动触发构建

1. 前往 GitHub 仓库的 Actions 页面
2. 选择 "Build and Release APK" workflow
3. 点击 "Run workflow"
4. 输入版本标签（可选，如 `v1.0.1`）
5. 点击运行

手动构建的 APK 会作为 Artifact 保存 30 天，可在 workflow 运行页面下载。

## CI/CD Workflows

### 1. Build and Release APK (release-apk.yml)
- **触发条件**：推送 tag (v*) 或手动触发
- **功能**：
  - 构建 release APK
  - 自动创建 GitHub Release（tag 触发时）
  - 上传 APK 到 Release 或 Artifacts

### 2. Build Check (build-check.yml)
- **触发条件**：PR 或推送到 main/master 分支
- **功能**：
  - 代码分析
  - 运行测试
  - 构建 debug APK
  - 确保代码质量

## 版本管理建议

- 使用语义化版本：`MAJOR.MINOR.PATCH`
  - MAJOR: 重大更新，不兼容的 API 变更
  - MINOR: 新功能，向后兼容
  - PATCH: Bug 修复

- 构建号（`+` 后的数字）每次构建递增

## 下载 APK

### 从 GitHub Releases
1. 前往仓库的 [Releases](../../releases) 页面
2. 找到对应版本
3. 下载 `notifly-v*.apk` 文件

### 从 Actions Artifacts（手动构建）
1. 前往 [Actions](../../actions) 页面
2. 选择对应的 workflow run
3. 在 Artifacts 部分下载 APK

## 签名说明

当前配置使用 debug 签名用于快速发布。

**生产环境建议**：配置正式的 release 签名
1. 生成 keystore
2. 将签名信息添加到 GitHub Secrets
3. 修改 workflow 使用正式签名

详见：[官方文档](https://docs.flutter.dev/deployment/android#signing-the-app)
