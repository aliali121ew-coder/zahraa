# جلب خطوط Amiri النسخية — شغّله مرة واحدة بعد استنساخ المستودع.
#
# لماذا لا تُودَع الخطوط في المستودع مباشرة؟ لأن أداة الرفع الآلية لدى
# الوكيل ترمّز الملفات الثنائية مرتين فتُفسدها. جلبها بسكربت أضمن، ويبقي
# المستودع أخفّ. خطوط IBM Plex موجودة أصلاً لأنها رُفعت بـ git مباشرة.
#
#   powershell -ExecutionPolicy Bypass -File tools\fetch_fonts.ps1

$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/google/fonts/main/ofl/amiri'
$dir  = Join-Path $PSScriptRoot '..\assets\fonts'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

foreach ($w in @('Regular','Bold')) {
    $out = Join-Path $dir "Amiri-$w.ttf"
    if ((Test-Path $out) -and ((Get-Item $out).Length -gt 100000)) {
        Write-Host "  موجود مسبقاً: Amiri-$w.ttf"
        continue
    }
    Write-Host "  تنزيل Amiri-$w.ttf ..."
    Invoke-WebRequest -Uri "$base/Amiri-$w.ttf" -OutFile $out
    $kb = [math]::Round((Get-Item $out).Length / 1KB)
    if ($kb -lt 100) { throw "فشل التنزيل: Amiri-$w.ttf حجمه $kb KB فقط" }
    Write-Host "  تم: Amiri-$w.ttf ($kb KB)"
}
Write-Host "`nجاهز. شغّل الآن: flutter pub get"
