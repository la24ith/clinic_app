import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/tables/users_table.dart';
import '../../core/utils/password_helper.dart';

class UsersRepository {
  final AppDatabase db;

  UsersRepository(this.db);

  // التحقق من بيانات تسجيل الدخول
  Future<User?> login(String username, String password) async {
    final hashedPassword = PasswordHelper.hash(password);
    final query = db.select(db.users)
      ..where(
        (u) =>
            u.username.equals(username) &
            u.passwordHash.equals(hashedPassword) &
            u.isActive.equals(true),
      );
    return await query.getSingleOrNull();
  }

  // التحقق من وجود أي مستخدم بقاعدة البيانات (لشاشة الإعداد الأول)
  Future<bool> hasAnyUser() async {
    final result = await db.select(db.users).get();
    return result.isNotEmpty;
  }

  // إنشاء المستخدم الأول (الطبيب/Admin) عند أول تشغيل
  Future<int> createFirstUser({
    required String username,
    required String password,
    required String fullName,
    String? specialty,
    String? phone,
  }) {
    return db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            username: username,
            passwordHash: PasswordHelper.hash(password),
            fullName: fullName,
            role: UserRole.doctor,
            specialty: Value(specialty),
            phone: Value(phone),
          ),
        );
  }

  // إنشاء مستخدم مساعد (من شاشة الإعدادات لاحقاً)
  Future<int> createAssistant({
    required String username,
    required String password,
    required String fullName,
  }) {
    return db
        .into(db.users)
        .insert(
          UsersCompanion.insert(
            username: username,
            passwordHash: PasswordHelper.hash(password),
            fullName: fullName,
            role: UserRole.assistant,
          ),
        );
  }

  // تغيير كلمة المرور
  Future<int> changePassword(int userId, String newPassword) {
    return (db.update(db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(passwordHash: Value(PasswordHelper.hash(newPassword))),
    );
  }

  Future<bool> verifyPassword(int userId, String password) async {
    final user = await (db.select(
      db.users,
    )..where((u) => u.id.equals(userId))).getSingleOrNull();
    if (user == null) return false;
    return PasswordHelper.verify(password, user.passwordHash);
  }
}
