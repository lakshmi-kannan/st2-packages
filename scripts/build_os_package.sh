#!/bin/bash
set -e
set -o pipefail

package_name="$1"
artifact_dir="${ARTIFACT_DIR}"

RPMS="/root/rpmbuild/RPMS"
export WHEELDIR

platform() {
  [ -f /etc/debian_version ] && { echo 'deb'; return 0; }
  echo 'rpm'
}

build_rpm() { rpmbuild -bb rpm/"$package_name".spec; }
build_deb() { dpkg-buildpackage -b -uc -us; }

copy_rpm() { sudo cp -v $RPMS/*/$1*.rpm "$artifact_dir"; }
copy_deb() {
  sudo cp -v $1*.deb "$artifact_dir";
  sudo cp -v $1{*.changes,*.dsc} "$artifact_dir" || :;
}

[ -z "$package_name" ] && { echo "usage: $0 package_name" && exit 1; }

build_$(platform)
copy_$(platform)