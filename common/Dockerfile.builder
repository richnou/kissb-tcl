FROM rleys/builder:rocky8

RUN dnf install -y --enablerepo=devel libcurl-devel bc bzip2 tcl libX11-devel zlib-devel mingw64-gcc mingw64-cpp mingw64-gcc-c++ mingw64-winpthreads-static mingw32-pkg-config mingw32-libxml2-static libxml2-static libxml2-devel libxslt-devel
RUN dnf install -y --enablerepo=devel openssl-devel
RUN dnf install -y --enablerepo=devel openssl-static
RUN dnf install -y --enablerepo=devel zlib-static