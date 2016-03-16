::
:: Build frozen Tahoe-LAFS on Windows7 (64 bit) - virtualenv edition
::
::
:: This script assumes that the following dependencies have already been 
:: downloaded and properly installed:
::
::      Python 2.7: https://www.python.org/
::      Microsoft Visual C++ Compiler for Python 2.7: https://www.microsoft.com/en-us/download/details.aspx?id=44266
::      ActiveState Perl: https://www.activestate.com/activeperl/downloads
::      Git: https://git-scm.com/download/win
::          (select "Use Git from the Windows Command Prompt" and "Checkout
::          as-is" in setup wizard)
::
:: The following source packages must also be downloaded and unpacked (to 
:: C:\Users\%USERNAME%\Downloads in this case):
::
::      OpenSSL (version 1.0.2g at the time of writing): https://www.openssl.org/source/
::      pyOpenSSL 0.13.1: https://pypi.python.org/pypi/pyOpenSSL/0.13.1
::
:: Lastly, in the event of a missing 'vcvarsall.bat' error, change line 266
:: in Python27\Lib\distutils\msvc9compiler.py to point directly to the file,
:: e.g.:
::
::      vcvarsall = "C:/Users/Buildbot/AppData/Local/Programs/Common/Microsoft/Visual C++ for Python/9.0/vcvarsall.bat"
::

@echo off

if "%1"=="--with-openssl" call :openssl
call :frozen-tahoe
goto :eof

:: Adapted from https://github.com/tahoe-lafs/tahoe-lafs/blob/195.windows-packaging.10/docs/build/windows-installer.rst
:openssl
call "C:\Users\%USERNAME%\AppData\Local\Programs\Common\Microsoft\Visual C++ for Python\9.0\vcvarsall.bat" amd64
call pushd C:\Users\%USERNAME%\Downloads\openssl-1.0.2g
call mkdir c:\dist
call perl Configure VC-WIN64A --prefix=c:\dist\openssl64 no-asm enable-tlsext
call ms\do_win64a.bat
call nmake -f ms\ntdll.mak
call nmake -f ms\ntdll.mak install
call popd
goto :eof

:pyopenssl
call "C:\Users\%USERNAME%\AppData\Local\Programs\Common\Microsoft\Visual C++ for Python\9.0\vcvarsall.bat" x86_amd64
call pushd C:\Users\%USERNAME%\Downloads\pyOpenSSL-0.13.1
call set PYCA_WINDOWS_LINK_TYPE=dynamic
call set LIB=c:\dist\openssl64\lib;%LIB%
call set INCLUDE=c:\dist\openssl64\include;%INCLUDE%
call set PATH=c:\dist\openssl64\bin;%PATH%
call python setup.py build
call python setup.py install
call popd
goto :eof

:frozen-tahoe
call C:\Python27\python.exe -m pip install --upgrade virtualenv
call C:\Python27\python.exe -m virtualenv --clear .\build\venv
call .\build\venv\Scripts\activate
call pip install --upgrade pypiwin32
call :pyopenssl
call python setup.py build
call pip install --upgrade .
:: Ugly hack to disable Tahoe-LAFS' setuptools requirement. Needed for frozen builds.
call python -c "with open('build\\venv\\Lib\\site-packages\\allmydata\\_auto_deps.py') as f, open('_auto_deps.py', 'w+') as n: n.write(f.read().replace('""setuptools >= 0.6c6""','#""setuptools >= 0.6c6""'))"
call move _auto_deps.py build\venv\Lib\site-packages\allmydata\_auto_deps.py
call pip install --upgrade pyinstaller
call set PYTHONHASHSEED=1
call pyinstaller --noconfirm tahoe.spec
call python -m zipfile -c dist\Tahoe-LAFS.zip dist\Tahoe-LAFS
call set PYTHONHASHSEED=
call .\build\venv\Scripts\deactivate
goto :eof

