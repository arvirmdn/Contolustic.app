"""
Menambal android/app/src/main hasil `flutter create` agar pemutaran
bisa berjalan di background dengan notifikasi (just_audio_background).
"""
import pathlib
import re

MAIN_DIR = pathlib.Path('android/app/src/main')
manifest = MAIN_DIR / 'AndroidManifest.xml'
xml = manifest.read_text(encoding='utf-8')

# 1. Izin
perms = [
    'android.permission.INTERNET',
    'android.permission.WAKE_LOCK',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
    'android.permission.POST_NOTIFICATIONS',
]
perm_xml = ''.join(
    f'    <uses-permission android:name="{p}" />\n'
    for p in perms if p not in xml
)
xml = xml.replace('<application', perm_xml + '    <application', 1)

# 2. Service pemutar musik
service_xml = '''        <service
            android:name="com.ryanheise.just_audio_background.JustAudioBackgroundPlaybackService"
            android:foregroundServiceType="mediaPlayback"
            android:exported="true">
            <intent-filter>
                <action android:name="android.media.browse.MediaBrowserService" />
            </intent-filter>
        </service>
'''
if 'JustAudioBackgroundPlaybackService' not in xml:
    xml = xml.replace('</application>', service_xml + '    </application>', 1)

# 3. Nama aplikasi yang tampil di HP
xml = re.sub(
    r'(<application\b[^>]*?android:label=")[^"]*(")',
    r'\g<1>contolustic\g<2>',
    xml,
    count=1,
)

manifest.write_text(xml, encoding='utf-8')
print('AndroidManifest.xml ditambal')

# 4. MainActivity -> FlutterFragmentActivity (dibutuhkan plugin audio)
for path in MAIN_DIR.rglob('MainActivity.*'):
    src = path.read_text(encoding='utf-8')
    src = re.sub(
        r'import io\.flutter\.embedding\.android\.FlutterActivity\b',
        'import io.flutter.embedding.android.FlutterFragmentActivity',
        src,
    )
    src = re.sub(r':\s*FlutterActivity\(\)', ': FlutterFragmentActivity()', src)
    src = re.sub(r'extends\s+FlutterActivity\b', 'extends FlutterFragmentActivity', src)
    path.write_text(src, encoding='utf-8')
    print(f'{path} diperbarui')
