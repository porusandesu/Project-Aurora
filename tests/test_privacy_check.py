import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import privacy_check as pc  # noqa: E402


def make(root: Path, files: dict[str, str]) -> Path:
    for name, text in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    return root


PUBSPEC = "name: demo\ndependencies:\n  flutter:\n    sdk: flutter\n  sqflite: ^2.0.0\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n"
ALLOWED = "flutter\nflutter_test\nsqflite\n"


class PrivacyCheckTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_clean_project_passes(self):
        make(self.root, {"pubspec.yaml": PUBSPEC, "tools/allowed_dependencies.txt": ALLOWED, "lib/main.dart": "void main() {}\n"})
        self.assertEqual(pc.run(self.root), 0)

    def test_unlisted_dependency_fails(self):
        make(self.root, {"pubspec.yaml": PUBSPEC + "", "tools/allowed_dependencies.txt": "flutter\nflutter_test\n"})
        self.assertTrue(any("sqflite" in e for e in pc.check_dependencies(self.root)))

    def test_tracking_package_fails_even_if_listed(self):
        spec = PUBSPEC.replace("sqflite: ^2.0.0", "firebase_analytics: ^1.0.0")
        make(self.root, {"pubspec.yaml": spec, "tools/allowed_dependencies.txt": ALLOWED + "firebase_analytics\n"})
        self.assertTrue(any("tracking" in e for e in pc.check_dependencies(self.root)))

    def test_network_call_fails_unless_allowlisted(self):
        make(self.root, {"lib/a.dart": "import 'package:http/http.dart' as http;\n"})
        self.assertEqual(len(pc.check_network(self.root)), 1)
        make(self.root, {"tools/network_allowlist.txt": "lib/a.dart\n"})
        self.assertEqual(pc.check_network(self.root), [])

    def test_unapproved_permission_fails(self):
        manifest = '<manifest><uses-permission android:name="android.permission.INTERNET"/></manifest>'
        make(self.root, {"android/app/src/main/AndroidManifest.xml": manifest})
        self.assertEqual(len(pc.check_permissions(self.root)), 1)
        make(self.root, {"tools/approved_permissions.txt": "android.permission.INTERNET\n"})
        self.assertEqual(pc.check_permissions(self.root), [])

    def test_ios_location_key_fails(self):
        plist = "<dict><key>NSLocationWhenInUseUsageDescription</key><string>x</string></dict>"
        make(self.root, {"ios/Runner/Info.plist": plist})
        self.assertEqual(len(pc.check_permissions(self.root)), 1)

    def test_local_path_fails(self):
        bad_path = "/ho" + "me/someone/project"  # split so this file does not match itself
        make(self.root, {"notes.json": '{"root": "' + bad_path + '"}\n'})
        errors = pc.check_paths(self.root, [self.root / "notes.json"])
        self.assertEqual(len(errors), 1)

    def test_backup_must_be_disabled(self):
        make(self.root, {"android/app/src/main/AndroidManifest.xml": "<manifest><application/></manifest>"})
        self.assertEqual(len(pc.check_backup(self.root)), 1)
        make(self.root, {"android/app/src/main/AndroidManifest.xml": '<manifest><application android:allowBackup="false"/></manifest>'})
        self.assertEqual(pc.check_backup(self.root), [])

    def test_private_term_fails_without_echoing_it(self):
        make(self.root, {"README.md": "hello secretword here\n"})
        errors, _ = pc.check_private_terms(self.root, [self.root / "README.md"], r"secretword|othername")
        self.assertEqual(len(errors), 1)
        self.assertNotIn("secretword", errors[0])

    def test_private_term_check_skips_when_not_configured(self):
        errors, note = pc.check_private_terms(self.root, [], None)
        self.assertEqual(errors, [])
        self.assertIn("skipped", note)


if __name__ == "__main__":
    unittest.main()
