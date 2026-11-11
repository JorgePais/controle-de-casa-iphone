"""Package an actual macOS-built iOS app; this never builds or signs an app."""
import os
from pathlib import Path
import plistlib
import stat
import sys
import zipfile


def package(app: Path, destination: Path) -> None:
    if not app.is_dir() or app.suffix != '.app':
        raise ValueError('An existing device .app built by Xcode is required')
    with (app / 'Info.plist').open('rb') as source:
        info = plistlib.load(source)
    if 'iPhoneOS' not in info.get('CFBundleSupportedPlatforms', []):
        raise ValueError('A device build is required; simulator apps cannot be installed')
    executable = app / info['CFBundleExecutable']
    if not executable.is_file():
        raise ValueError('The app executable is missing')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(app.rglob('*')):
            name = (Path('Payload') / app.name / path.relative_to(app)).as_posix()
            if path.is_symlink():
                entry = zipfile.ZipInfo(name)
                entry.create_system = 3
                entry.external_attr = (stat.S_IFLNK | 0o777) << 16
                archive.writestr(entry, os.readlink(path))
            elif path.is_file():
                archive.write(path, name)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: package_ipa.py Runner.app destination.ipa')
    package(Path(sys.argv[1]), Path(sys.argv[2]))
