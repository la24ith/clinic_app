import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../../../data/repositories/users_repository.dart';
import '../../../core/services/session_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final UsersRepository usersRepository;
  final SessionService sessionService;

  int _failedAttempts = 0;
  DateTime? _lockUntil;

  AuthCubit({required this.usersRepository, required this.sessionService})
    : super(AuthInitial());

  // emit آمن - يتجاهل العملية إذا كان الـ Cubit مغلقاً
  void _safeEmit(AuthState state) {
    if (!isClosed) emit(state);
  }

  Future<void> checkInitialState() async {
    _safeEmit(AuthLoading());

    final hasUsers = await usersRepository.hasAnyUser();
    if (!hasUsers) {
      _safeEmit(AuthFirstSetup());
      return;
    }

    final session = await sessionService.getSavedSession();
    if (session != null) {
      _safeEmit(AuthInitial());
      return;
    }

    _safeEmit(AuthInitial());
  }

  Future<void> login(
    String username,
    String password, {
    bool remember = false,
  }) async {
    if (_lockUntil != null && DateTime.now().isBefore(_lockUntil!)) {
      final remaining = _lockUntil!.difference(DateTime.now()).inSeconds;
      _safeEmit(
        AuthFailure(
          'تم تجاوز عدد المحاولات المسموح بها. حاول مجدداً بعد $remaining ثانية.',
        ),
      );
      return;
    }

    if (username.trim().isEmpty || password.isEmpty) {
      _safeEmit(AuthFailure('الرجاء تعبئة اسم المستخدم وكلمة المرور.'));
      return;
    }

    _safeEmit(AuthLoading());

    try {
      final user = await usersRepository.login(username.trim(), password);

      if (user == null) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _lockUntil = DateTime.now().add(const Duration(minutes: 5));
          _failedAttempts = 0;
          _safeEmit(
            AuthFailure(
              'اسم المستخدم أو كلمة المرور غير صحيحة.\n'
              'تم قفل الحساب مؤقتاً لمدة 5 دقائق.',
            ),
          );
        } else {
          _safeEmit(AuthFailure('اسم المستخدم أو كلمة المرور غير صحيحة.'));
        }
        return;
      }

      _failedAttempts = 0;
      _lockUntil = null;

      await sessionService.saveSession(
        userId: user.id,
        fullName: user.fullName,
        role: user.role.name,
        remember: remember,
      );

      _safeEmit(AuthSuccess(user));
    } catch (e) {
      _safeEmit(AuthFailure('حدث خطأ غير متوقع. حاول مجدداً.'));
    }
  }

  Future<void> logout() async {
    await sessionService.clearSession();
    _safeEmit(AuthInitial());
  }

  Future<void> createFirstUser({
    required String username,
    required String password,
    required String fullName,
    String? specialty,
  }) async {
    if (username.trim().isEmpty ||
        password.isEmpty ||
        fullName.trim().isEmpty) {
      _safeEmit(AuthFailure('الرجاء تعبئة جميع الحقول الإلزامية.'));
      return;
    }

    if (password.length < 6) {
      _safeEmit(AuthFailure('كلمة المرور يجب أن تكون 6 أحرف على الأقل.'));
      return;
    }

    _safeEmit(AuthLoading());

    try {
      await usersRepository.createFirstUser(
        username: username.trim(),
        password: password,
        fullName: fullName.trim(),
        specialty: specialty?.trim(),
      );

      // ندخل مباشرة بعد إنشاء الحساب
      await login(username.trim(), password, remember: false);
    } catch (e) {
      _safeEmit(
        AuthFailure('فشل إنشاء الحساب. تأكد من عدم تكرار اسم المستخدم.'),
      );
    }
  }
}
