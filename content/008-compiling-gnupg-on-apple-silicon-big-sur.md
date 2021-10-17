---
title: Compiling GnuPG (GPG) from source on Apple Silicon with Big Sur
published: 2020-11-29T07:37:35Z
revised: 2021-01-05T13:08:57Z
draft: false
preview: Compiling a program like GnuPG (GPG) from source is not difficult. However, there are many individual dependencies, and this post breaks them down.
description: Compiling GnuPG (GPG) from source on Apple Silicon with Big Sur
slug: compiling-gnupg-from-source-on-apple-silicon-with-big-sur
---

Compiling a program like GnuPG (GPG) from source is not difficult. But, there are many individual dependencies and this post breaks them down.

## What about Homebrew?

These instructions are not meant to be a substitute for [Homebrew](https://brew.sh). Homebrew is an excellent package manager run by dedicated contributors. At the time I wrote this, Homebrew support for GnuPG on Apple Silicon was still being completed and certified. 

## Build environment

On a Mac, I don't install programs and libraries into the `usr` folder. Rather, I have a folder called `tools` in my home directory. I have my `PATH` configured as:

```bash
export PATH="/Users/corybuecker/tools/bin:$PATH"
```

I have installed _Xcode 12.2_ rather than the developer tools. The developer tools should would work just fine.

Setting the `tools` directory as an environment variable will make the following steps easier.

```bash
export PREFIX="/Users/corybuecker/tools"
```

Also, many of these packages have been updated to work on Apple Silicon, but they don't always detect the correct architecture. I set the following environment variable to make compiling a bit easier.

```bash
export BUILD="aarch64-apple-darwin20.1.0"
```

## Download sources

It's possible to download and compile each package individually, but I find it much easier to stage all the downloads, verify signatures, extract files, etc. before compiling.

Here are the packages that I downloaded:

```bash
curl -L -o pkg-config-0.29.2.tar.gz http://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
curl -L -o pinentry-1.1.0.tar.bz2 https://gnupg.org/ftp/gcrypt/pinentry/pinentry-1.1.0.tar.bz2
curl -L -o libgpg-error-1.39.tar.bz2 https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.39.tar.bz2
curl -L -o libgcrypt-1.8.7.tar.bz2 https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.8.7.tar.bz2
curl -L -o libksba-1.5.0.tar.bz2 https://gnupg.org/ftp/gcrypt/libksba/libksba-1.5.0.tar.bz2
curl -L -o libassuan-2.5.4.tar.bz2 https://gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.4.tar.bz2
curl -L -o ntbtls-0.2.0.tar.bz2 https://gnupg.org/ftp/gcrypt/ntbtls/ntbtls-0.2.0.tar.bz2
curl -L -o npth-1.6.tar.bz2 https://gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2
curl -L -o scute-1.6.0.tar.bz2 https://gnupg.org/ftp/gcrypt/scute/scute-1.6.0.tar.bz2
curl -L -o gnupg-2.2.25.tar.bz2 https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.2.25.tar.bz2
```

### Signatures

Verifying the signature or digest of downloaded source code is important to validate authenticity and reduce the possibility of supply chain vulnerabilities. I'm including the digests I used to validate the tarballs, but _you_ should always find and build the checksum file yourself from sources you trust. This is another great reason to use a package manager like Homebrew as this step is automatically performed when installing a package.

```bash
6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591  pkg-config-0.29.2.tar.gz
4a836edcae592094ef1c5a4834908f44986ab2b82e0824a0344b49df8cdb298f  libgpg-error-1.39.tar.bz2
c080ee96b3bd519edd696cfcebdecf19a3952189178db9887be713ccbcb5fbf0  libassuan-2.5.4.tar.bz2
68076686fa724a290ea49cdf0d1c0c1500907d1b759a3bcbfbec0293e8f56570  pinentry-1.1.0.tar.bz2
03b70f028299561b7034b8966d7dd77ef16ed139c43440925fe8782561974748  libgcrypt-1.8.7.tar.bz2
ae4af129216b2d7fdea0b5bf2a788cd458a79c983bb09a43f4d525cc87aba0ba  libksba-1.5.0.tar.bz2
1393abd9adcf0762d34798dc34fdcf4d0d22a8410721e76f1e3afcd1daa4e2d1  npth-1.6.tar.bz2
511be523407590a586b7d61b5985af965dd91901b75d9650b55e9ae1d86d0ab0  scute-1.6.0.tar.bz2
649fe74a311d13e43b16b26ebaa91665ddb632925b73902592eac3ed30519e17  ntbtls-0.2.0.tar.bz2
c55307b247af4b6f44d2916a25ffd1fb64ce2e509c3c3d028dbe7fbf309dc30a  gnupg-2.2.25.tar.bz2
```

I saved those digests into a file called `SHASUMS` that I placed with all the tarballs.

```bash
shasum -c SHASUMS
```

## Compiling

These packages must be compiled and installed the order outlined below. I do recommend running `make check`, but it probably isn't critical for smaller libraries.

### `pkg-config`

`pkg-config` makes it much easier to include headers and link libraries as I compile each package.

```bash
tar xvf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure --prefix=$PREFIX --build=$BUILD --with-internal-glib
make -j4
make check
make install
```

Once `pkg-config` is installed, add the following environment variable to your shell.

```bash
export PKG_CONFIG_PATH="/Users/corybuecker/tools/lib/pkgconfig:$PKG_CONFIG_PATH"
```

### `libgpg-error`

`libgpg-error` defines all the common errors for GnuPG programs.

```bash
tar xvf libgpg-error-1.39.tar.bz2
cd libgpg-error-1.39
./configure --prefix=$PREFIX --build=$BUILD
make -j4
make check
make install
```

### `libassuan`

`libassuan` provides an inter-process communication (IPC) protocol and library.

```bash
tar xvf libassuan-2.5.4.tar.bz2
cd libassuan-2.5.4
./configure --prefix=$PREFIX --build=$BUILD
make -j4
make check
make install
```

### `pinentry`

`pinentry` is used to securely read PINs and other passwords.

```bash
tar xvf pinentry-1.1.0.tar.bz2
cd pinentry-1.1.0
./configure --prefix=$PREFIX --build=$BUILD
make -j4
make install
```

### `libgcrypt`

`libgcrypt` provides all the cryptographic functions for GnuPG.

As of this post, the assembly versions of some functions will not compile on Apple Silicon. Hopefully, this will be updated in the near future.

`make check` will fail with a single failure on the `random` function. It appears to be [related to this issue](https://dev.gnupg.org/T2056), so I suspected a regression and I moved on with the installation.

```bash
tar xvf libgcrypt-1.8.7.tar.bz2
cd libgcrypt-1.8.7
./configure --prefix=$PREFIX --build=$BUILD --disable-asm
make -j4
make check
make install
```

### `libksba`

`libksba` is an easy-to-use interface for working with certificates.

```bash
tar xvf libksba-1.5.0.tar.bz2
cd libksba-1.5.0
./configure --prefix=$PREFIX --build=$BUILD
make -j4
make check
make install
```

### `npth`

`npth` is a portable threads library.

```bash
tar xvf npth-1.6.tar.bz2
cd npth-1.6
./configure --prefix=$PREFIX --build=$BUILD
make -j4
make check
make install
```

### `scute`

`scute` allows the GnuPG agent to work with smart cards. If you are not using a hardware key or smart card, skip this package.

```bash
tar xvf scute-1.6.0.tar.bz2
cd scute-1.6.0
./configure --prefix=$PREFIX --build=$BUILD --disable-dependency-tracking
```

Open the `Makefile` in an editor and look for this line, `SUBDIRS = m4 src ${tests} doc`. Remove `doc` from the end of that line. The documentation doesn't compile on Big Sur right now, but it's not critical.

```bash
make -j4
make install
```

The test suite will fail pretty broadly for `scute`. However, it appears to require a GnuPG agent to be running, which I don't have yet.


### `ntbtls`

`ntbtls` is a very small TLS 1.2-only implementation used only by GnuPG tools.

#### Note about GnuTLS

The GnuPG project promotes `ntbtls` from their download page but [provides a pretty big warning](https://gnupg.org/software/ntbtls/index.html). However, I don't have any real concerns using it in this specific case. If you do, the classic TLS library is [GnuTLS](https://www.gnutls.org). That's a much larger package with more dependencies, and I haven't tried compiling it yet.

```bash
tar xvf ntbtls-0.2.0.tar.bz2
cd ntbtls-0.2.0
./configure --prefix=$PREFIX --build=$BUILD
make -j4
make check
make install
```

### `gnupg`

Whew, we made it!

```bash
tar xvf gnupg-2.2.25.tar.bz2
cd gnupg-2.2.25
./configure --prefix=$PREFIX --build=$BUILD
```

Once GnuPG is configured, it will print out some details. Confirm that every feature besides `G13` is enabled. `G13` is a encrypted filesystem container tool which I will explore in the future.

```bash
make -j4
make check
make install
```

After installing, try running `gpg` in a new Terminal tab. It should prompt for a message to encrypt.

Wrapping up, there are a lot of dependencies to install. For the most part, they are straight-forward and `pkg-config` helps a lot with `CFLAGS` and library linking.