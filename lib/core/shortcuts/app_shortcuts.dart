import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// تعريف كل الاختصارات كثوابت
class AppShortcuts {
  // Ctrl+W → إضافة لقائمة الانتظار
  static const addToWaiting = SingleActivator(
    LogicalKeyboardKey.keyW,
    control: true,
  );

  // Ctrl+N → مريض جديد
  static const newPatient = SingleActivator(
    LogicalKeyboardKey.keyN,
    control: true,
  );

  // Ctrl+M → موعد جديد
  static const newAppointment = SingleActivator(
    LogicalKeyboardKey.keyM,
    control: true,
  );

  // Ctrl+F → بحث سريع
  static const search = SingleActivator(LogicalKeyboardKey.keyF, control: true);
}

// Intent لكل اختصار (الـ Flutter Shortcut System يحتاجها)
class AddToWaitingIntent extends Intent {
  const AddToWaitingIntent();
}

class NewPatientIntent extends Intent {
  const NewPatientIntent();
}

class NewAppointmentIntent extends Intent {
  const NewAppointmentIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}
