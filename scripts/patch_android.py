"""
Menambal android/app/src/main hasil `flutter create`:
- izin INTERNET (wajib untuk build release)
- nama aplikasi yang tampil di HP: contolustic
"""
import pathlib
import re

MAIN_DIR = pathlib.Path('android/app/src/main')
manifest = MAIN_DIR / 'AndroidManifest.xml'
xml = manifest.read_text(encoding='utf-8')

# 1. Izin internet
if 'android.permission.INTERNET' not in xml:
    xml = xml.replace(
        '<application',
        '    <uses-permission android:name="android.permission.INTERNET" />\n    <application',
        1,
    )

# 2. Nama aplikasi yang tampil di HP
xml = re.sub(
    r'(<application\b[^>]*?android:label=")[^"]*(")',
    r'\g<1>contolustic\g<2>',
    xml,
    count=1,
)

manifest.write_text(xml, encoding='utf-8')
print('AndroidManifest.xml ditambal')
