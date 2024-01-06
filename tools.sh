find_builtin_with_command()
{
	local expected_output=$1
	local output

	shift

	output=$($@ 2> /dev/null) || true

	[ "$output" = "$expected_output" ] 
}

is_builtin_command()
{
	local tool_name=$1

	find_builtin_with_command builtin type -t "$tool_name" && return
	find_builtin_with_command "$tool_name is a shell builtin" command -V "$tool_name" && return
	find_builtin_with_command "$tool_name is a shell builtin" command -v "$tool_name" && return

	return 2
}

tool_varname_to_name()
{
	local tool_varname=$1

	echo "$tool_varname" | "$TR" '[:upper:]' '[:lower:]'
}

try_assign_builtin_command()
{
	local tool_varname=$1
	local tool_name=$2

	if is_builtin_command "$tool_name"; then
		eval $tool_varname="$tool_name"
		return 0
	fi

	return 2
}

assign_external_command()
{
	local tool_varname=$1
	local tool_name=$2
	local err=0

	tool_path=$("$WHICH" $tool_name) || err=$?
	if [ $err -eq 0 ]; then
		eval $tool_varname="$tool_path"
		return 0
	fi

	pr_err "Cannot find tool \"$tool_name\""

	return $err
}

__find_and_assign_tool()
{
	local tool_varname=$1
	local tool_name=$2

	try_assign_builtin_command "$tool_varname" "$tool_name" && return 0

	assign_external_command "$tool_varname" "$tool_name"
}

find_and_assign_tool()
{
	local tool_varname=$1
	local tool_name=$(tool_varname_to_name "$tool_varname")

	__find_and_assign_tool "$tool_varname" "$tool_name" || return $?
}

init_find_tool_deps()
{
	WHICH=which		# chicken-and-egg hack
	__find_and_assign_tool WHICH which || return $?
	__find_and_assign_tool TR tr
}

init_one_tool()
{
	local tool_varname=$1

	if [ "$tool_varname" = "SUDO" ]; then
		if [ -z "${ID+x}" ]; then
			find_and_assign_tool ID || return $?
		fi
		if [ "$("$ID" -u)" -eq 0 ]; then
			SUDO=
			return 0
		fi
	fi

	find_and_assign_tool "$tool_varname"
}

init_tools()
{
	local tool_varname_list=$1
	local tool_varname
	local err

	init_find_tool_deps || return $?

	for tool_varname in $tool_varname_list; do
		init_one_tool "$tool_varname" || return $?
	done

}
