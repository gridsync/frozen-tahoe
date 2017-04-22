::
:: Build frozen Tahoe-LAFS on Windows7 (64 bit) - virtualenv edition
::
@echo off

call C:\Python27\python.exe -m pip install --upgrade pip virtualenv

call C:\Python27\python.exe -m virtualenv --clear .\build\venv
call .\build\venv\Scripts\activate

call python setup.py update_version
call pip install .[tor]
call pip install git+https://github.com/pyinstaller/pyinstaller.git

call set PYTHONHASHSEED=1
call pyinstaller -y tahoe.spec
call set PYTHONHASHSEED=
