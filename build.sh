#!/bin/bash -e

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

# defaults
ARCH=mips
VERSION=stretch
QEMU_ARCH=mips64
QEMU_VER=v4.2.0-2
SUITE=stretch
INCLUDE=wget

while getopts "a:v:q:u:d:s:i:o:" opt; do
    case "$opt" in
    a)  ARCH=$OPTARG
        ;;
    v)  VERSION=$OPTARG
        ;;
    q)  QEMU_ARCH=$OPTARG
        ;;
    u)  QEMU_VER=$OPTARG
        ;;
    s)  SUITE=$OPTARG
        ;;
    i)  INCLUDE=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

dir="$VERSION"
COMPONENTS="main"
VARIANT="minbase"
args=( -d "$dir" ../bin/debootstrap --no-check-gpg --variant="$VARIANT" --components="$COMPONENTS" --include="$INCLUDE" --arch="$ARCH" "$SUITE" )

# create our bootstrap
mkdir -p $dir
sudo DEBOOTSTRAP="./bin/qemu-debootstrap" "./bin/mkimage.sh" "${args[@]}" 2>&1 | tee "$dir/build.log"
cat "$dir/build.log"
sudo chown -R "$(id -u):$(id -g)" "$dir"

# seed qemu
cd "${dir}"
if [ ! -f x86_64_qemu-${QEMU_ARCH}-static.tar.gz ]; then
  wget -N https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VER}/x86_64_qemu-${QEMU_ARCH}-static.tar.gz
fi
tar xf x86_64_qemu-*.gz
cd ..

# build our dockerfile
sed -i /^ENV/d "${dir}/Dockerfile"
cat >> "${dir}/Dockerfile" <<EOF
ENV ARCH=${ARCH} DEBIAN_SUITE=${SUITE} 
ADD qemu-*-static /usr/bin/
EOF
