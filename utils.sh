pr_err()
{
	echo "$@" >&2
}

err_exit()
{
	pr_err "$@"
	exit 1
}

escape_sed_pattern()
{
	local pattern=$1

	echo "$pattern" | "$SED" 's/[\/.^$*\\[]/\\&/g'
}

remove_reps()
{
	local str=$1
	local rep_char=$2

	rep_char=$(escape_sed_pattern "$rep_char") || return $?

	echo "$str" | "$SED" "s/$rep_char\+/$rep_char/g"
}

sanitize_path()
{
	local path=$1

	remove_reps "$path" /
}
