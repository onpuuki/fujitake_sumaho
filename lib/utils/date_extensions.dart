import 'package:flutter/material.dart'; // DateTime.sunday のために必要

// DateTimeを拡張して、日付計算を容易にするヘルパー
extension DateTimeExtension on DateTime {
  /// その日の23時59分59秒999ミリ秒を返す
  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// 次の最初の日曜日を返す
  DateTime nextSunday() {
    DateTime now = this;
    // DateTime.sunday は 7
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) {
      // 今日が日曜日か、日曜日を過ぎている場合、次の日曜日まで7日加算
      daysUntilSunday += 7;
    }
    return now.add(Duration(days: daysUntilSunday));
  }
}
