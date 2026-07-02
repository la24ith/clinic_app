import 'package:clinic_app/data/database/database.dart';

import '../../../data/database/tables/users_table.dart';

// كل حالات تسجيل الدخول بملف منفصل للوضوح
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

// حالة خاصة: أول تشغيل، لا يوجد أي مستخدم بعد
class AuthFirstSetup extends AuthState {}
