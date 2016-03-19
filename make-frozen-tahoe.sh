#!/bin/bash
#
# Build frozen Tahoe-LAFS on OS X - virtualenv edition
#

pip install --upgrade pip virtualenv

virtualenv --clear --python=python2 build/venv
source build/venv/bin/activate

python setup.py update_version
pip install .

pip install pyinstaller
export PYTHONHASHSEED=1
pyinstaller tahoe.spec
python -m zipfile -c dist/Tahoe-LAFS.zip dist/Tahoe-LAFS
export PYTHONHASHSEED=
