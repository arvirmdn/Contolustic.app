# Metrolist (versi 0.1)

Pemutar musik Flutter yang mengambil lagu dari YouTube, dengan fitur:

- Cari lagu dan putar langsung (streaming audio, tanpa video)
- Pemutaran di background dengan notifikasi kontrol
- Lirik tersinkron (sumber: lrclib.net)
- Unduh lagu untuk diputar offline

Tidak memakai server Railway. Semua pengambilan data YouTube dilakukan di HP.

## Struktur

```
lib/
  main.dart                 entry point + navigasi bawah
  models/song.dart          model lagu
  services/
    youtube_service.dart    cari & ambil stream (satu-satunya yang bicara ke YouTube)
    player_service.dart     pemutar (just_audio + notifikasi background)
    download_service.dart   unduh & daftar lagu offline
    lyrics_service.dart     ambil & parse lirik LRC
  screens/
    home_screen.dart        pencarian
    player_screen.dart      layar pemutar + lirik
    downloads_screen.dart   daftar unduhan
  widgets/
    mini_player.dart        bar pemutar di bawah
    thumb.dart              thumbnail
scripts/patch_android.py    menambal AndroidManifest saat build
codemagic.yaml              konfigurasi build APK di Codemagic
```

## Cara menjalankan di Codemagic

1. Buat repo baru di GitHub, lalu upload semua isi folder ini (termasuk `codemagic.yaml`).
2. Di Codemagic: **Add application** → pilih repo GitHub tersebut → pilih **Flutter App**.
3. Codemagic akan membaca `codemagic.yaml`. Klik **Start new build** pada workflow `android-apk`.
4. Setelah selesai, unduh file `.apk` dari bagian **Artifacts** dan pasang di HP.

Folder `android/` tidak disimpan di repo. Codemagic membuatnya ulang setiap build lewat `flutter create`, lalu menjalankan `scripts/patch_android.py`.

## Catatan

- Pustaka `youtube_explode_dart` mengikuti perubahan internal YouTube. Jika suatu hari pencarian atau pemutaran gagal, biasanya cukup menaikkan versinya di `pubspec.yaml`.
- Mengunduh atau memutar konten YouTube bisa melanggar Ketentuan Layanan YouTube. Aplikasi ini cocok untuk pemakaian pribadi. Hindari mempublikasikannya ke Play Store.
- Lirik dicari berdasarkan judul dan artis dari YouTube, jadi kadang tidak cocok untuk video yang judulnya tidak rapi.
