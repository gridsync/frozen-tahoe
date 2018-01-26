#!/bin/bash
#
# Build frozen Tahoe-LAFS on OS X - virtualenv edition
#

pip install --upgrade pip virtualenv || pip install --user --upgrade pip virtualenv

virtualenv --clear --python=python2 build/venv
source build/venv/bin/activate

python setup.py update_version
pip install .[tor]
pip install git+https://github.com/pyinstaller/pyinstaller.git

# Recompile libsodium for the target machine; needed for older Macs
case `uname` in \
    Darwin) pip install -I --no-deps --no-binary PyNaCl PyNaCl ;; \
esac

export PYTHONHASHSEED=1
pyinstaller -y tahoe.spec
export PYTHONHASHSEED=
