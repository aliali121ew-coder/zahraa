import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';
import '../models/contributor_model.dart';
import '../models/enums.dart';

/// كارت مساهم (متبرع أو مشترك) داخل قائمة عمودية.
///
/// **قرار أداء:** `GlassCard(blur: false)` — نفس المظهر الزجاجي بتدرّج مطلي
/// مسبقاً بلا [BackdropFilter]. لو استُخدم التمويه هنا لانهار معدّل الإطارات،
/// لأن كل عنصر في القائمة سيعيد حساب التمويه في كل إطار.
///
/// **قرارات التصميم:** الاسم بالخط النسخي والمبلغ بخط الواجهة داخل حبّة
/// ذهبية، فيتباين النص العربي عن الرقم. المراتب الثلاث الأولى تحصل على
/// حلقة ميدالية متدرّجة حول الصورة بدل أيقونة صغيرة جانبية.
class ContributorTile extends StatelessWidget {
  const ContributorTile({
    super.key,
    required this.contributor,
    this.rank,
    this.onTap,
    this.showStatus = false,
    this.hideName = false,
  });

  final ContributorModel contributor;

  /// المرتبة في قائمة الأعلى تبرّعاً — الأوائل الثلاثة يحصلون على ميدالية
  final int? rank;
  final VoidCallback? onTap;

  /// يعرض شارة مسدد/متأخر — للمشتركين
  final bool showStatus;

  /// يخفي الاسم لدور العضو الذي لا يُصرَّح له برؤية الأسماء
  final bool hideName;

  bool get _hasMedal => rank != null && rank! <= 3;

  /// ألوان الميدالية: ذهبي ثم فضّي ثم برونزي
  List<Color> get _medalColors => switch (rank) {
        1 => const [Color(0xFFF3DDA9), AppColors.gold, Color(0xFF8A6A33)],
        2 => const [Color(0xFFE8E8E8), Color(0xFFB9BDC2), Color(0xFF7C8288)],
        _ => const [Color(0xFFD9A87C), AppColors.bronze, Color(0xFF6B573C)],
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = contributor;
    final amount = c.isSubscriber ? c.subscriptionAmount : c.totalPaid;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      borderColor: _hasMedal ? AppColors.gold.withValues(alpha: 0.38) : null,
      gradient: _hasMedal && isDark
          ? LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                AppColors.gold.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.035),
              ],
            )
          : null,
      child: Row(
        children: [
          _Avatar(
            contributor: c,
            rank: rank,
            hideName: hideName,
            medalColors: _hasMedal ? _medalColors : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hideName ? 'مساهم مُخفى الاسم' : c.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: isDark
                        ? AppColors.textOnDark
                        : AppColors.textOnLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // المبلغ داخل حبّة — يفصله بصرياً عن بقية النص
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.26),
                          ),
                        ),
                        child: Text(
                          Fmt.moneyShort(amount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.goldBright
                                : AppColors.goldDark,
                          ),
                        ),
                      ),
                    ),
                    if (c.isSubscriber && c.subscriptionType != null) ...[
                      const SizedBox(width: 9),
                      Text(
                        c.subscriptionType!.label,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (!c.isSubscriber && c.lastPaymentAt != null) ...[
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          Fmt.dateShort(c.lastPaymentAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showStatus) ...[
            const SizedBox(width: 8),
            _StatusChip(status: c.paymentStatus),
          ],
          if (c.pendingSync) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.cloud_upload_outlined,
              size: 16,
              color: AppColors.pending.withValues(alpha: 0.9),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.contributor,
    this.rank,
    this.hideName = false,
    this.medalColors,
  });

  final ContributorModel contributor;
  final int? rank;
  final bool hideName;

  /// إن مُرِّرت، تُرسم حلقة ميدالية متدرّجة حول الصورة
  final List<Color>? medalColors;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    const ring = 2.5;
    final url = contributor.photoUrl;
    final name = contributor.fullName.trim();
    final letter = hideName || name.isEmpty ? '؟' : name.characters.first;

    Widget inner;
    if (url != null && url.isNotEmpty && !hideName) {
      inner = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // صورة مصغّرة في الذاكرة: يمنع فكّ صور ضخمة داخل قائمة طويلة
        memCacheWidth: 144,
        placeholder: (_, _) => _letterBox(context, letter),
        errorWidget: (_, _, _) => _letterBox(context, letter),
      );
    } else {
      inner = _letterBox(context, letter);
    }

    Widget avatar = ClipOval(
      child: SizedBox(width: size, height: size, child: inner),
    );

    // حلقة الميدالية للمراتب الثلاث الأولى
    if (medalColors != null) {
      avatar = Container(
        padding: const EdgeInsets.all(ring),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [...medalColors!, medalColors!.first],
          ),
          boxShadow: [
            BoxShadow(
              color: medalColors![1].withValues(alpha: 0.35),
              blurRadius: 10,
            ),
          ],
        ),
        child: avatar,
      );
    }

    if (rank == null) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        PositionedDirectional(
          bottom: -3,
          start: -3,
          child: Container(
            width: 21,
            height: 21,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: medalColors != null
                  ? LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [medalColors![0], medalColors![2]],
                    )
                  : null,
              color: medalColors == null ? AppColors.greenMid : null,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            child: Text(
              Fmt.count(rank),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1,
                color: medalColors != null
                    ? AppColors.greenAbyss
                    : AppColors.textOnDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _letterBox(BuildContext context, String letter) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.gold.withValues(alpha: 0.30),
              AppColors.green.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontFamily: AppTheme.displayFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.goldBright,
            ),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final paid = status == PaymentStatus.paid;
    final color = paid ? AppColors.paid : AppColors.overdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
