#!/bin/bash

set -ex

rm -rf output

mix tailwind default
mix esbuild default

mix run -e "Blog.assets()"
mix run -e "Blog.hello()"
