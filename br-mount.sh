#!/bin/sh

set -eu

# Required variables:
#
# BR_ROOT: path of the chroot rootfs
# BR_MOUNTS: devices/files to be mounted with the provided mount-point/fs-type/mount-options
# BR_MOUNTS format: mount-point device/file fs-type[ mount-options]
# BR_MOUNTS fs-device/file: <path for device/file>|none
# BR_MOUNTS fs-type: <filesystem type of fs-device/file>|auto
# BR_MOUNTS mount-options: <option1>[,<option2>...]: loop,bind

RC_FILE="$HOME"/.br.rc

if ! [ -f "$RC_FILE" ]; then
	echo "$RC_FILE doesn't exist"
	exit 2
fi

. "$RC_FILE"

BR_MOUNT_TOOLS="SUDO MOUNT MKDIR GREP AWK SED"

br_mount_basename()
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

TOP_DIR=$(br_mount_basename "$0")

. "$TOP_DIR"/tools.sh
. "$TOP_DIR"/utils.sh
. "$TOP_DIR"/br-utils.sh

parse_mount_option()
{
	local option=$1

	case "$option" in
	loop)
		echo "-oloop"
		;;
	bind)
		echo "--bind"
		;;
	"")
		;;
	*)
		pr_err "Unknown mount option \"$option\""
		return 1
		;;
	esac

	return 0
}

parse_mount_option_list()
{
	local option_list=$1
	local old_ifs=$IFS
	local option
	local arg_list=""

	set -f
	IFS=,
	set -- $option_list
	set +f

	IFS="$old_ifs"

	for option in "$@"; do
		local arg
		
		arg=$(parse_mount_option "$option") || return $?

		arg_list="$arg_list${arg_list:+|}$arg"
	done

	echo "$arg_list"
}

parse_mount_fs_type()
{
	local fs_type=$1

	[ "$fs_type" = "auto" ] && return

	echo "-t$fs_type"
}

mount_one_entry()
{
	local mount_point=$1
	local device=$2
	local fs_type=$3
	local options=$4
	local arg_list=""
	local option_args=""
	local old_ifs
	local current_mounts
	local err=0

	is_mounted "$mount_point" || err=$?
	[ $err -ne 1 ] && return $err

	arg_list="$(parse_mount_fs_type "$fs_type")"

	option_args=$(parse_mount_option_list "$options") || return $?
	[ -n "$option_args" ] && arg_list="$arg_list${arg_list:+|}$option_args"

	arg_list="$arg_list${arg_list:+|}$device"
	arg_list="$arg_list${arg_list:+|}$mount_point"

	old_ifs=$IFS

	set -f
	IFS='|'
	set -- $arg_list
	set +f

	IFS=$old_ifs

	$SUDO "$MKDIR" -p "$mount_point"
	$SUDO "$MOUNT" "$@"
}

mount_all_entries()
{
	local mount_entry
	local mount_point device fs_type options

	check_mount_entries "$BR_MOUNTS" || return $?

	echo "$BR_MOUNTS" | while read -r mount_point device fs_type options; do
		local err=0

		mount_point=$(sanitize_path "$mount_point") || return $?

		mount_one_entry "$mount_point" "$device" "$fs_type" "$options" || err=$?
		if [ $err -ne 0 ]; then
			pr_err "Couldn't mount \"$device\" to \"$mount_point\""
			return $err
		fi
	done
}

trap $HOME/bin/br-umount.sh INT TERM

init_tools "$BR_MOUNT_TOOLS" || return $?
mount_all_entries
