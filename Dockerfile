#FROM lambci/lambda:build-provided
FROM danger89/cmake:latest

LABEL maintainer="Development Seed <info@developmentseed.org>"
LABEL authors="Matthew Hanson  <matt.a.hanson@gmail.com>, Nils Weber <nilsweber@gmx.de>"

RUN apt-get -y update && apt-get -y upgrade

# install system libraries
RUN \
    apt-get -y install wget libpng-dev libglib2.0-dev nasm rsync; \
    apt-get -y install bash-completion openssl libssl-dev; \
    apt-get -y install openssl; \
    apt-get clean all;

# versions of packages
ENV \
    GDAL_VERSION=3.9.0 \
    PROJ_VERSION=9.4.0 \
    GEOS_VERSION=3.12.1 \
    GEOTIFF_VERSION=1.7.2 \
    HDF4_VERSION=4.2.16 \
    HDF5_VERSION=1.14.3 \
    NETCDF_VERSION=4.9.2 \
    NGHTTP2_VERSION=1.62.0 \
    OPENJPEG_VERSION=2.5.0 \
    LIBJPEG_TURBO_VERSION=2.0.6 \
    CURL_VERSION=8.8.0 \
    PKGCONFIG_VERSION=0.29.2 \
    SZIP_VERSION=2.1.1 \
    WEBP_VERSION=1.1.0 \
    ZSTD_VERSION=1.5.6 \
    OPENSSL_VERSION=3.3.0

# Paths to things
ENV \
    BUILD=/build \
    NPROC=4 \
    PREFIX=/usr/local \
    GDAL_CONFIG=/usr/local/bin/gdal-config \
    LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64 \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig \
    GDAL_DATA=/usr/local/share/gdal \
    PROJ_LIB=/usr/local/share/proj

# switch to a build directory
WORKDIR /build

# pkg-config - version > 2.5 required for GDAL 2.3+
RUN \
    mkdir pkg-config; \
    wget -qO- https://pkg-config.freedesktop.org/releases/pkg-config-$PKGCONFIG_VERSION.tar.gz \
        | tar xvz -C pkg-config --strip-components=1; cd pkg-config; \
    ./configure --prefix=$PREFIX CFLAGS="-O2 -Os"; \
    make -j ${NPROC} install; \
    cd ../; rm -rf pkg-config

# nghttp2
RUN \
    mkdir nghttp2; \
    wget -qO- https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz \
        | tar xvz -C nghttp2 --strip-components=1; cd nghttp2; \
    ./configure --enable-lib-only --prefix=${PREFIX}; \
    make -j ${NPROC} install; \
    cd ..; rm -rf nghttp2

# curl
RUN \
    mkdir curl; \
    wget -qO- https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz \
        | tar xvz -C curl --strip-components=1; cd curl; \
    ./configure --prefix=${PREFIX} --disable-manual --disable-cookies --with-nghttp2=${PREFIX} --with-openssl; \
    make -j ${NPROC} install; \
    cd ..; rm -rf curl

# Open SSL is needed for building Python so it's included here for ease
# RUN \
#     mkdir openssl; \
#     wget -qO- https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
#         | tar xvz -C openssl --strip-components=1; cd openssl; \
#     ./config shared --prefix=${PREFIX}/openssl --openssldir=${PREFIX}/openssl; \
#     make depend; make install; cd ..; rm -rf openssl

# sqlite3 (required by proj)
RUN \
    mkdir sqlite3; \
    wget -qO- https://www.sqlite.org/2020/sqlite-autoconf-3330000.tar.gz \
        | tar xvz -C sqlite3 --strip-components=1; cd sqlite3; \
    ./configure --prefix=$PREFIX; \
    make; make install; \
    cd ../; rm -rf sqlite3;

# proj
RUN \
    mkdir proj; \
    wget -qO- http://download.osgeo.org/proj/proj-$PROJ_VERSION.tar.gz \
        | tar xvz -C proj --strip-components=1; cd proj; \
    SQLITE3_LIBS="=L$PREFIX/lib -lsqlite3" SQLITE3_INCLUDE_DIRS=$PREFIX/include/proj ./configure --prefix=$PREFIX; \
    make -j ${NPROC} install; \
    cd ..; rm -rf proj

# GEOS
RUN \
    mkdir geos; \
    wget -qO- http://download.osgeo.org/geos/geos-$GEOS_VERSION.tar.bz2 \
        | tar xvj -C geos --strip-components=1; cd geos; \
    ./configure --enable-python --prefix=$PREFIX CFLAGS="-O2 -Os"; \
    make -j ${NPROC} install; \
    cd ..; rm -rf geos

# szip (for hdf)
RUN \
    mkdir szip; \
    wget -qO- https://support.hdfgroup.org/ftp/lib-external/szip/$SZIP_VERSION/src/szip-$SZIP_VERSION.tar.gz \
        | tar xvz -C szip --strip-components=1; cd szip; \
    ./configure --prefix=$PREFIX; \
    make -j ${NPROC} install; \
    cd ..; rm -rf szip

# libhdf4
RUN \
    mkdir hdf4; \
    wget -qO- https://support.hdfgroup.org/ftp/HDF/releases/HDF$HDF4_VERSION/src/hdf-$HDF4_VERSION.tar \
        | tar xv -C hdf4 --strip-components=1; cd hdf4; \
    ./configure \
        --prefix=$PREFIX \
        --with-szlib=$PREFIX \
        --enable-shared \
        --disable-netcdf \
        --disable-fortran; \
    make -j ${NPROC} install; \
    cd ..; rm -rf hdf4

# libhdf5
RUN \
    mkdir hdf5; \
    wget -qO- https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-${HDF5_VERSION}/src/hdf5-$HDF5_VERSION.tar.gz \
        | tar xvz -C hdf5 --strip-components=1; cd hdf5; \
    ./configure \
        --prefix=$PREFIX \
        --with-szlib=$PREFIX; \
    make -j ${NPROC} install; \
    cd ..; rm -rf hdf5

# NetCDF
RUN \
    mkdir netcdf; \
    wget -qO- https://github.com/Unidata/netcdf-c/archive/v$NETCDF_VERSION.tar.gz \
        | tar xvz -C netcdf --strip-components=1; cd netcdf; \
    ./configure --prefix=$PREFIX --enable-hdf4; \
    make -j ${NPROC} install; \
    cd ..; rm -rf netcdf

# WEBP
RUN \
    mkdir webp; \
    wget -qO- https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz \
        | tar xvz -C webp --strip-components=1; cd webp; \
    CFLAGS="-O2 -Wl,-S" PKG_CONFIG_PATH="/usr/lib64/pkgconfig" ./configure --prefix=$PREFIX; \
    make -j ${NPROC} install; \
    cd ..; rm -rf webp

# ZSTD
RUN \
    mkdir zstd; \
    wget -qO- https://github.com/facebook/zstd/archive/v${ZSTD_VERSION}.tar.gz \
        | tar -xvz -C zstd --strip-components=1; cd zstd; \
    make -j ${NPROC} install PREFIX=$PREFIX ZSTD_LEGACY_SUPPORT=0 CFLAGS=-O1 --silent; \
    cd ..; rm -rf zstd

# openjpeg
RUN \
    mkdir openjpeg; \
    wget -qO- https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz \
        | tar xvz -C openjpeg --strip-components=1; cd openjpeg; mkdir build; cd build; \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX; \
    make -j ${NPROC} install; \
    cd ../..; rm -rf openjpeg

# jpeg_turbo
RUN \
    mkdir jpeg; \
    wget -qO- https://github.com/libjpeg-turbo/libjpeg-turbo/archive/${LIBJPEG_TURBO_VERSION}.tar.gz \
        | tar xvz -C jpeg --strip-components=1; cd jpeg; \
    cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=$PREFIX .; \
    make -j $(nproc) install; \
    cd ..; rm -rf jpeg

# geotiff
RUN \
    mkdir geotiff; \
    wget -qO- https://download.osgeo.org/geotiff/libgeotiff/libgeotiff-$GEOTIFF_VERSION.tar.gz \
        | tar xvz -C geotiff --strip-components=1; cd geotiff; \
    ./configure --prefix=${PREFIX} \
        --with-proj=${PREFIX} --with-jpeg=${PREFIX} --with-zip=yes;\
    make -j ${NPROC} install; \
    cd ${BUILD}; rm -rf geotiff

# GDAL
RUN \
    mkdir gdal; \
    wget -qO- http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz \
        | tar xvz -C gdal --strip-components=1; cd gdal; \
    cmake \
        -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DGDAL_USE_OPENJPEG=ON \
        -DGDAL_USE_GEOTIFF=ON \
        -DGEOTIFF_INCLUDE_DIR=${PREFIX} \
        -DGDAL_USE_HDF4=ON \
        -DHDF4_INCLUDE_DIR=${PREFIX} \
        -DGDAL_USE_HDF5=ON \
        -DHDF5_INCLUDE_DIR=${PREFIX} \
        -DGDAL_USE_NETCDF=ON \
        -DNETCDF_INCLUDE_DIR=${PREFIX} \
        -DGDAL_USE_WEBP=ON \
        -DWEBP_INCLUDE_DIR=${PREFIX} \
        -DGDAL_USE_ZSTD=ON \
        -DZSTD_INCLUDE_DIR=${PREFIX} \
        -DGDAL_USE_JPEG=ON \
        -DJPEG_INCLUDE_DIR=${PREFIX} \
        -DGDAL_USE_SQLITE3=ON \
        -DSQLite3_INCLUDE_DIR=$PREFIX \
        -DGDAL_USE_CURL=ON \
        -DCURL_INCLUDE_DIR=${PREFIX}/bin/curl-config \
        -DBUILD_PYTHON_BINDINGS:BOOL=OFF \
        -DOGR_ENABLE_DRIVER_ELASTIC:BOOL=OFF \
        -DGDAL_USE_GEOS=ON \
        -DGEOS_INCLUDE_DIR=$PREFIX/bin/geos-config \
        -DPROJ_INCLUDE_DIR=${PREFIX} \
        -DCMAKE_C_FLAGS="-O2 -Os" \
        -DCMAKE_CXX_FLAGS="-O2 -Os" \
        -DCMAKE_EXE_LINKER_FLAGS="-Wl,-rpath,'\$\$ORIGIN'" .; \
    cmake --build . --parallel 4 \
    cmake --build . --parallel 4 --target install \
    cd ${BUILD}; rm -rf gdal
    # ./configure \
    #     --disable-debug \
    #     --disable-static \
    #     --prefix=${PREFIX} \
    #     --with-openjpeg \
    #     --with-geotiff=${PREFIX} \
    #     --with-hdf4=${PREFIX} \
    #     --with-hdf5=${PREFIX} \
    #     --with-netcdf=${PREFIX} \
    #     --with-webp=${PREFIX} \
    #     --with-zstd=${PREFIX} \
    #     --with-jpeg=${PREFIX} \
    #     --with-threads=yes \
    #     --with-sqlite3=$PREFIX \
    #     --with-curl=${PREFIX}/bin/curl-config \
    #     --without-python \
    #     --without-libtool \
    #     --disable-driver-elastic \
    #     --with-geos=$PREFIX/bin/geos-config \
    #     --with-hide-internal-symbols=yes \
    #     CFLAGS="-O2 -Os" CXXFLAGS="-O2 -Os" \
    #     LDFLAGS="-Wl,-rpath,'\$\$ORIGIN'"; \
    # make -j ${NPROC} install; \
    # cd ${BUILD}; rm -rf gdal


# Copy shell scripts and config files over
COPY bin/* /usr/local/bin/

WORKDIR /home/geolambda
