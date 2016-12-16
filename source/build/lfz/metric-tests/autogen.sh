autoreconf --install
CFLAGS="-O0 -g" ./configure
make check
