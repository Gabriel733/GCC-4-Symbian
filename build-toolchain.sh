#!/bin/bash
#License - Attribution-NonCommercial 4.0 International

# Notes:

# Looks like isl 0.15 incompatible with gcc 5.2 : graphite-poly.h:402:35: error: 'isl_constraint' was
#	 not declared in this scope

# D:\MinGW\msys\1.0\bin\make.exe: *** couldn't commit memory for cygwin heap, Win32 error 0


# --with-newlib
# Since a working C library is not yet available, this ensures that the inhibit_libc constant
# is defined when building libgcc. This prevents the compiling of any code that requires libc support.

# --------------------
# Global variables
export TARGET=arm-none-symbianelf
GCCC=gcc-5.5.0
BINUTILS=binutils-2.29.1
GDB=gdb-8.0.1

# I want have enviroment-free statically linked GCC
ICONV=--with-libiconv-prefix=/usr/local
# MAKEJOBS=-j4
MAKEJOBS=--jobs=1
#todo: use multithread download(aria2?)
#WGET=aria
WGET=wget
# --------------------
for arg in "$GDB" "$GCCC" "$BINUTILS"
do
  if [ ! -d $arg ] ; then
    if [ ! -f $arg.tar.* ] ; then
      $WGET ftp://gcc.gnu.org/pub/gdb/releases/$arg.tar.xz ftp://gcc.gnu.org/pub/gdb/releases/$arg.tar.bz2 ftp://gcc.gnu.org/pub/binutils/releases/$arg.tar.bz2 ftp://gcc.gnu.org/pub/gcc/releases/$arg/$arg.tar.bz2 ftp://gcc.gnu.org/pub/gcc/releases/$arg/$arg.tar.xz
    fi
    echo $arg
    tar -xvf $arg.tar.*
  fi
done

# --------------------
# Installation folder
export PREFIX=/usr/local/$GCCC
export PATH=$PATH:$PREFIX/bin
export CONFIGURE=$GCCC/libstdc++-v3/configure
unset CFLAGS
export CFLAGS+="-pipe"

# ------------------
echo "Bulding binutils pass started"

touch build-binutils-started
if [ -d ./build-binutils ] ; then
 rm -rf ./build-binutils
fi
mkdir build-binutils

cd build-binutils
../$BINUTILS/configure --target=$TARGET --prefix=$PREFIX --disable-option-checking \
--enable-ld --enable-gold --enable-lto --enable-vtable-verify \
--enable-werror=no --without-headers --disable-nls --disable-shared \
--disable-libquadmath --enable-plugins --enable-multilib

make $MAKEJOBS
make install-strip

cd ..
touch build-binutils-finished
echo "Bulding binutils pass finished"

# _____________
echo "Copyng gcc dependency libs started"

MPC=mpc-1.0.3
ISL=isl-0.16.1
GMP=gmp-6.1.0
MPFR=mpfr-3.1.4

for arg in "$MPC" "$ISL" "$GMP" "$MPFR"
do
  dir=`echo "$arg" | grep -Eo '^.{3}[[:alpha:]]?'`
  if [ ! -d $GCCC/$dir ] ; then
    if [ ! -f $arg.tar.* ] ; then
      $WGET ftp://gcc.gnu.org/pub/gcc/infrastructure/$arg.tar.bz2 ftp://gcc.gnu.org/pub/gcc/infrastructure/$arg.tar.gz
    fi
    tar -xf $arg.tar.*
	cp -Ru $arg $GCCC/$dir
  fi
done

echo "Copyng gcc dependency libs finished"

# _____________
unset CFLAGS
export CFLAGS+="-pipe"
if [ -d ./build-gcc ] ; then
 rm -rf ./build-gcc
fi
mkdir build-gcc

echo "Building gcc started"

# patch for the EOF, SEEK_CUR, and SEEK_END integer constants
# because autoconf can't set them
find='as_fn_error "computing EOF failed" "$LINENO" 5'
replace='$as_echo "computing EOF failed" "$LINENO" >\&5'
# echo $replace
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE
find='as_fn_error "computing SEEK_CUR failed" "$LINENO" 5'
replace='$as_echo "computing SEEK_CUR failed" "$LINENO" >\&5'
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE
find='as_fn_error "computing SEEK_END failed" "$LINENO" 5'
replace='$as_echo "computing SEEK_END failed" "$LINENO" >\&5'
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE

# patch for the void, int, short and long
# because autoconf can't set them
find='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (void \*))" "ac_cv_sizeof_void_p"        "$ac_includes_default"'
replace='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (void \*))" "ac_cv_sizeof_void_p"'
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE

find='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (long))" "ac_cv_sizeof_long"        "$ac_includes_default"'
replace='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (long))" "ac_cv_sizeof_long"'
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE

find='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (int))" "ac_cv_sizeof_int"        "$ac_includes_default"'
replace='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (int))" "ac_cv_sizeof_int"'
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE

find='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (short))" "ac_cv_sizeof_short"        "$ac_includes_default"'
replace='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (short))" "ac_cv_sizeof_short"'
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE

find='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (char))" "ac_cv_sizeof_char"        "$ac_includes_default"'
replace='if ac_fn_c_compute_int "$LINENO" "(long int) (sizeof (char))" "ac_cv_sizeof_char"'
sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE

# find=''
# replace=''
# sed -i -e 's/'"$find"'/'"$replace"'/g' $CONFIGURE



touch build-gcc-started
cd build-gcc
../$GCCC/configure  --target=$TARGET --prefix=$PREFIX  --without-headers \
	--enable-languages="c,c++,lto" --enable-poison-system-directories \
	--enable-lto --with-newlib --enable-long-long $ICONV \
	--with-dwarf2 --enable-interwork --enable-tls --enable-multilib \
	--disable-hosted-libstdcxx --disable-libstdcxx-pch \
	--disable-option-checking --disable-threads --disable-nls \
	--disable-win32-registry --disable-libssp --disable-shared \
	--enable-wchar_t --enable-extra-sgxxlite-multilibs --enable-c99
	# --with-sysroot

# Ugly hack for:
# D:\MinGW\msys\1.0\bin\make.exe: *** couldn't commit memory for cygwin heap, Win32 error 0
# I hope this enough :-)

# use -k because build libstdc++ expectable failes
# but libsupc and other stuff should be installed!

make $MAKEJOBS -k 2> make-gcc.log
touch first-make-call
make $MAKEJOBS -k 2>> make-gcc.log
make $MAKEJOBS -k 2>> make-gcc.log
make $MAKEJOBS -k 2>> make-gcc.log
# make -k 2>> make-gcc.log
# make -k 2>> make-gcc.log
make -k install-strip

cd ..
touch build-gcc-finished
echo "Bulding gcc finished"


unset CFLAGS
export CFLAGS+="-pipe"
if [ -d ./build-gdb ] ; then
 rm -rf ./build-gdb
fi
mkdir build-gdb


# ______________________

touch build-gdb-started
cd build-gdb

../$GDB/configure --target=$TARGET --prefix=$PREFIX --disable-nls --disable-shared
make $MAKEJOBS 2> gdb-log.txt
make install

cd ..
touch build-gdb-finished

rundll32 powrprof.dll,SetSuspendState 0,1,0
