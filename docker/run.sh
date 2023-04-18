#! /bin/bash
#
# run.sh -- build and optionally test the software in this repo via docker
#
# type "run.sh -h" to see detailed help
#
prog=`basename $0`
execdir=`dirname $0`
[ "$execdir" = "" -o "$execdir" = "." ] && execdir=$PWD
codedir=`(cd $execdir/.. > /dev/null 2>&1; pwd)`
os=`uname`
SED_RE_OPT=r
[ "$os" != "Darwin" ] || SED_RE_OPT=E

function usage {
    cat <<EOF

$prog - build and optionally test the software in this repo via docker

SYNOPSIS
  $prog [-d|--docker-build] [--dist-dir DIR] [CMD ...] 
        [DISTNAME|python|angular|java ...] 
        

ARGS:
  python    apply commands to just the python distributions
  angular   apply commands to just the angular distributions
  java      apply commands to just the java distributions

DISTNAMES:  pdr-lps, pdr-publish, customization-api

CMDs:
  build     build the software
  test      build the software and run the unit tests
  install   just install the prerequisites (use with shell)
  shell     start a shell in the docker container used to build and test

OPTIONS
  -d        build the required docker containers first
  -t TESTCL include the TESTCL class of tests when testing; as some classes
            of tests are skipped by default, this parameter provides a means 
            of turning them on.
EOF
}

function wordin {
    word=$1
    shift

    echo "$@" | grep -qsw "$word"
}
function docker_images_built {
    for image in "$@"; do
        (docker images | grep -qs $image) || {
            return 1
        }
    done
    return 0
}

set -e

distvol=
distdir=
dodockbuild=
cmds=
comptypes=
args=()
dargs=()
pyargs=()
angargs=()
jargs=()
testcl=()
while [ "$1" != "" ]; do
    case "$1" in
        -d|--docker-build)
            dodockbuild=1
            ;;
        --dist-dir)
            shift
            distdir="$1"
            mkdir -p $distdir
            distdir=`(cd $distdir > /dev/null 2>&1; pwd)`
            distvol="-v ${distdir}:/app/dist"
            args=(${args[@]} "--dist-dir=/app/dist")
            ;;
        --dist-dir=*)
            distdir=`echo $1 | sed -e 's/[^=]*=//'`
            mkdir -p $distdir
            distdir=`(cd $distdir > /dev/null 2>&1; pwd)`
            distvol="-v ${distdir}:/app/dist"
            args=(${args[@]} "--dist-dir=/app/dist")
            ;;
        -t|--incl-tests)
            shift
            testcl=(${testcl[@]} $1)
            ;;
        --incl-tests=*)
            testcl=(${testcl[@]} `echo $1 | sed -e 's/[^=]*=//'`)
            ;;
        -h|--help)
            usage
            exit
            ;;
        -*)
            args=(${args[@]} $1)
            ;;
        python|wizard|editable|java)
            comptypes="$comptypes $1"
            ;;
        wizard)
            wordin wizard $comptypes || comptypes="$comptypes wizard"
            angargs=(${args[@]} $1)
            ;;
        editable)
            wordin editable $comptypes || comptypes="$comptypes editable"
            angargs=(${args[@]} $1)
            ;;
        build|install|test|shell)
            cmds="$cmds $1"
            ;;
        *)
            echo Unsupported command: $1
            false
            ;;
    esac
    shift
done

[ -z "$distvol" ] || dargs=(${dargs[@]} "$distvol")
[ -z "${testcl[@]}" ] || {
    dargs=(${dargs[@]} --env OAR_TEST_INCLUDE=\"${testcl[@]}\")
}
echo "*** TEST"
comptypes=`echo $comptypes`
cmds=`echo $cmds`
[ -n "$comptypes" ] || comptypes="pdr-lps"
[ -n "$cmds" ] || cmds="build"
echo "run.sh: Running docker commands [$cmds] on [$comptypes]"

testopts="--cap-add SYS_ADMIN"
volopt="-v ${codedir}:/dev/oar-pdr-angular"

# check to see if we need to build the docker images; this can't detect
# changes requiring re-builds.
# 
echo "*** TEST 2"
if [ -z "$dodockbuild" ]; then
    if wordin wizard $comptypes; then
        if wordin build $cmds; then
            docker_images_built oar-pdr-angular/wizard || dodockbuild=1
        fi
    fi
fi

if [ -z "$dodockbuild" ]; then
    if wordin editable $comptypes; then
        if wordin build $cmds; then
            docker_images_built oar-pdr-angular/editable || dodockbuild=1
        fi
    fi
fi

        
[ -z "$dodockbuild" ] || {
    echo '#' Building missing docker containers...
    $execdir/dockbuild.sh
}
echo "*** TEST3"
# handle angular building and/or testing.  If shell was requested with
# angular, open the shell in the angular test contatiner (angtest).
# 
if wordin wizard $comptypes; then
    docmds=`echo $cmds | sed -${SED_RE_OPT}e 's/shell//' -e 's/install//' -e 's/^ +$//'`
    if { wordin shell $cmds && [ "$comptypes" == "wizard" ]; }; then 
        docmds="$docmds shell"
    fi

    if [ "$docmds" == "build" ]; then
        # build only
        echo '+' docker run --rm $volopt "${dargs[@]}" oar-pdr-angular/wizard build \
                       "${args[@]}" "${angargs[@]}"
        docker run --rm $volopt "${dargs[@]}" oar-pdr-angular/wizard build \
                       "${args[@]}" "${angargs[@]}"
    fi
fi

# handle angular building and/or testing.  If shell was requested with
# angular, open the shell in the angular test contatiner (angtest).
# 
if wordin editable $comptypes; then
    docmds=`echo $cmds | sed -${SED_RE_OPT}e 's/shell//' -e 's/install//' -e 's/^ +$//'`
    if { wordin shell $cmds && [ "$comptypes" == "editable" ]; }; then
        docmds="$docmds shell"
    fi

    if [ "$docmds" == "build" ]; then
        # build only
        echo '+' docker run --rm $volopt "${dargs[@]}" oar-pdr-angular/editable build \
                       "${args[@]}" "${angargs[@]}"
        docker run --rm $volopt "${dargs[@]}" oar-pdr-angular/editable build \
                       "${args[@]}" "${angargs[@]}"
    fi
fi