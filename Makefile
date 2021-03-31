.DEFAULT_GOAL := all
SHELL := /bin/bash
.PHONY: clean frozen-tahoe all

clean:
	rm -rf build/
	rm -rf dist/

frozen-tahoe:
	mkdir -p dist
	mkdir -p build/tahoe-lafs
	python3 -m virtualenv --clear --python=python2 build/venv-tahoe
	# CPython2 virtualenvs are (irredeemably?) broken on Apple Silicon
	# so allow falling back to the user environment.
	# https://github.com/pypa/virtualenv/issues/2023
	# https://github.com/pypa/virtualenv/issues/2024
	source build/venv-tahoe/bin/activate && \
	python --version || deactivate && \
	git clone https://github.com/tahoe-lafs/tahoe-lafs.git build/tahoe-lafs && \
	pushd build/tahoe-lafs && \
	git checkout tahoe-lafs-1.14.0 && \
	cp ../../patches/tahoe-lafs-inject-zkapauthorizer-plugin.patch . && \
	git apply tahoe-lafs-inject-zkapauthorizer-plugin.patch && \
	cp ../../patches/tahoe-lafs-rsa-public-exponent-65537.patch . && \
	git apply tahoe-lafs-rsa-public-exponent-65537.patch && \
	python setup.py update_version && \
	export CFLAGS=-g0 && \
	python -m pip install -r ../../requirements.txt && \
	git clone https://github.com/PrivateStorageio/ZKAPAuthorizer build/ZKAPAuthorizer && \
	cp ../../patches/zkapauthorizer-retry-interval.patch build/ZKAPAuthorizer && \
	pushd build/ZKAPAuthorizer && \
	git checkout 632d2cdc96bb2975d8aff573a3858f1a6aae9963 && \
	git apply zkapauthorizer-retry-interval.patch && \
	python -m pip install . && \
	popd && \
	python -m pip install . && \
	python -m pip list && \
	export PYTHONHASHSEED=1 && \
	cp ../../pyinstaller.spec pyinstaller.spec && \
	python -m PyInstaller pyinstaller.spec && \
	rm -rf dist/Tahoe-LAFS/cryptography-*-py2.7.egg-info && \
	rm -rf dist/Tahoe-LAFS/include/python2.7 && \
	rm -rf dist/Tahoe-LAFS/lib/python2.7 && \
	mkdir -p dist/Tahoe-LAFS/challenge_bypass_ristretto && \
	cp -R $$(python -c 'import site, sys;print site.getsitepackages()[0] if hasattr(sys, "real_prefix") else site.getusersitepackages()')/challenge_bypass_ristretto/*.so dist/Tahoe-LAFS/challenge_bypass_ristretto && \
	popd && \
	mv build/tahoe-lafs/dist/* dist

all:
	@case `uname` in \
		Darwin)	arch -x86_64 $(MAKE) frozen-tahoe ;; \
		*) $(MAKE) frozen-tahoe ;; \
	esac
