@echo off

if "%1"=="clean" call :clean
if "%1"=="test" call :test
if "%1"=="frozen-tahoe" call :frozen-tahoe
if "%1"=="all" call :all
if "%1"=="" call :all
goto :eof

:clean
call rmdir /s /q .\build
call rmdir /s /q .\dist
goto :eof

:test
call py -2.7 .\test.py
goto :eof

:frozen-tahoe
call mkdir dist
call mkdir build
call py -2.7 -m virtualenv --clear .\build\venv-tahoe
call .\build\venv-tahoe\Scripts\activate
call python -m pip install --upgrade setuptools pip
call git clone https://github.com/tahoe-lafs/tahoe-lafs.git .\build\tahoe-lafs
call pushd .\build\tahoe-lafs
call git checkout tahoe-lafs-1.14.0
call copy ..\..\patches\tahoe-lafs-inject-zkapauthorizer-plugin.patch .
call git apply --ignore-space-change --ignore-whitespace tahoe-lafs-inject-zkapauthorizer-plugin.patch
call copy ..\..\patches\tahoe-lafs-rsa-public-exponent-65537.patch .
call git apply --ignore-space-change --ignore-whitespace tahoe-lafs-rsa-public-exponent-65537.patch
call python setup.py update_version
:: The "hkdf" module fails to install on Windows when the USER environment variable is set to "vagrant":
:: https://github.com/casebeer/python-hkdf/blob/ba0e2eee8f50cc84706f816dbc57897319e2250c/setup.py#L11
:: So work around this workaround/bug(?) by temporarily changing the case of the value...
if "%USER%"=="vagrant" (set USER=Vagrant)
call python -m pip install -r ..\..\requirements.txt
if "%USER%"=="Vagrant" (set USER=vagrant)
call git clone https://github.com/PrivateStorageio/ZKAPAuthorizer .\build\ZKAPAuthorizer
call copy ..\..\patches\zkapauthorizer-retry-interval.patch .\build\ZKAPAuthorizer
call pushd .\build\ZKAPAuthorizer
call git checkout 632d2cdc96bb2975d8aff573a3858f1a6aae9963
call git apply --ignore-space-change --ignore-whitespace zkapauthorizer-retry-interval.patch
call python -m pip install .
call popd
call python -m pip install .
call python -m pip list
call copy ..\..\pyinstaller.spec pyinstaller.spec
call set PYTHONHASHSEED=1
call python -m PyInstaller pyinstaller.spec
call deactivate
call popd
call move build\tahoe-lafs\dist\Tahoe-LAFS dist
call move build\tahoe-lafs\dist\* dist
goto :eof

:all
call :frozen-tahoe
goto :eof
