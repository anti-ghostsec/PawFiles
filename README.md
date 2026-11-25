# Files

A file manager for Android that stays on your phone. It's a lighter,
privacy-first fork of [Material Files](https://github.com/zhanghai/MaterialFiles)
by Hai Zhang, with everything that reaches the network taken out.

It keeps what makes Material Files good:

- Material Design throughout, with breadcrumbs.
- Root support, through root or Shizuku.
- Archives: view, extract and create zip, 7z, tar and other formats.
- Linux-aware: symbolic links, permissions and SELinux context.
- Themes, including night mode and true black.

## What's different from Material Files

- **No network at all.** The FTP, SFTP, SMB and WebDAV support is gone, and
  so is the FTP server. Their libraries are gone too: SMBJ, SMBJ-RPC,
  jcifs-ng, sshj, dav4jvm, Apache Commons Net, Apache FtpServer and MINA,
  Bouncy Castle, Guava and SLF4J. The app has no internet permission; it's
  removed even if a library asks for it. Every release build checks the APK
  for network permissions and fails if it finds any.
- **No crash reporting or analytics.** The Firebase build (Analytics and
  Crashlytics) is gone.
- **No logs.** Release builds strip every call to Android's log, and every
  printed stack trace, from the app and its libraries. Java's own logging,
  which Android also sends to its log, is switched off as the app starts.
  The native libraries that come built (libarchive's and libselinux's) are
  relinked to a stand-in for Android's log that does nothing, and the
  app's own native code logs nothing. A crash just closes the app, without
  Android's crash report in the phone's log. Every release build checks the
  APK for anything left that could log (`tools/log-audit.sh`).
- **No backups.** Nothing of the app's (settings, bookmarks) goes to cloud
  backups or device transfers.
- **Its own app.** It's called "Files", with its own icon and app ID
  (`io.github.files.app`), so it installs beside Material Files rather than
  replacing it. It starts fresh, with no settings carried over.

The permissions it keeps are the ones a file manager uses on the phone
itself: all-files access, installing APKs you open, notifications for long
copies, launcher shortcuts, and the list of installed apps (for their icons
and "Open with").

## Releases

Every push to `main` of [PawFiles](https://github.com/anti-ghostsec/PawFiles) builds `files-android.apk` (one APK for every phone)
and publishes it as the newest release. Signing happens in a separate job
that runs none of the build's code. The signing certificate's SHA-256 is in
`release-cert.sha256`.

## License and credit

Files is Material Files, changed as described above (from November 2026),
and like Material Files it's under the [GNU General Public License,
version 3](LICENSE).

- Material Files is copyright © 2018 Hai Zhang and its contributors. Its
  source files keep their copyright notices.
- The libraries it still uses are listed, with their licenses, in the app
  under About → Licenses.
- Files is not made or endorsed by Material Files' author. Please don't
  send them reports about this fork.
