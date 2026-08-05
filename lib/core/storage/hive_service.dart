import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// طبقة التخزين المحلي المشفّر.
///
/// كل صندوق يخزّن **خرائط JSON** لا كائنات Dart، وهذا مقصود: يتجنّب توليد
/// TypeAdapter بـ build_runner الذي يفشل بصمت عند تعديل النماذج ويعطّل
/// البناء. الثمن تحويل يدوي بسيط، والمقابل بناء لا يتعطّل أبداً.
///
/// التشفير: AES بمفتاح ٢٥٦ بت يُولَّد مرة واحدة ويُحفظ في
/// Android Keystore / iOS Keychain عبر flutter_secure_storage، فلا يوجد
/// المفتاح في الكود ولا في ملفات التطبيق.
class HiveService {
  HiveService._();
  static final instance = HiveService._();

  static const _keyName = 'mawkib_hive_key_v1';
  // final لا const: المُنشئ الثابت غير متاح في كل إصدارات الحزمة
  static final _secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _ready = false;
  bool get isReady => _ready;

  /// الصناديق التي تعذّر فتحها فأُعيد إنشاؤها، أي **فُقد محتواها المخزّن**.
  ///
  /// نحتفظ بالقائمة ولا نبتلع الحدث بصمت: التطبيق يعرف أن عليه إعادة
  /// المزامنة من السيرفر، ويستطيع إخبار المستخدم بدل أن تختفي بياناته
  /// دون أثر.
  final List<String> recoveredBoxes = [];

  /// هل فُقدت بيانات محلية في آخر إقلاع؟
  bool get didLoseLocalData => recoveredBoxes.isNotEmpty;

  Future<void> init() async {
    if (_ready) return;

    // initFlutter يكفي عادةً، لكنه يفشل على بعض الأجهزة والإصدارات.
    // نجرّب مسار التخزين الصريح أولاً ثم نرتدّ إليه.
    try {
      final dir = await getApplicationSupportDirectory();
      Hive.init('${dir.path}/mawkib_zahra_db');
    } catch (_) {
      await Hive.initFlutter('mawkib_zahra_db');
    }

    final cipher = HiveAesCipher(await _encryptionKey());

    for (final name in const [
      AppConfig.boxContributors,
      AppConfig.boxPayments,
      AppConfig.boxDonations,
      AppConfig.boxPosts,
      AppConfig.boxStories,
      AppConfig.boxStats,
      AppConfig.boxOutbox,
    ]) {
      await _openEncrypted(name, cipher);
    }

    // صندوق الإعدادات غير مشفّر: لا يحوي بيانات حساسة ويُقرأ قبل التشفير
    await _openSettings();
    _ready = true;
  }

  /// يفتح صندوقاً مشفّراً، ويتعافى من التلف بإعادة الإنشاء **مع تسجيل الفقد**.
  ///
  /// الفشل الشائع سببه تغيّر مفتاح التشفير (مسح بيانات التطبيق مثلاً) أو
  /// ملف تالف. في الحالتين لا سبيل لقراءة المحتوى، فإعادة الإنشاء هي الحل
  /// الوحيد لتفادي تعطّل التطبيق عند الإقلاع.
  ///
  /// ⚠️ استثناء مقصود: صندوق **الطابور** (outbox) يحوي كتابات لم تُرفع بعد،
  /// وحذفه يعني ضياعها نهائياً. لذلك نعيد رمي الخطأ بدل حذفه صامتين، فيظهر
  /// العطل بوضوح بدل أن يبتلع عمل المستخدم.
  Future<void> _openEncrypted(String name, HiveAesCipher cipher) async {
    try {
      await Hive.openBox<String>(name, encryptionCipher: cipher);
      return;
    } catch (e) {
      if (name == AppConfig.boxOutbox) rethrow;
    }
    try {
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox<String>(name, encryptionCipher: cipher);
      recoveredBoxes.add(name);
    } catch (_) {
      // آخر محاولة: صندوق في الذاكرة فقط، فيعمل التطبيق ولا يتعطّل
      await Hive.openBox<String>(name, bytes: Uint8List(0));
      recoveredBoxes.add(name);
    }
  }

  Future<void> _openSettings() async {
    try {
      await Hive.openBox<dynamic>(AppConfig.boxSettings);
    } catch (_) {
      await Hive.deleteBoxFromDisk(AppConfig.boxSettings);
      await Hive.openBox<dynamic>(AppConfig.boxSettings);
      recoveredBoxes.add(AppConfig.boxSettings);
    }
  }

  Future<List<int>> _encryptionKey() async {
    final existing = await _secure.read(key: _keyName);
    if (existing != null) {
      try {
        final k = base64Decode(existing);
        if (k.length == 32) return k;
      } catch (_) {
        // مفتاح تالف — نولّد بديلاً
      }
    }
    final rnd = Random.secure();
    final key = List<int>.generate(32, (_) => rnd.nextInt(256));
    await _secure.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  Box<String> box(String name) => Hive.box<String>(name);
  Box<dynamic> get settings => Hive.box<dynamic>(AppConfig.boxSettings);

  // ── قراءة وكتابة قوائم JSON ─────────────────────────────────

  /// يقرأ كل عناصر صندوق كقائمة خرائط
  List<Map<String, dynamic>> readAll(String boxName) {
    final b = box(boxName);
    final out = <Map<String, dynamic>>[];
    for (final raw in b.values) {
      try {
        out.add(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // عنصر تالف — نتجاهله بدل إسقاط الشاشة كاملة
      }
    }
    return out;
  }

  Map<String, dynamic>? readOne(String boxName, String id) {
    final raw = box(boxName).get(id);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> put(String boxName, String id, Map<String, dynamic> data) =>
      box(boxName).put(id, jsonEncode(data));

  /// يستبدل محتوى الصندوق بالكامل — يُستخدم بعد مزامنة ناجحة
  Future<void> replaceAll(
    String boxName,
    List<Map<String, dynamic>> items,
    String Function(Map<String, dynamic>) idOf,
  ) async {
    final b = box(boxName);
    await b.clear();
    await b.putAll({for (final it in items) idOf(it): jsonEncode(it)});
  }

  Future<void> delete(String boxName, String id) => box(boxName).delete(id);

  /// حجم الذاكرة المؤقتة بعدد العناصر — لشاشة الإعدادات
  int get cachedItemsCount => [
        AppConfig.boxContributors,
        AppConfig.boxPayments,
        AppConfig.boxDonations,
        AppConfig.boxPosts,
        AppConfig.boxStories,
      ].fold<int>(0, (sum, n) => sum + box(n).length);

  /// مسح كل البيانات المخزّنة محلياً — لا يمسّ طابور المزامنة
  Future<void> clearCache() async {
    for (final n in const [
      AppConfig.boxContributors,
      AppConfig.boxPayments,
      AppConfig.boxDonations,
      AppConfig.boxPosts,
      AppConfig.boxStories,
      AppConfig.boxStats,
    ]) {
      await box(n).clear();
    }
  }
}
