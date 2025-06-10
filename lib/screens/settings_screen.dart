import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationEnabled = false;
  bool _isLoading = true;
  Map<String, dynamic>? _backupInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await NotificationService.isNotificationEnabled();
    final backupInfo = await BackupService.getBackupInfo();
    setState(() {
      _notificationEnabled = enabled;
      _backupInfo = backupInfo;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (value) {
        await NotificationService.scheduleDailyNotification();
        _showSnackBar(_getLocalizations().notificationEnabled);
      } else {
        await NotificationService.cancelDailyNotification();
        _showSnackBar('알림이 해제되었습니다');
      }
      
      setState(() {
        _notificationEnabled = value;
      });
    } catch (e) {
      _showSnackBar('설정 중 오류가 발생했습니다: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  AppLocalizations _getLocalizations() {
    final locale = Localizations.localeOf(context);
    return AppLocalizations(locale);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _getLocalizations();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Colors.grey.shade50,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 알림 설정 섹션
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.notifications_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                localizations.notificationSettings,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // 매일 알림 설정
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizations.dailyHabitReminder,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        localizations.notificationDescription,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // 현재 시간대 정보 표시 (출시용에서 숨김)
                                      // Container(
                                      //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      //   decoration: BoxDecoration(
                                      //     color: Colors.blue.shade50,
                                      //     borderRadius: BorderRadius.circular(8),
                                      //     border: Border.all(color: Colors.blue.shade200),
                                      //   ),
                                      //   child: Text(
                                      //     NotificationService.getCurrentTimezoneInfo(),
                                      //     style: TextStyle(
                                      //       fontSize: 11,
                                      //       color: Colors.blue.shade700,
                                      //       fontFamily: 'monospace',
                                      //     ),
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _notificationEnabled,
                                  onChanged: _toggleNotification,
                                  activeColor: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                          
                          if (_notificationEnabled) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.blue.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '일일 습관 알림이 활성화되었습니다',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '📅 알림 시간: 오전 7시, 오후 12시, 오후 6시\n'
                                    '🎯 목적: 아침(시작), 점심(중간체크), 저녁(마무리) 습관 관리\n'
                                    '💡 일정한 시간에 반복하면 습관이 더 쉽게 만들어져요',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // 데이터 백업/복원 섹션 (숨김)
                    // const SizedBox(height: 20),
                    
                    const SizedBox(height: 20),
                    
                    // 앱 정보 섹션
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.info_rounded,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '앱 정보',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          _buildInfoRow('앱 이름', localizations.appTitle),
                          _buildInfoRow('버전', '1.0.0'),
                          _buildInfoRow('개발자', 'Habit Maker Team'),
                          _buildInfoRow('설명', '매일 반복하는 습관을 만들고 관리하는 앱'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 도움말 섹션
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.help_outline_rounded,
                                  color: Colors.orange.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '사용법',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildHelpItem('1. 반복 습관 템플릿', '매일 반복할 습관들을 최대 30개까지 설정하세요'),
                          _buildHelpItem('2. 템플릿 적용', '"오늘부터 습관 템플릿 적용하기" 버튼을 눌러 적용하세요'),
                          _buildHelpItem('3. 일일 체크', '매일 습관을 체크하고 진행률을 확인하세요'),
                          _buildHelpItem('4. 통계 확인', '완료율과 칭호를 통해 성과를 확인하세요'),
                          _buildHelpItem('5. 스마트 알림', '오전 7시, 오후 12시, 오후 6시에 하루 3번 알림을 받아보세요'),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBackupDate(dynamic date) {
    if (date is String) {
      return date;
    } else if (date is num) {
      return DateTime.fromMillisecondsSinceEpoch(date.toInt()).toString();
    } else {
      throw Exception('Invalid date format');
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    ) ?? false;
  }
} 