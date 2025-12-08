import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SensitiveNotificationGuidePage extends StatefulWidget {
  final String packageName;

  const SensitiveNotificationGuidePage({
    super.key,
    required this.packageName,
  });

  @override
  State<SensitiveNotificationGuidePage> createState() =>
      _SensitiveNotificationGuidePageState();
}

class _SensitiveNotificationGuidePageState
    extends State<SensitiveNotificationGuidePage> {
  int _selectedSolution = 0; // 0: ADB, 1: Disable Enhanced Notifications

  void _copyAdbCommand() {
    final command =
        'adb shell appops set ${widget.packageName} RECEIVE_SENSITIVE_NOTIFICATIONS allow';
    Clipboard.setData(ClipboardData(text: command));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ ADB 命令已複製到剪貼簿'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('敏感通知存取解決方案'),
      ),
      body: Column(
        children: [
          // Solution selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSolutionTab(
                    title: '方案 A：ADB 授權',
                    subtitle: '推薦給技術用戶',
                    isSelected: _selectedSolution == 0,
                    onTap: () => setState(() => _selectedSolution = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSolutionTab(
                    title: '方案 B：關閉增強通知',
                    subtitle: '適合所有用戶',
                    isSelected: _selectedSolution == 1,
                    onTap: () => setState(() => _selectedSolution = 1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Solution content
          Expanded(
            child: _selectedSolution == 0
                ? _buildAdbSolution()
                : _buildDisableEnhancedNotificationsSolution(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdbSolution() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWarningCard(
          icon: Icons.computer,
          title: '此方案需要電腦協助',
          description: '您需要一台電腦、USB 線，並啟用開發者模式。完成後可 100% 接收所有敏感通知。',
        ),
        const SizedBox(height: 24),
        _buildStepCard(
          stepNumber: '1',
          title: '啟用開發者模式',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('開啟', '設定 > 關於手機'),
              _buildSubStep('找到', '「版本號」或「Build number」'),
              _buildSubStep('連續點擊', '版本號 7 次'),
              _buildSubStep('完成', '看到「您已成為開發人員」訊息'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '2',
          title: '啟用 USB 調試',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('開啟', '設定 > 系統 > 開發人員選項'),
              _buildSubStep('啟用', '「USB 調試」開關'),
              _buildSubStep('確認', '彈出的安全警告對話框'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '3',
          title: '安裝 ADB 工具（電腦端）',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '根據您的電腦作業系統選擇：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildSubStep('Windows', '下載 Platform Tools 並解壓縮\n或使用 Chocolatey: choco install adb'),
              _buildSubStep('macOS', '使用 Homebrew: brew install android-platform-tools'),
              _buildSubStep('Linux', '使用套件管理器: sudo apt install adb'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '下載連結：developer.android.com/tools/releases/platform-tools',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '4',
          title: '連接手機並執行命令',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('連接', '使用 USB 線連接手機與電腦'),
              _buildSubStep('授權', '手機上確認「允許 USB 調試」'),
              _buildSubStep('開啟', '電腦的命令提示字元/終端機'),
              _buildSubStep('測試', '輸入 adb devices 確認連接'),
              const SizedBox(height: 12),
              const Text(
                '執行以下命令：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      'adb shell appops set ${widget.packageName} RECEIVE_SENSITIVE_NOTIFICATIONS allow',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _copyAdbCommand,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('複製命令'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '5',
          title: '重啟 Hookfy',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('完成', '在手機上完全關閉並重新開啟 Hookfy'),
              _buildSubStep('測試', '發送一個包含驗證碼的測試通知'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          icon: Icons.lightbulb_outline,
          title: '小提示',
          content: '• 每次應用更新後可能需要重新執行此命令\n'
              '• 此權限僅授予 Hookfy，不影響其他應用\n'
              '• 您可以隨時使用「關閉增強通知」方案作為替代',
        ),
      ],
    );
  }

  Widget _buildDisableEnhancedNotificationsSolution() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWarningCard(
          icon: Icons.warning_amber,
          title: '此方案會影響整個系統',
          description: '關閉後將失去通知建議回覆等功能，但操作簡單且立即生效。',
          color: Colors.deepOrange,
        ),
        const SizedBox(height: 24),
        _buildStepCard(
          stepNumber: '1',
          title: '開啟系統設定',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('方式 1', '下拉通知欄 > 點擊設定圖示'),
              _buildSubStep('方式 2', '在應用列表中找到「設定」應用'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '2',
          title: '進入通知設定',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('找到', '「通知」或「Notifications」選項'),
              _buildSubStep('點擊', '進入通知設定頁面'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '不同品牌的設定路徑可能略有不同',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '3',
          title: '關閉增強通知功能',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('向下滾動', '找到「Enhanced notifications」'),
              _buildSubStep('關閉', '將開關切換為「關閉」狀態'),
              const SizedBox(height: 8),
              const Text(
                '可能的名稱：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              _buildBulletPoint('Enhanced notifications（增強通知）'),
              _buildBulletPoint('Smart notifications（智能通知）'),
              _buildBulletPoint('Notification intelligence（通知智能）'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildStepCard(
          stepNumber: '4',
          title: '重啟 Hookfy',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubStep('完成', '在手機上完全關閉並重新開啟 Hookfy'),
              _buildSubStep('測試', '發送一個包含驗證碼的測試通知'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          icon: Icons.help_outline,
          title: '找不到「Enhanced notifications」選項？',
          content: '部分手機品牌可能沒有此選項，或選項名稱不同：\n\n'
              '• Samsung：設定 > 通知 > 進階設定\n'
              '• Google Pixel：設定 > 通知 > 通知記錄\n'
              '• 小米/MIUI：設定 > 通知與控制中心\n\n'
              '如果找不到此選項，請考慮使用方案 A（ADB 授權）',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.info_outline,
          title: '此方案的影響',
          content: '關閉增強通知後，您將失去：\n\n'
              '• 通知建議回覆功能\n'
              '• 智能通知分類\n'
              '• 自動操作建議\n\n'
              '但所有應用都能接收完整的通知內容。',
        ),
      ],
    );
  }

  Widget _buildSolutionTab({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard({
    required IconData icon,
    required String title,
    required String description,
    MaterialColor color = Colors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildSubStep(String label, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label：',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
