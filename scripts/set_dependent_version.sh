#!/bin/bash

E_BADARGS=65

case $# in
    0|1|2|3)             # The vertical bar means "or" in this context.
        echo "Usage: `basename $0` <src_dir> <namespace> <major_num> <minor_num>"
        exit $E_BADARGS  # If 0 or 1 arg, then bail out.
        ;;
esac

src_dir=$1
namespace=$2
major_num=$3
minor_num=$4

for file in `grep -i -l -I -r "<namespace>$namespace</namespace>" "$src_dir"`; do
    # Check if the file has the correct major number
    if [ "`grep -i "<majorNumber>$major_num</majorNumber>" "$file"`" == '' ]; then
        echo "Upgrading majorNumber in $file"
        sed -i.bak "s/<majorNumber>.*<\\/majorNumber>/<majorNumber>$major_num<\\/majorNumber>/g" "$file"
        rm "$file".bak
    fi

    if [ "`grep -i "<minorNumber>$minor_num</minorNumber>" "$file"`" == '' ]; then
    # Check if the file has the correct minor number
        echo "Upgrading minorNumber in $file"
        sed -i.bak "s/<minorNumber>.*<\\/minorNumber>/<minorNumber>$minor_num<\\/minorNumber>/g" "$file"
        rm "$file".bak
    fi

done
