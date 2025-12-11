# Version Update - 版本更新流程

## 何時使用 (When to Use)

當需要更新應用版本號時使用此 Skill：
- 新增功能完成後
- 修復 Bug 後
- 進行任何代碼改動後

**重要**: 每次功能調整或修復都必須更新版本號！

## 版本號規則 (Version Rules)

格式：`major.minor.patch+build`（例如：`1.0.3+4`）

- **新功能**: 增加 `minor`（1.0.x → 1.1.0）
- **Bug 修復/小改進**: 增加 `patch`（1.0.3 → 1.0.4）
- **每次更新**: 必須增加 `build`（+3 → +4）

## 執行步驟 (Steps)

### 1. 更新 pubspec.yaml

```bash
# 讀取當前版本
grep '^version:' pubspec.yaml

# 手動編輯或使用 sed 更新（例如更新到 1.0.5+6）
# version: 1.0.5+6
```

編輯 `pubspec.yaml` 的 `version` 欄位。

### 2. 更新 settings_page.dart

文件路徑：`lib/pages/settings_page.dart`

找到版本顯示行並更新：
```dart
subtitle: Text('1.0.5+6'),  // 更新此行
```

### 3. 更新 CLAUDE.md

更新頂部的版本號：
```markdown
- **版本**: 1.0.5+6
```

### 4. 驗證三處一致性

```bash
# 檢查三個文件的版本號
echo "=== pubspec.yaml ==="
grep '^version:' pubspec.yaml

echo "=== settings_page.dart ==="
grep "subtitle: Text(" lib/pages/settings_page.dart | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\++[0-9]\+"

echo "=== CLAUDE.md ==="
grep '^\- \*\*版本\*\*:' CLAUDE.md
```

確保三處版本號完全一致！

### 5. 提交變更

```bash
# 提交版本更新
git add pubspec.yaml lib/pages/settings_page.dart CLAUDE.md
git commit -m "chore: 更新版本號至 x.x.x+x"
```

## 驗證檢查清單 (Verification Checklist)

- [ ] `pubspec.yaml` 版本號已更新
- [ ] `lib/pages/settings_page.dart` 版本號已更新
- [ ] `CLAUDE.md` 版本號已更新
- [ ] 三處版本號完全一致
- [ ] `build` 號已遞增
- [ ] 根據變更類型正確更新了 `minor` 或 `patch`
- [ ] Git 提交信息使用了正確格式

## 常見問題 (Common Issues)

### 問題 1: 忘記更新某個文件
**症狀**: 版本號不一致
**解決**: 使用上面的驗證命令檢查所有三處，補充遺漏的更新

### 問題 2: build 號忘記遞增
**症狀**: build 號與上一版本相同
**解決**: 每次更新都必須增加 build 號，即使只改了 patch

### 問題 3: 不確定該增加哪個版本號
**規則**:
- 新功能/新特性 → 增加 `minor`
- Bug 修復/小調整 → 增加 `patch`
- 破壞性更新 → 增加 `major`（需謹慎）
- 任何情況都要增加 `build`

### 問題 4: Git 提交後發現版本號錯誤
**解決**:
```bash
# 如果還沒 push
git reset --soft HEAD~1
# 修正版本號後重新提交

# 如果已經 push，創建新的修正提交
# 修正版本號
git add pubspec.yaml lib/pages/settings_page.dart CLAUDE.md
git commit -m "fix: 修正版本號錯誤"
```

## 範例 (Examples)

### 範例 1: 新功能（添加通知過濾）
```
舊版本: 1.0.3+4
新版本: 1.1.0+5  (minor +1, patch 重置為 0, build +1)
```

### 範例 2: Bug 修復（修復通知不顯示）
```
舊版本: 1.1.0+5
新版本: 1.1.1+6  (patch +1, build +1)
```

### 範例 3: 小改進（優化 UI）
```
舊版本: 1.1.1+6
新版本: 1.1.2+7  (patch +1, build +1)
```

## 自動化腳本（可選）

如需自動化版本更新，可使用以下腳本模板：

```bash
#!/bin/bash
# update-version.sh

OLD_VERSION=$(grep '^version:' pubspec.yaml | cut -d' ' -f2)
echo "當前版本: $OLD_VERSION"
echo "輸入新版本（格式: x.x.x+x）:"
read NEW_VERSION

# 更新三個文件
sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
sed -i "s/subtitle: Text('.*')/subtitle: Text('$NEW_VERSION')/" lib/pages/settings_page.dart
sed -i "s/- \*\*版本\*\*: .*/- **版本**: $NEW_VERSION/" CLAUDE.md

echo "版本已更新至: $NEW_VERSION"
echo "請檢查並提交變更"
```

## 相關資源

- [語義化版本規範 (Semantic Versioning)](https://semver.org/lang/zh-TW/)
- Flutter 版本管理文檔
- `pubspec.yaml` 規範
