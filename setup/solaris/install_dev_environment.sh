#!/usr/bin/env bash
# source: https://docs.oracle.com/cd/E53394_01/html/E54831/gnwrc.html
set -euxo pipefail
pkg install --accept gnu-emacs-no-x11 group/feature/developer-gnu developer/build/automake developer/build/gnu-make developer/debug/gdb developer/java/jdk library/python/ipython runtime/ruby-21 developer/gcc-48 developer/versioning/git developer/versioning/mercurial
