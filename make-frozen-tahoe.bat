::
:: Build frozen Tahoe-LAFS on Windows7 (64 bit) - virtualenv edition
::
@echo off

call C:\Python27\python.exe -m pip install --upgrade pip virtualenv

call C:\Python27\python.exe -m virtualenv --clear .\build\venv
call .\build\venv\Scripts\activate

call python setup.py update_version
call pip install . 

call pip install pyinstaller==3.1.1
call set PYTHONHASHSEED=1
call pyinstaller tahoe.spec
call python -m zipfile -c dist\Tahoe-LAFS.zip dist\Tahoe-LAFS
call set PYTHONHASHSEED=
