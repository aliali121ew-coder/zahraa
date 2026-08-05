import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/girih_pattern.dart';
import '../../core/widgets/glass.dart';

/// كارت المبلغ الكلي العريض في أعلى الرئيسية.
///
/// **قرارات التصميم** التي تصنع الفرق بين كارت «بسيط» وكارت مصمَّم:
///  • تدرّج ثلاثي المحطات لا لون مسطّح — يعطي السطح عمقاً
///  • علامة مائية هندسية إسلامية بشفافية ٤٪ تكسر فراغ السطح
///  • خط ذهبي شعري يفصل العنوان عن الرقم فيفرض تسلسلاً بصرياً
///  • الرقم بخط الواجهة الثقيل بتتبّع سالب، والعملة منفصلة أصغر وذهبية —
///    فلا يتنافس الرمز مع الرقم على الانتباه
///  • العنوان بالخط النسخي لا بخط الواجهة، فيتباين مع الرقم
class TotalAmountCard extends StatelessWidget {
  const TotalAmountCard({
    super.key,
    required this.total,
    this.onTap,
    this.loading = false,
  });

  final num total;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GoldBorder(
      radius: AppTheme.radiusLarge,
      width: 1.5,
      child: Stack(
        children: [
          // الطبقة ١: التدرّج العميق
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? const [
                          Color(0xFF17603A),
                          Color(0xFF0E3F28),
                          Color(0xFF071F14),
                        ]
                      : const [
                          Color(0xFF1B6B41),
                          Color(0xFF14512F),
                          Color(0xFF0D3A22),
                        ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // الطبقة ٢: العلامة المائية الهندسية
          const Positioned.fill(
            child: ClipRect(
              child: GirihPattern(
                color: AppColors.goldBright,
                opacity: 0.055,
                cell: 58,
              ),
            ),
          ),
          // الطبقة ٣: توهّج علوي خفيف يوحي بانعكاس ضوء على سطح معدني
          Positioned(
            top: -70,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.goldBright.withValues(alpha: 0.16),
                      AppColors.goldBright.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // الطبقة ٤: المحتوى
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppColors.gold.withValues(alpha: 0.08),
              highlightColor: AppColors.gold.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const _GoldRingIcon(icon: Icons.savings_outlined),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'المبلغ الكلي',
                            style: TextStyle(
                              fontFamily: AppTheme.displayFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldBright,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (onTap != null)
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: AppColors.goldBright.withValues(
                                alpha: 0.85,
                              ),
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _GoldRule(),
                    const SizedBox(height: 16),
                    if (loading)
                      const _Skeleton(width: 200, height: 42)
                    else
                      _AmountLine(total: total),
                    const SizedBox(height: 10),
                    Text(
                      'مجموع الاشتراكات والتبرعات النقدية',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textOnDark.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// سطر المبلغ: الرقم ثقيل ومتراصّ، والعملة منفصلة أصغر وذهبية.
class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.total});

  final num total;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        textBaseline: TextBaseline.alphabetic,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Fmt.amount(total),
            maxLines: 1,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 42,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
              height: 1.0,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'د.ع',
            style: TextStyle(
              fontFamily: AppTheme.displayFamily,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.goldBright.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

/// كارت عدد (المتبرعين أو المشتركين) — صف 2×1 تحت كارت المبلغ.
class CountCard extends StatelessWidget {
  const CountCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.badge,
    this.onTap,
    this.loading = false,
  });

  final String label;
  final int count;
  final IconData icon;

  /// شارة صغيرة مثل «٣ متأخرون»
  final String? badge;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      blur: true,
      padding: EdgeInsets.zero,
      onTap: onTap,
      gradient: isDark
          ? const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF123A26), Color(0xFF091E14)],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // خط ذهبي علوي رفيع — تفصيلة صغيرة تعطي الكارت حافة مصمَّمة
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.0),
                  AppColors.gold.withValues(alpha: 0.55),
                  AppColors.gold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _GoldRingIcon(icon: icon, size: 38, iconSize: 18),
                const SizedBox(height: 16),
                if (loading)
                  const _Skeleton(width: 58, height: 30)
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      Fmt.count(count),
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        height: 1.0,
                        color: isDark ? Colors.white : AppColors.textOnLight,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppColors.textOnDarkMuted
                        : AppColors.textOnLightMuted,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.overdue.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.overdue.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.overdue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              badge!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.overdue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// أيقونة داخل حلقة ذهبية — أرقى من المربّع المدوّر المعتاد
class _GoldRingIcon extends StatelessWidget {
  const _GoldRingIcon({required this.icon, this.size = 42, this.iconSize = 20});

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.20),
            AppColors.gold.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.42),
          width: 1,
        ),
      ),
      child: Icon(icon, color: AppColors.goldBright, size: iconSize),
    );
  }
}

/// خط ذهبي شعري يتلاشى عند طرفيه
class _GoldRule extends StatelessWidget {
  const _GoldRule();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.45),
          AppColors.gold.withValues(alpha: 0.12),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ),
    ),
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// عنوان قسم: خط نسخي + خط ذهبي يمتدّ منه، بدل نص عادي بجانب أيقونة.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.icon, this.action});

  final String title;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 9),
        ],
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.displayFamily,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textOnDark
                : AppColors.textOnLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.38),
                  AppColors.gold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}
