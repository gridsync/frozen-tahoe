# -*- mode: python -*-

from __future__ import print_function

import glob
import hashlib
import os
import shutil
import site
import stat
import sys
import zipfile

# https://github.com/pyinstaller/pyinstaller/wiki/Recipe-remove-tkinter-tcl
sys.modules["FixTk"] = None

options = [
    # Enable unbuffered stdio:
    ("u", None, "OPTION"),
    # Supress CryptographyDeprecationWarning (https://github.com/gridsync/gridsync/issues/313):
    ("W ignore::UserWarning", None, "OPTION"),
]

added_files = [
    ("COPYING.*", "."),
    ("CREDITS", "."),
    ("relnotes.txt", "."),
    ("src/allmydata/web/*.xhtml", "allmydata/web"),
    ("src/allmydata/web/static/*", "allmydata/web/static"),
    ("src/allmydata/web/static/css/*", "allmydata/web/static/css"),
    ("src/allmydata/web/static/img/*.png", "allmydata/web/static/img"),
]

hidden_imports = [
    # Required for `tahoe run`/`tahoe daemonize`:
    "allmydata.client",
    "allmydata.introducer",
    "allmydata.stats",
    # Required always:
    "cffi",
    # Required previously, but possibly no longer necessary:
    "six.moves.html_parser",
    "yaml",
    "zfec",
]

a = Analysis(
    ["static/tahoe.py"],
    pathex=[],
    binaries=None,
    datas=added_files,
    hiddenimports=hidden_imports,
    hookspath=[],
    runtime_hooks=[],
    excludes=["FixTk", "tcl", "tk", "_tkinter", "tkinter", "Tkinter"],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    options,
    exclude_binaries=True,
    name="tahoe",
    debug=False,
    strip=False,
    upx=False,
    console=True,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    name="Tahoe-LAFS",
)


# These directories are not needed and the presence of the dot
# within them has broken macOS notarization in the past.
for path in glob.glob(
    os.path.join("dist", "Tahoe-LAFS", "cryptography-*-py2.7.egg-info")
):
    try:
        shutil.rmtree(path)
    except OSError:
        pass
try:
    shutil.rmtree(os.path.join("dist", "Tahoe-LAFS", "include", "python2.7"))
except OSError:
    pass
try:
    shutil.rmtree(os.path.join("dist", "Tahoe-LAFS", "lib", "python2.7"))
except OSError:
    pass


# The (rustc compiled) python-challenge-bypass-ristretto library
# gets missed by PyInstaller for some reason so add it manually.
os.makedirs(os.path.join("dist", "Tahoe-LAFS", "challenge_bypass_ristretto"))
if hasattr(sys, "real_prefix"):
    if sys.platform == "win32":
        site_packages = site.getsitepackages()[1]
    else:
        site_packages = site.getsitepackages()[0]
else:
    site_packages = site.getusersitepackages()
shutil.copy2(
    glob.glob(
        os.path.join(
            site_packages, "challenge_bypass_ristretto", "_native__lib.*"
        )
    )[0],
    os.path.join("dist", "Tahoe-LAFS", "challenge_bypass_ristretto"),
)


def make_zip(base_name, root_dir=None, base_dir=None):
    zipfile_path = os.path.abspath(base_name)
    if not root_dir:
        root_dir = os.getcwd()
    if not base_dir:
        base_dir = os.getcwd()

    cwd = os.getcwd()
    os.chdir(root_dir)

    paths = []
    for root, directories, files in os.walk(base_dir):
        for file in files:
            paths.append(os.path.join(root, file))
        for directory in directories:
            dirpath = os.path.join(root, directory)
            if os.path.islink(dirpath):
                paths.append(dirpath)
            elif not os.listdir(dirpath):  # Directory is empty
                paths.append(dirpath + "/")

    with zipfile.ZipFile(zipfile_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(paths):
            zinfo = zipfile.ZipInfo(path)
            zinfo.date_time = (2021, 1, 1, 0, 0, 0)
            if path.endswith("/"):
                zinfo.external_attr = (0o755 | stat.S_IFDIR) << 16
                zf.writestr(zinfo, "")
            elif os.path.islink(path):
                zinfo.filename = path  # To strip trailing "/" from dirs
                zinfo.create_system = 3
                zinfo.external_attr = (0o755 | stat.S_IFLNK) << 16
                zf.writestr(zinfo, os.readlink(path))
            else:
                if os.access(path, os.X_OK):
                    zinfo.external_attr = (0o755 | stat.S_IFREG) << 16
                else:
                    zinfo.external_attr = (0o644 | stat.S_IFREG) << 16
                with open(path, "rb") as f:
                    zf.writestr(zinfo, f.read())
    os.chdir(cwd)


def sha256sum(filepath):
    hasher = hashlib.sha256()
    with open(os.path.abspath(filepath), "rb") as f:
        for block in iter(lambda: f.read(4096), b""):
            hasher.update(block)
    return hasher.hexdigest()


zip_path = os.path.join("dist", "Tahoe-LAFS.zip")
make_zip(zip_path, "dist", "Tahoe-LAFS")
print("{}  {}".format(sha256sum(zip_path), zip_path))
