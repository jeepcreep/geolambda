ARG VERSION=3.0.1
FROM jeepcreep/geolambda:${VERSION}

LABEL maintainer="Development Seed <info@developmentseed.org>"
LABEL authors="Matthew Hanson  <matt.a.hanson@gmail.com>"

ARG PYVERSION=3.10.14

# install Python
ENV \
    PYENV_ROOT=/root/.pyenv \
    PATH=/root/.pyenv/shims:/root/.pyenv/bin:$PATH \
    GDAL_CONFIG=/usr/local/bin/gdal-config

RUN \
    curl https://pyenv.run | bash; \
    CONFIGURE_OPTS="--with-openssl=${PREFIX}/openssl --enable-loadable-sqlite-extensions" \
        LD_RUN_PATH="${PREFIX}/openssl/lib" \
        pyenv install ${PYVERSION}; \
    pyenv global ${PYVERSION}; \
    pip3 install --upgrade pip

COPY requirements*.txt ./

RUN \
    pip3 install -r requirements-pre.txt; \
    pip3 install -r requirements.txt

COPY bin/* /usr/local/bin/
