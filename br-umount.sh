#!/bin/sh

set -eu

RC_FILE="$HOME"/.br.rc

if ! [ -f "$RC_FILE" ]; then
	echo "$RC_FILE doesn't exist"
	exit 2
fi

. "$RC_FILE"

BR_UMOUNT_TOOLS="SUDO MOUNT UMOUNT GREP AWK SED"

br_umount_basename()
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

TOP_DIR=$(br_umount_basename "$0")

. "$TOP_DIR"/tools.sh
. "$TOP_DIR"/utils.sh
. "$TOP_DIR"/br-utils.sh

umount_one_entry()
{
	local mount_point=$1
	local err

	is_mounted "$mount_point" || err=$?
	[ $err -eq 1 ] && return 0
	[ $err -ne 0 ] && return $err

	$SUDO "$UMOUNT" "$mount_point"
}

umount_all()
{
	local reversed_entries

	reversed_entries="$(echo "$BR_MOUNTS" | "$SED" -n '1!G;h;$p')" || return $?

	echo "$reversed_entries" | while read -r mount_point unused_fields; do
		local err=0

		mount_point=$(sanitize_path "$mount_point")

		umount_one_entry "$mount_point" || err=$?
		if [ $err -ne 0 ]; then
			pr_err "Couldn't umount \"$mount_point\""
			return $err
		fi
	done
}

init_tools "$BR_UMOUNT_TOOLS" || return $?
umount_all
