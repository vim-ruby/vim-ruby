#!/bin/bash

# This depends on cvsrelease, downloadable from cvsutils.sourceforge.net,
# but included in this directory.  It is covered by a BSD license.

usage() {
        echo "usage: $0 <tag> <release number>" 1>&2
        echo "   eg: $0 v0_2_0 0.2.0" 1>&2
        exit 2
}

[ $# -eq 2 ] || usage

release_tag=$1
release_number=$2

export CVSROOT=`cat CVS/Root`
cvsrelease -z -t $release_tag -r $release_number vim-ruby

