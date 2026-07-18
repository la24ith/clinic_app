// lib/features/licensing/view/license_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/licensing/license_manager.dart';

class LicenseScreen extends StatefulWidget {
  final LicenseInfo info;
  final VoidCallback onActivated;

  const LicenseScreen({
    super.key,
    required this.info,
    required this.onActivated,
  });

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _keyCtrl = TextEditingController();
  String? _hwId;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHwId();
  }

  Future<void> _loadHwId() async {
    final id = await LicenseManager.getHardwareId();
    if (mounted) setState(() => _hwId = id);
  }

  @override
  Widget build(BuildContext context) {
    final isExpired =
        widget.info.status == LicenseStatus.trialExpired ||
        widget.info.status == LicenseStatus.expired;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF1F3864).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isExpired
                      ? Icons.lock_outline_rounded
                      : Icons.access_time_rounded,
                  size: 40,
                  color: isExpired ? Colors.red : const Color(0xFF1F3864),
                ),
              ),
              const SizedBox(height: 24),

              // العنوان
              Text(
                isExpired
                    ? 'انتهت فترة التجربة المجانية'
                    : 'فترة التجربة المجانية',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F3864),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                isExpired
                    ? 'لمتابعة استخدام النظام، يرجى تفعيل الترخيص'
                    : 'متبقي ${widget.info.daysRemaining} يوم من فترة التجربة',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // بطاقة التفعيل
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // معرف الجهاز
                      const Text(
                        'معرف جهازك (أرسله للحصول على ترخيص):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _hwId ?? '...',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F3864),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              tooltip: 'نسخ',
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: _hwId ?? ''),
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ معرف الجهاز ✓'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // حقل الـ Key
                      const Text(
                        'مفتاح الترخيص:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keyCtrl,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'CLINIC-XXXX-XXXX-XXXX-XXXX',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          errorText: _error,
                        ),
                        onChanged: (_) {
                          if (_error != null) {
                            setState(() => _error = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // زر التفعيل
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _loading ? null : _activate,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1F3864),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                )
                              : const Text(
                                  'تفعيل الترخيص',
                                  style: TextStyle(fontSize: 15),
                                ),
                        ),
                      ),

                      if (!isExpired) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: widget.onActivated,
                            child: Text(
                              'متابعة التجربة (${widget.info.daysRemaining} يوم متبقي)',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // معلومات التواصل
              Text(
                'للحصول على ترخيص: la24ithdev@gmail.com',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _activate() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'الرجاء إدخال مفتاح الترخيص');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final info = await LicenseManager.activate(key);

    if (!mounted) return;
    setState(() => _loading = false);

    switch (info.status) {
      case LicenseStatus.active:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تفعيل الترخيص بنجاح ✓ — صالح حتى ${_formatDate(info.expiryDate!)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onActivated();

      case LicenseStatus.invalid:
        setState(() => _error = 'مفتاح الترخيص غير صالح');

      case LicenseStatus.expired:
        setState(() => _error = 'انتهت صلاحية هذا الترخيص');

      default:
        setState(() => _error = 'خطأ غير متوقع، تواصل مع الدعم');
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
