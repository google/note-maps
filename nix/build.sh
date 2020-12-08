# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
source $stdenv/setup
for p in $buildInputs; do
  export PATH=$p/bin${PATH:+:}$PATH
done

# Tell Go to use TMP directories for writes. Otherwise Go tries to write to
# some locations that are readonly during nix-build.
export GOCACHE=$TMP/go-build
export GOPATH=$TMP/go

# Copy source to TMP so we can write to it.  Nix sources are readonly, but we
# (currently) need to write to the source directory during build.
export SRCDIR=$TMP/src
mkdir -p $SRCDIR
cp -rf $src/* $SRCDIR/
chmod +w -R $SRCDIR
export GOMODCACHE=$SRCDIR/tmp/go/mod
export PUBCACHE=$SRCDIR/tmp/pub/cache

echo "*** attempting build in SRCDIR=$SRCDIR"
cd $SRCDIR && make -e OUT=$TMP lint #test build

echo "*** attempting release to out=$out"
mkdir -p $out/bin
#cp $TMP/go/bin/note-maps $out/bin/note-maps
cp $SRCDIR/VERSION* $out/
