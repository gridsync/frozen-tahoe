#!/bin/bash
#
# Build frozen Tahoe-LAFS on OS X - virtualenv edition
#

pip install --upgrade pip virtualenv || pip install --user --upgrade pip virtualenv

virtualenv --clear --python=python2 build/venv
source build/venv/bin/activate

python setup.py update_version
pip install .
pip install git+https://github.com/pyinstaller/pyinstaller.git

export PYTHONHASHSEED=1
pyinstaller tahoe.spec
export PYTHONHASHSEED=
