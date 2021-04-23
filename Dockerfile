FROM centos:7

RUN yum -y update && yum -y install \
    git make gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel xz \
    && yum clean all

RUN git clone --branch 1.2.26 https://github.com/pyenv/pyenv.git ~/.pyenv
RUN echo -e 'export PYENV_ROOT="$HOME/.pyenv"\nexport PATH="$PYENV_ROOT/bin:$PATH"\nif command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bashrc
ARG PYTHON_CONFIGURE_OPTS=--enable-shared
RUN bash -l -c "pyenv install --skip-existing 2.7.18 && pyenv rehash && pyenv global 2.7.18 && python -m pip install --upgrade setuptools pip virtualenv"

WORKDIR /frozen-tahoe
CMD ["bash", "-l", "-c", "make"]
