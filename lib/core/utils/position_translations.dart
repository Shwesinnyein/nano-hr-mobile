import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class PositionTranslations {
  // Position name translations
  static const Map<String, String> _positionTranslations = {
    'HR': 'ฝ่ายทรัพยากรบุคคล',
    'Manager': 'ผู้จัดการ',
    'Accountant': 'นักบัญชี',
    'Administrator': 'ธุรการ',
    'Programmer (Team Lead)': 'โปรแกรมเมอร์ (ผู้บริหารทีม)',
    'Programmer': 'โปรแกรมเมอร์',
    'Salesman': 'พนักงานขาย',
    'Purchase': 'ฝ่ายจัดซื้อ',
    'Security': 'เจ้าหน้าที่รักษาความปลอดภัย',
    'Housekeeper': 'พนักงานทำความสะอาด',
    'Shipper': 'พนักงานขนส่ง',
    'Driver': 'พนักงานขับรถ',
    'Management': 'ผู้บริหาร',
    'Warehouse Worker': 'พนักงานคลังสินค้า',
    'Warehouse Manager': 'ผู้จัดการคลังสินค้า',
    'Warehouse Administrator': 'ธุรการคลัง',
    'Surveyor': 'เซอร์เวย์',
    'Cashier': 'พนักงานเก็บเงิน',
    'Sale': 'พนักงานขาย',
    'Captain': 'กัปตัน',
    'Head Chef': 'หัวหน้าเชฟ',
    'Sous Chef': 'ผู้ช่วยเชฟ',
    'Waiter/Waitress': 'พนักงานเสิร์ฟ',
    'Bar Runner': 'พนักงานบาร์',
    'Dishwasher': 'พนักงานล้างจาน',
    'Receptionist': 'พนักงานต้อนรับ',
    'Assistant Manager': 'ผู้ช่วยผู้จัดการ',
    'Bartender': 'บาร์เทนเดอร์',
    'Purchasing': 'ฝ่ายจัดซื้อ',
    'Food Runner': 'เดินอาหาร',
    'Singer': 'นักร้อง',
    'Bassist': 'มือเบส',
    'Guitarist': 'มือกีตาร์',
    'Keyboardist': 'มือคีย์บอร์ด',
    'Drummer': 'มือกลอง',
    'Sound Engineer': 'วิศวกรเสียง',
    'Musician': 'นักดนตรี',
    'DJ': 'ดีเจ',
    'MC': 'พิธีกร',
    'Lightmen': 'ช่างไฟ',
    'Photographer': 'ช่างภาพ',
    'Bodyguard': 'บอดี้การ์ด',
  };

  /// Translate position name based on current language
  /// Returns translated name if available, otherwise returns original name
  static String translatePositionName(WidgetRef ref, String? positionName) {
    if (positionName == null || positionName.isEmpty) {
      return '-';
    }

    // Get current language
    final isThai = ref.read(languageProvider);
    
    // If English, return original
    if (!isThai) {
      return positionName;
    }

    // Check if translation exists
    final translation = _positionTranslations[positionName];
    if (translation == null) {
      // No translation found, return original
      return positionName;
    }

    return translation;
  }

  /// Translate position name with boolean language flag
  static String translatePositionNameWithLanguage(bool isThai, String? positionName) {
    if (positionName == null || positionName.isEmpty) {
      return '-';
    }

    // If English, return original
    if (!isThai) {
      return positionName;
    }

    final translation = _positionTranslations[positionName];
    if (translation == null) {
      return positionName;
    }

    return translation;
  }

  /// Get all available position names
  static List<String> getAvailablePositions() {
    return _positionTranslations.keys.toList();
  }
}

