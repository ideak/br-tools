check_mount_entries()
{
	local err=0

	echo "$@" | "$GREP" -q '|' || err=$?
	if [ $err -ne 0 -a $err -ne 1 ]; then
		pr_err "$GREP internal error"
		return $err
	fi
	[ $err -ne 0 ] && return 0

	pr_err "BR mount entries can't contain '|' characters"

	return 1
}

is_mounted()
{
	local mount_point=$1
	local mounts
	local err=0

	mounts=$("$MOUNT") || return $?
	mounts=$(echo "$mounts" | "$AWK" '{print $3}') || return $?

	echo "$mounts" | "$GREP" -q "^$mount_point\$" || err=$?
	if [ $err -ne 0 -a $err -ne 1 ]; then
		pr_err "$GREP internal failure"
	fi

	return $err
}
