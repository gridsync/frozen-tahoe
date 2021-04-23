.DEFAULT_GOAL := all
SHELL := /bin/bash
.PHONY: clean frozen-tahoe all

clean:
	rm -rf build/
	rm -rf dist/

frozen-tahoe:
	mkdir -p dist
	mkdir -p build/tahoe-lafs
	python2 -m virtualenv --clear --python=python2 build/venv-tahoe
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
	popd && \
	mv build/tahoe-lafs/dist/* dist

in-container:
	docker run --rm --mount type=bind,src=$$(pwd),target=/frozen-tahoe -w /frozen-tahoe \
		gridsync/gridsync-builder@sha256:211cbc53640f737433389a024620d189022c7d5b4b93b62b1aaa3d47513b6a15

all:
	@case `uname` in \
		Darwin)	arch -x86_64 $(MAKE) frozen-tahoe ;; \
		*) $(MAKE) frozen-tahoe ;; \
	esac
