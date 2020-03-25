#!/usr/bin/env bash

device="hx8k"
package="ct256"
family=
pcf=
dry=
aproject=
atoolchain=
verbose=
onfail=true
out_prefix=build

usage() {
    echo "Exhaustively try project-toolchain combinations"
    echo "usage: exaust.sh [args]"
    echo "--device <device>         device (default: hx8k)"
    echo "--package <package>       device package (default: ct256)"
    echo "--family <family>         device family"
    echo "--project <project>       run given project only (default: all)"
    echo "--toolchain <toolchain>   run given toolchain only (default: all)"
    echo "--pcf <pcf>               pin constraint file (default: none)"
    echo "--sdc <xdc>               constraint file (default: none)"
    echo "--xdc <xdc>               constraint file (default: none)"
    echo "--out-prefix <dir>        output directory prefix (default: build)"
    echo "--dry                     print commands, don't invoke"
    echo "--fail                    fail on error"
    echo "--verbose                 verbose output"
}

ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
    --device)
        device=$2
        shift
        shift
        ;;
    --package)
        package=$2
        shift
        shift
        ;;
    --family)
        family=$2
        shift
        shift
        ;;
    --pcf)
        pcf=$2
        shift
        shift
        ;;
    --sdc)
        sdc=$2
        shift
        shift
        ;;
    --xdc)
        xdc=$2
        shift
        shift
        ;;

    --dry)
        dry=echo
        shift
        ;;
    --project)
        aproject=$2
        shift
        shift
        ;;
    --toolchain)
        atoolchain=$2
        shift
        shift
        ;;
    --out-prefix)
        out_prefix=$2
        shift
        shift
        ;;
    --fail)
        onfail=false
        shift
        ;;
    --verbose)
        verbose=--verbose
        shift
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    *)
        echo "Unrecognized argument"
        usage
        exit 1
        ;;
    esac
done

set -x
set -e

function run2() {
    $dry python3 fpgaperf.py --toolchain $toolchain --project "$project" --device "$device" --family "$family" --package "$package" $pcf_arg $sdc_arg $xdc_arg --out-prefix "$out_prefix" $verbose || $onfail
}

function run() {
    toolchain=$1
    project=$2

    if [ "$pcf" = "" ] ; then
        pcf_arg=""
    else
        pcf_arg="--pcf $pcf"
    fi

    if [ "$sdc" = "" ] ; then
        sdc_arg=""
    else
        sdc_arg="--sdc $sdc"
    fi

    if [ "$xdc" = "" ] ; then
        xdc_arg=""
    else
        xdc_arg="--xdc $xdc"
    fi

    run2

    # make ^C easier
    sleep 0.1
}

# Some of these will fail
function exhaustive() {
    echo "Running exhaustive project-toolchain search"
    for project in $(python3 fpgaperf.py --list-projects) ; do
        if [ -n "$aproject" -a "$aproject" != "$project" ] ; then
            continue
        fi
        for toolchain in $(python3 fpgaperf.py --list-toolchains) ; do
            if [ -n "$atoolchain" -a "$atoolchain" != "$toolchain" ] ; then
                continue
            fi
            echo
            run $toolchain $project
        done
    done
}

mkdir -p $out_prefix
exhaustive
cd $out_prefix && ../json.sh

