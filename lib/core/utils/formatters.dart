import 'package:intl/intl.dart';

import '../config/app_config.dart';

/// تنسيق الأرقام والتواريخ بالعربية.
///
/// العملة دينار عراقي فقط: بفواصل آلاف وبلا كسور عشرية، لأن الدينار
/// العراقي لا يُتعامل به بالفلس عملياً.
abstract final class Fmt {
  static final _money = NumberFormat('#,###', 'ar');
  static final _plain = NumberFormat('#,###', 'ar');

  /// يوحّد نظام الأرقام إلى اللاتيني (0-9).
  ///
  /// **لماذا هذا ضروري:** حزمة intl تشتق نظام الأرقام من بيانات اللغة، فتظهر
  /// المبالغ بأرقام لاتينية والتواريخ بأرقام عربية-هندية على نفس الشاشة،
  /// وتختلف النتيجة بين أندرويد وويندوز. فرض نظام واحد صراحةً يجعل العرض
  /// متطابقاً على كل جهاز.
  ///
  /// للتبديل إلى الأرقام العربية-الهندية (٠١٢٣): اعكس اتجاه الاستبدال هنا،
  /// وهو التغيير الوحيد المطلوب في التطبيق كله.
  static String _digits(String s) {
    const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
    var out = s;
    for (var i = 0; i < 10; i++) {
      out = out.replaceAll(arabicIndic[i], '$i');
    }
    // الفاصلة العربية والفاصلة العشرية العربية
    return out.replaceAll('٬', ',').replaceAll('٫', '.');
  }

  /// مبلغ مع العملة: «١٢٠,٠٠٠ د.ع»
  static String money(num? v) {
    if (v == null) return '—';
    return '${_digits(_money.format(v))} ${AppConfig.currency}';
  }

  /// مبلغ بلا عملة
  static String amount(num? v) => v == null ? '—' : _digits(_money.format(v));

  /// عدد صحيح: «١,٢٤٠»
  static String count(num? v) => v == null ? '0' : _digits(_plain.format(v));

  /// مبلغ مختصر للكروت الضيقة: «١٢٠ ألف» / «٢.٤ مليون»
  static String moneyShort(num? v) {
    if (v == null) return '—';
    final n = v.abs();
    if (n >= 1000000) {
      final m = v / 1000000;
      return '${_trim(m)} مليون ${AppConfig.currency}';
    }
    if (n >= 1000) {
      final k = v / 1000;
      return '${_trim(k)} ألف ${AppConfig.currency}';
    }
    return money(v);
  }

  static String _trim(double d) {
    final s = d.toStringAsFixed(1);
    return _digits(NumberFormat('#,##0.#', 'ar').format(double.parse(s)));
  }

  /// تاريخ: «٣ آب ٢٠٢٦»
  static String date(DateTime? d) =>
      d == null ? '—' : _digits(DateFormat('d MMMM y', 'ar').format(d.toLocal()));

  /// تاريخ قصير: «٢٠٢٦/٠٨/٠٣»
  static String dateShort(DateTime? d) =>
      d == null ? '—' : _digits(DateFormat('yyyy/MM/dd', 'ar').format(d.toLocal()));

  /// تاريخ ووقت للطباعة: «٢٠٢٦/٠٨/٠٣ — ١١:٤٥ م»
  static String dateTime(DateTime? d) => d == null
      ? '—'
      : '${_digits(DateFormat('yyyy/MM/dd', 'ar').format(d.toLocal()))} — '
          '${_digits(DateFormat('h:mm a', 'ar').format(d.toLocal()))}';

  /// وقت نسبي للمنشورات: «قبل ٣ ساعات»
  static String relative(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${count(diff.inMinutes)} دقيقة';
    if (diff.inHours < 24) return 'قبل ${count(diff.inHours)} ساعة';
    if (diff.inDays < 7) return 'قبل ${count(diff.inDays)} يوم';
    if (diff.inDays < 30) return 'قبل ${count(diff.inDays ~/ 7)} أسبوع';
    if (diff.inDays < 365) return 'قبل ${count(diff.inDays ~/ 30)} شهر';
    return date(d);
  }
}
