#!/bin/sh

set -eu

# Optional environment variable:
# BR_ROOT_HOME : HOME's value inside the chroot shell. If unset it will
# be the current value of HOME.

RC_FILE="$HOME"/.br.rc

if ! [ -f "$RC_FILE" ]; then
	echo "$RC_FILE doesn't exist"
	exit 2
fi

. "$RC_FILE"

[ -z "${BR_ROOT_HOME+x}" ] && BR_ROOT_HOME=$HOME

BR_CHROOT_TOOLS="SUDO CHROOT"

br_chroot_basename()
{
	local full_path=$1
	local path=$full_path

	path="${path%/*}"
	if [ -z "$path" ]; then
		path="/"
	elif [ "$path" = "$full_path" ];then
		path="."
	fi

	echo "$path"
}

TOP_DIR=$(br_chroot_basename "$0")

. "$TOP_DIR"/tools.sh

init_tools "$BR_CHROOT_TOOLS" || return $?

trap "$TOP_DIR"/br-umount.sh INT TERM

"$TOP_DIR"/br-mount.sh

HOME=$BR_ROOT_HOME $SUDO ${SUDO:+--preserve-env=HOME} "$CHROOT" "$BR_ROOT"

"$TOP_DIR"/br-umount.sh
