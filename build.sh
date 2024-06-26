#!/usr/bin/env bash

# you can either build cmake only
# or can build the project
BUILD_TYPE=Release
GENERATE=
BUILD_DIR=
SANITIZER_OP=OFF
MEMORY_PROFILER=OFF

function print-usage {
    echo "Usage: "
    echo "    [-g|--generate <1|0>] to generate cmake build env only"
    echo "    [-t|--type] either Release (the default) RelWithDebInfo or Debug built type"
    echo "    [-b|--build-dir (path to build directory for cmake) default to build-type"
    echo "    [-u|--unit-tests <1|0> (run unit tests after the build)"
    echo "    [-s]--sanitizer <1|0>] enable sanitizer for this build (off by default)"
    echo "    [-c]--clean] clean the build directory. You must set the location of the build directory with -b as well!!"
    echo "    [-m]--memory] <ON|OFF> enable memory profiler in the build. Please note that this is better left off in release builds"
}

function is_full_path {
    case "x$1" in
    (x*/..|x*/../*|x../*|x*/.|x*/./*|x./*)
        rc=1
        ;;
    (x/*)
        rc=0
        ;;
    (*)
        rc=1
        ;;
    esac
    return $rc
}


SCRIPT=$(realpath "$0")
SOURCES=$(dirname "${SCRIPT}")
SOURES_DIR=$(while [ ! -f CMakeLists.txt ]; do cd ..; done ; pwd)

while [[ $# -gt 0 ]]; do
  case $1 in
    -g|--generate)
      GENERATE="$2"
      shift # past argument
      shift # past value
      ;;
    -s|sanitizer)
        SANITIZER_OP=ON
        shift
        shift
        ;;
    -t|--type)
        BUILD_TYPE="$2"
        shift
        shift
        ;;
     -b|--build-dir)
        BUILD_DIR="$2"
        shift
        shift
        ;;
    -m|--memory)
        if [ "$2" = "ON" -o "$2" = "on" ]; then
            MEMORY_PROFILER=ON
        else
            MEMORY_PROFILER=OFF
        fi
        shift
        shift
        ;;
     -c|--clean)
       DO_CLEAN="1"
       shift
       ;;
     -u|--unit-tests)
        RUN_UT=1
        shift
        shift
        ;;
     -*|--*)
      echo "Unknown option $1"
      print-usage
      exit 1
      ;;
      *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}"
if [ ${BUILD_TYPE} != "Release" -a ${BUILD_TYPE} != "Debug" -a ${BUILD_TYPE} != "RelWithDebInfo" ]; then
      print-usage
      exit 1
fi
if [ "${BUILD_DIR}" = "" ]; then
    BUILD_DIR="build-${BUILD_TYPE}"
fi
if [ "${GENERATE}" = "" ]; then
    GENERATE=0
fi

is_full_path $BUILD_DIR  || {
    BUILD_DIR=$SOURES_DIR/${BUILD_DIR}
}
echo "build directory is set to ${BUILD_DIR}"

if [ "$DO_CLEAN" != "" ]; then
    echo "cleaning build dir ${BUILD_DIR}"
    rm -rf ${BUILD_DIR} || {
        echo "failed to remove build dir ${BUILD_DIR}"
        exit 1
    }
    echo "successfully clean old build from ${BUILD_DIR}"
    exit 0
fi

mkdir -p ${BUILD_DIR} || {
    echo "failed to generate build directory at ${BUILD_DIR}"
    exit 1
}

cd ${BUILD_DIR} || {
    echo "failed to cd into build dir ${BUILD_DIR}"
    exit 1
}
if [ ${GENERATE} -eq 1 ]; then
    conan install ${SOURES_DIR}  --output-folder=. --build=missing --settings=build_type=${BUILD_TYPE} || {
	 echo "failed to install conan dependecies"
    	 exit 1
    }
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
	    -DENABLE_CLANG_TIDY=${SANITIZER_OP} \
	    -DENABLE_MEMORY_PROFILER=${MEMORY_PROFILER} \
	    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
	    -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake \
	    -DCMAKE_POLICY_DEFAULT_CMP0091=NEW \
	    -G Ninja ${SOURES_DIR} || {
        echo "failed to generate cmake project at ${BUILD_DIR}"
        exit 1
    }
    echo "successfully generate cmake project at ${BUILD_DIR}"
    exit 0
fi

cmake --build . --target all || {
    echo "failed to build current target of ${BUILD_TYPE}"
    exit 1
}

if [ "$RUN_UT" = "1" ]; then
    echo "running unit tests"
    cur_dir=$(basename `pwd`)
    if [ ${cur_dir} != ${BUILD_DIR} ]; then
        cd ${BUILD_DIR} 
    fi
    ctest --progress -VV
    exit $?
fi
