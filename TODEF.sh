#!/bin/bash
# Manipulate options in a .config file from the command line
# To convert config to .defines for ifdef.vim

myname=${0##*/}

# If no prefix forced, use the default CONFIG_
CONFIG_="${CONFIG_-CONFIG_}"
def_file=$(pwd)/.defines

def_string="defined="
undef_string="undefined="

function usage() {
"
Manipulate options in a .config file from the command line.
Usage:
$myname options command ...
commands:
	--enable|-e option   Enable option
	--disable|-d option  Disable option
	--module|-m option   Turn option into a module
	--set-str option string
	                     Set option to "string"
	--set-val option value
	                     Set option to value
	--undefine|-u option Undefine option
	--state|-s option    Print state of option (n,y,m,undef)

	--enable-after|-E beforeopt option
                             Enable option directly after other option
	--disable-after|-D beforeopt option
                             Disable option directly after other option
	--module-after|-M beforeopt option
                             Turn option into module directly after other option

	commands can be repeated multiple times

options:
	--file config-file   .config file to change (default .config)
	--keep-case|-k       Keep next symbols' case (dont' upper-case it)

config doesn't check the validity of the .config file. This is done at next
make time.

By default, $myname will upper-case the given symbol. Use --keep-case to keep
the case of all following symbols unchanged.

config uses 'CONFIG_' as the default symbol prefix. Set the environment
variable CONFIG_ to the prefix to use. Eg.: CONFIG_="FOO_" $myname ...
"
	exit 1
}

function checkarg() {
	ARG="$1"
	if [ "$ARG" = "" ] ; then
		usage
	fi
	case "$ARG" in
	${CONFIG_}*)
		ARG="${ARG/${CONFIG_}/}"
		;;
	esac
	if [ "$MUNGE_CASE" = "yes" ] ; then
		ARG="`echo $ARG | tr a-z A-Z`"
	fi
}

function txt_append() {
	local anchor="$1"
	local insert="$2"
	local infile="$3"
	local tmpfile="$infile.swp"

	# sed append cmd: 'a\' + newline + text + newline
	cmd="$(printf "a\\%b$insert" "\n")"

	sed -e "/$anchor/$cmd" "$infile" >"$tmpfile"
	# replace original file with the edited one
	mv "$tmpfile" "$infile"
}

function txt_subst() {
	local before="$1"
	local after="$2"
	local infile="$3"
	local tmpfile="$infile.swp"

	sed -e "s:$before:$after:" "$infile" >"$tmpfile"
	# replace original file with the edited one
	mv "$tmpfile" "$infile"
}

function txt_delete() {
	local text="$1"
	local infile="$2"
	local tmpfile="$infile.swp"

	sed -e "/$text/d" "$infile" >"$tmpfile"
	# replace original file with the edited one
	mv "$tmpfile" "$infile"
}

function set_var() {
	local name=$1 new=$2 before=$3

	name_re="^($name=|# $name is not set)"
	before_re="^($before=|# $before is not set)"
	if test -n "$before" && grep -Eq "$before_re" "$FN"; then
		txt_append "^$before=" "$new" "$FN"
		txt_append "^# $before is not set" "$new" "$FN"
	elif grep -Eq "$name_re" "$FN"; then
		txt_subst "^$name=.*" "$new" "$FN"
		txt_subst "^# $name is not set" "$new" "$FN"
	else
		echo "$new" >>"$FN"
	fi
}

function undef_var() {
	local name=$1

	txt_delete "^$name=" "$FN"
	txt_delete "^# $name is not set" "$FN"
}

function convert() {
	touch $def_file
	cat /dev/null > $def_file
	defstr=`awk '{if($3==1){print $2}}' $FN`
	defstr=`echo $defstr | sed 's/ /;/g'`
	def_string="$def_string$defstr"
	echo $def_string

	undefstr=`awk '{if($3==0){print $2}}' $FN`
	undefstr=`echo $undefstr | sed 's/ /;/g'`
	undef_string="$undef_string$undefstr"
	echo $undef_string

	echo $def_string >> $def_file
	echo "" >> $def_file
	echo $undef_string >> $def_file
	echo "ifdef-parse finish!"
}

if [ "$1" = "--file" ]; then
	FN="$2"
	if [ "$FN" = "" ] ; then
		usage
	fi
	shift 2
else
	FN=$(pwd)/ifdef-autoconf.txt
fi

if [ "$1" = "" ] ; then
	usage
fi

MUNGE_CASE=yes
while [ "$1" != "" ] ; do
	CMD="$1"
	shift
	case "$CMD" in
	--keep-case|-k)
		MUNGE_CASE=no
		continue
		;;
	--refresh)
		;;
	--*-after|-E|-D|-M)
		checkarg "$1"
		A=$ARG
		checkarg "$2"
		B=$ARG
		shift 2
		;;
	-*)
		checkarg "$1"
		shift
		;;
	esac
	case "$CMD" in
	--enable|-e)
		set_var "${CONFIG_}$ARG" "${CONFIG_}$ARG=y"
		;;

	--disable|-d)
		set_var "${CONFIG_}$ARG" "# ${CONFIG_}$ARG is not set"
		;;

	--module|-m)
		set_var "${CONFIG_}$ARG" "${CONFIG_}$ARG=m"
		;;

	--set-str)
		# sed swallows one level of escaping, so we need double-escaping
		set_var "${CONFIG_}$ARG" "${CONFIG_}$ARG=\"${1//\"/\\\\\"}\""
		shift
		;;

	--set-val)
		set_var "${CONFIG_}$ARG" "${CONFIG_}$ARG=$1"
		shift
		;;
	--undefine|-u)
		undef_var "${CONFIG_}$ARG"
		;;

	--state|-s)
		if grep -q "# ${CONFIG_}$ARG is not set" $FN ; then
			echo n
		else
			V="$(grep "^${CONFIG_}$ARG=" $FN)"
			if [ $? != 0 ] ; then
				echo undef
			else
				V="${V/#${CONFIG_}$ARG=/}"
				V="${V/#\"/}"
				V="${V/%\"/}"
				V="${V//\\\"/\"}"
				echo "${V}"
			fi
		fi
		;;
	--output|-o)
		convert
		;;
	*)
		usage
		;;
	esac
done




