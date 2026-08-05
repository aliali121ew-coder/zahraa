#!/usr/bin/env bash
# جلب خطوط Amiri النسخية — يُشغَّل بعد الاستنساخ وفي CI قبل البناء.
# انظر tools/fetch_fonts.ps1 لشرح سبب عدم إيداعها في المستودع.
set -euo pipefail

BASE="https://raw.githubusercontent.com/google/fonts/main/ofl/amiri"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/assets/fonts"
mkdir -p "$DIR"

for w in Regular Bold; do
  out="$DIR/Amiri-$w.ttf"
  if [ -f "$out" ] && [ "$(stat -c%s "$out" 2>/dev/null || stat -f%z "$out")" -gt 100000 ]; then
    echo "  موجود مسبقاً: Amiri-$w.ttf"
    continue
  fi
  echo "  تنزيل Amiri-$w.ttf ..."
  curl -sSL --max-time 90 -o "$out" "$BASE/Amiri-$w.ttf"
  sz=$(stat -c%s "$out" 2>/dev/null || stat -f%z "$out")
  if [ "$sz" -lt 100000 ]; then
    echo "  فشل التنزيل: الحجم $sz بايت فقط" >&2
    rm -f "$out"; exit 1
  fi
  echo "  تم: Amiri-$w.ttf ($((sz/1024)) KB)"
done
echo
echo "جاهز. شغّل الآن: flutter pub get"
