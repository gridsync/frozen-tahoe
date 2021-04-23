import hashlib
import os
import shutil
import subprocess
import sys
import tempfile


def sha256sum(filepath):
    hasher = hashlib.sha256()
    with open(filepath, "rb") as f:
        for block in iter(lambda: f.read(4096), b""):
            hasher.update(block)
    return hasher.hexdigest()


def call_make_clean_all():
    if sys.platform == "win32":
        subprocess.call(["make.bat", "clean"])
        subprocess.call(["make.bat", "all"])
    elif sys.platform == "darwin":
        subprocess.call(
            ["arch", "-x86_64", "make", "clean", "all"]
        )
    else:
        subprocess.call(["make", "clean", "all"])


if __name__ == "__main__":
    zipfile = os.path.join("dist", "Tahoe-LAFS.zip")
    if not os.path.exists(zipfile):
        call_make_clean_all()
    zipfile_tmp = os.path.join(tempfile.mkdtemp(), "Tahoe-LAFS-1.zip")
    shutil.move(zipfile, zipfile_tmp)
    call_make_clean_all()
    zipfile1 = os.path.join("dist", "Tahoe-LAFS-1.zip")
    shutil.move(zipfile_tmp, zipfile1)
    checksum1 = sha256sum(zipfile1)
    print("{}  {}".format(checksum1, zipfile1))
    checksum2 = sha256sum(zipfile)
    print("{}  {}".format(checksum2, zipfile))
    if checksum1 == checksum2:
        print("Hashes match; success!")
    else:
        print("Hashes don't match; running diffoscope...")
        subprocess.call(["diffoscope", zipfile, zipfile1])
        sys.exit(1)
