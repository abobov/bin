#!/bin/bash

#
# Version 0.2
#
#
#

# debug mode
# set -u
# set -o nounset

# options
FLAC_SEEK=5s
NICE_PRIORITY=15
TEST_AFTER_ENCODING=1
CUE_ENCODING="WINDOWS-1251"


# executable
FLAC_BIN=`which flac`
METAFLAC_BIN=`which metaflac`
MAC_BIN=`which mac`
WVUNPACK_BIN=`which wvunpack`
SHNTOOL_BIN=`which shntool`
CUEPRINT_BIN=`which cueprint`
RECODE_BIN=`which recode`
ICONV_BIN=`which iconv`
NICE_BIN=`which nice`

# =================== DONT EDIT ANYTHING BELOW THIS LINE =======================
#
NEED_WRITE_TAGS=0
FORMAT=""
FORMAT_EXT=""
CUE_FILE=""
TMP_WORKING_DIR=""
CANT_RECODE=0

# --== COLORS ==--
#Tnx to cue2tracks project for idea
COLOR_DEFAULT='\033[00m'
COLOR_RED='\033[01;31m'
COLOR_GREEN='\033[01;32m'
COLOR_YELLOW='\033[01;33m'
COLOR_MAGENTA='\033[01;35m'
COLOR_CYAN='\033[01;36m'


#
[ -x "$NICE_BIN" ] && NICE="$NICE_BIN --adjustment=$NICE_PRIORITY" || NICE=""






#
#
#
e_warning()
{
	echo -e "${COLOR_YELLOW}WARNING:${COLOR_DEFAULT} $@"
}


#
#
#
e_error()
{
	echo -e "${COLOR_RED}ERROR:${COLOR_DEFAULT} $@" >&2
}


#
#
#
e_die()
{
	echo -e "${COLOR_RED}CRITICAL ERROR:${COLOR_DEFAULT} $2" >&2
	exit $1
}



#
#
#
check_format()
{
	#FORMATS="ape wv wav flac"
	for frm in "[Aa][Pp][Ee] ape" "[Ww][Vv] wv" "[Ww][Aa][Vv] wav" "[Ff][Ll][Aa][Cc] flac"
	do
		set -- $frm
		NUM_FILES=`ls -1 ./*.$1 2>/dev/null | wc -l`

		if [[ "$NUM_FILES" -ge "1" ]]
		then
			[ ! -z "$FORMAT" ] && e_die "2" "Error: more than one format detected. Game over."

			FORMAT_EXT="$1"
			FORMAT="$2"
		fi	
	done

	[ -z "$FORMAT" ] && e_die "2" "Error: cant detect any format. Game over."
}


#
#
#
test_flac_files()
{
	if [[ $TEST_AFTER_ENCODING -eq 1 ]]
	then
		echo -e "\n=========== Start testing FLAC-files ============"
		$NICE $FLAC_BIN --test ${TMP_WORKING_DIR}/*.flac
		echo -e "\n================== Test is done =================="
	fi
}


#
#
# used from cuetag code (cuetools)
# Vorbis Comments
# for FLAC and Ogg Vorbis files
write_flac_tags()
{
	if [ $# -eq 3 ]
	then
		echo -n "Writing tags for '$2'... "
		
		fields='TITLE VERSION ALBUM TRACKNUMBER TRACKTOTAL ARTIST PERFORMER COPYRIGHT LICENSE ORGANIZATION DESCRIPTION GENRE DATE LOCATION CONTACT ISRC'


		TITLE='%t'
		VERSION=''
		ALBUM='%T'
		TRACKNUMBER='%n'
		TRACKTOTAL='%N'
		ARTIST='%c %p'
		PERFORMER='%p'
		COPYRIGHT=''
		LICENSE=''
		ORGANIZATION=''
		DESCRIPTION='%m'
		GENRE='%G'
		DATE=''
		LOCATION=''
		CONTACT=''
		ISRC='%i %u'

		# make tmp file for tags
		TMP_TAGS_FILE=`mktemp -q -p "./" tags_tmp_XXXXXX`

		[[ ! -f "$TMP_TAGS_FILE" ]] && e_die "2" "Cant create temporary files: '$TMP_TAGS_FILE'"

		METAFLAC="$METAFLAC_BIN --remove-all-tags --no-utf8-convert --import-tags-from=$TMP_TAGS_FILE"

		# date
		ALBUM_DATE=`grep -m 1 DATE "$3" | sed -r -e 's/(.?*)REM\ DATE\ //g'`
		[ -n "${ALBUM_DATE}" ] || ALBUM_DATE=0000
		echo "DATE=$ALBUM_DATE" > "$TMP_TAGS_FILE"

		(for field in $fields
		do
			value=""
			for conv in `eval echo \\$$field`
			do
				value=`$CUEPRINT_BIN -n "$1" -t "$conv\n" "$3"`

				if [ -n "$value" ]
				then
					echo "$field=$value" >> "$TMP_TAGS_FILE"
					break
				fi
			done
		done) && $METAFLAC "$2"

		rm -f "$TMP_TAGS_FILE"

		echo "done"
	fi
}


#
#
#
recode_to_utf8()
{
	# recode
	if [ -x "$RECODE_BIN" ]
	then
		$RECODE_BIN $CUE_ENCODING..UTF-8 "$1"
		return $?
	elif [ -x "$ICONV_BIN" ]
	then
		local TMP_CUE=`mktemp -q -p "./" cue_utf8_tmp_XXXXXX` &&
		{
			$ICONV_BIN --from-code=$CUE_ENCODING --to-code=UTF-8 --output=$TMP_CUE "$1"

			if [[ $? -eq 0 ]]
			then
				mv -f "$TMP_CUE" "$1"
				return $?
			fi
		}
	fi

	return 2
}


#
#
#
find_cue_file()
{
	CUE_FILE="${1/.$2}".cue
	
	if [[ ! -f "$CUE_FILE" ]]
	then
		CUE_FILE="$1.cue"
	fi

	if [[ ! -f "$CUE_FILE" ]]
	then
		CUE_FILE=`ls -1 *.[Cc][Uu][Ee] | head -n 1`
	fi
		
	if [[ -f "$CUE_FILE" && -s "$CUE_FILE" ]]
	then
		echo "Found CUE: '$CUE_FILE'"
		
		# check encodings of cue
		if [[ `file "$CUE_FILE" | grep "ISO-8859 text"` ]]
		then
	    		echo -n "Converting CUE ($CUE_FILE) to UTF-8... "
	    		recode_to_utf8 "$CUE_FILE" && echo "done" || { echo "error"; CANT_RECODE=1; }
		fi

		#
 		LASTLINE=`tail -n 1 "$CUE_FILE" | tr -d [:blank:] | tr -d [:cntrl:]`
    		if [[ "$LASTLINE" != "" ]]
    		then
        		echo -e "\n" >> "$CUE_FILE"
    		fi

	else
		unset CUE_FILE
	fi
	
	
}


#
#
#
trap_int_cb()
{
	if [ -d "$TMP_WORKING_DIR" ]
	then
		echo -e -n "\n\n *** Got INT signal ***\nDeleting TMP dir... "
		rm -f ${TMP_WORKING_DIR}/* && rmdir "$TMP_WORKING_DIR"
		echo -e "done\nFinished work.\n\n"
		exit 13
	fi
}


#
#
#
create_temp_dir()
{

	TMP_WORKING_DIR=`mktemp -q -d -p "./" tmp_XXXXX`

	[[ ! -d "$TMP_WORKING_DIR" ]] && e_die "5" "Cant create temporary dir: '$TMP_WORKING_DIR'" || trap 'trap_int_cb' TERM INT
}


#
#
#
rename_temp_dir()
{
	if [[ -d "$TMP_WORKING_DIR" ]]
	then
		if [[ -n "$CUE_FILE" ]]
		then
			local NEW_DIR_NAME=`$CUEPRINT_BIN -d '%T' "$CUE_FILE"`
			if [[ -n "$NEW_DIR_NAME" && ! -d "$NEW_DIR_NAME" && ! -f "$NEW_DIR_NAME" ]]
			then
				mv "$TMP_WORKING_DIR" "$NEW_DIR_NAME" && echo -e "\nYou can find converted files in '$NEW_DIR_NAME' directory"
				return
			fi	
		fi
		
		echo -e "\nYou can find converted files in '$TMP_WORKING_DIR'"						
	fi
}


#
#
#
bin_require()
{
	local FLAG=0
	
	for P in "$@"
	do
		set -- $P
		local BIN=$1
		local MAND=$2
		
		case $BIN in
		ape	)	
			if [[ ! -x "$MAC_BIN" && $MAND -eq 1 ]]
			then
				e_error "cant find 'mac' program -- install it"
				FLAG=1
			fi 
		;;
		wv	)	
			if [[ ! -x "$WVUNPACK_BIN" && $MAND -eq 1 ]]
			then
				e_error "cant find 'wvunpack' program -- install it"
				FLAG=1
			fi 
		;;
		flac	)	
			if [[ ! -x "$FLAC_BIN" && $MAND -eq 1 ]]
			then
				e_error "cant find 'flac' program -- install it"
				FLAG=1
			fi 
		;;
		metaflac	)	
			if [[ ! -x "$METAFLAC_BIN" && $MAND -eq 1 ]]
			then
				e_error "cant find 'metaflac' program -- install it"
				FLAG=1
			fi 
		;;
		cueprint )	
			if [[ ! -x "$CUEPRINT_BIN" && $MAND -eq 1 ]]
			then
				e_error "cant find 'cueprint' program -- install it"
				FLAG=1
			fi 
		;;
		shntool	)	
			if [[ ! -x "$SHNTOOL_BIN" && $MAND -eq 1 ]]
			then
				e_error "cant find 'shntool' program -- install it"
				FLAG=1
			fi 
		;;

		esac
	done
	
	[[ $FLAG -ne 0 ]] && exit 5
}


#
#
#
check_bin_require()
{
	[[ $2 -eq 1 ]] && SHN_MAND=1 || SHN_MAND=0
	
	case $FORMAT in
		ape	)	bin_require "ape 1" "shntool $SHN_MAND" "flac 1";;
		wv 	)	bin_require "wv 1" "shntool $SHN_MAND" "flac 1";;
		wav 	)	bin_require "flac 1";;
		flac 	)	bin_require "flac 1";;
		*	)	e_error "unknown format '$FORMAT'";;
	esac

}






#
# =================================================
# #	Let`s getting starting our party	# #
# =================================================
#

#
check_format


NUM_W_FILES=`ls -1 ./*.$FORMAT_EXT 2>/dev/null | wc -l`

[[ "$NUM_W_FILES" -lt "1" ]] && e_die "2" "Not found files for convert (detected format is '$FORMAT');-("


if [[ "$NUM_W_FILES" -eq 1 ]]
then
	W_FILE=`ls *.$FORMAT_EXT 2>&1`
	echo "Found file: '$W_FILE'"

	# cue
	find_cue_file "$W_FILE" "$FORMAT"

	if [[ -n "$CUE_FILE" ]]
	then
		if [[ -f "$W_FILE" && -s "$W_FILE" && -f "$CUE_FILE" && -s "$CUE_FILE" ]]
		then
			#
			check_bin_require "$FORMAT" "$NUM_W_FILES"
		
			create_temp_dir

			if [[ $CANT_RECODE -eq 0 ]]
			then
				TRACK_FORMAT="%n - %t"
			else
				TRACK_FORMAT="%n"
				echo "** Warning ** CUE file canot be converted to Unicode. No tags will be writed"
			fi

			echo ""
			# Converting and Spliting W->FLAC
			$NICE $SHNTOOL_BIN split "$W_FILE" -d "$TMP_WORKING_DIR" -t "$TRACK_FORMAT" -o "flac" -f "$CUE_FILE"
			NEED_WRITE_TAGS="1"

			# delete pregap
			if [[ -f "${TMP_WORKING_DIR}/00 - pregap.flac" ]]
			then
				echo -e "Found and removed '00 - pregap.flac'... "
				rm -f "${TMP_WORKING_DIR}/00 - pregap.flac" && echo "done" || echo "error"
			fi
		else
			e_die "2" "not found valid $FORMAT file"
		fi
	else
		e_die "2" "not found valid CUE file. Cant split file."
	fi
else
	#
	check_bin_require "$FORMAT" "$NUM_W_FILES"

	#
	create_temp_dir

	# Converting W->FLAC
	for W_FILE in *.${FORMAT_EXT}
	do
		echo -n "Converting '$W_FILE' to FLAC... "
		case $FORMAT in
			ape )
				$NICE $MAC_BIN "$W_FILE" - -d | $NICE $FLAC_BIN --silent --seekpoint="$FLAC_SEEK" --output-name="${W_FILE/.${FORMAT_EXT}/.flac}" -
				rm -f "$j"
				NEED_WRITE_TAGS=1
			;;
			wv )
				$NICE $WVUNPACK_BIN -q -d -o - "$W_FILE" | $NICE $FLAC_BIN --silent --seekpoint="$FLAC_SEEK" --output-name="${TMP_WORKING_DIR}/${W_FILE/.${FORMAT_EXT}/.flac}" -
				NEED_WRITE_TAGS=1
			;;

			wav )
				$NICE $FLAC_BIN --silent --delete-input-file --seekpoint="$FLAC_SEEK" --output-name="${W_FILE/.${FORMAT_EXT}/.flac}" "$W_FILE"
				NEED_WRITE_TAGS=1
			;;
			* )
				e_die "2" "unknown format"
			;;
		esac
	
		[ $? -eq 0 ] && echo "done"
	done
fi

# =================================

if [[ "$NEED_WRITE_TAGS" -eq 1 && -n "$CUE_FILE" && $CANT_RECODE -eq 0 ]]
then
	echo ""
	#
	bin_require "metaflac 1" "cueprint 1"
	
	NTRACK=`$CUEPRINT_BIN -d '%N' "$CUE_FILE"`
	TRACKNO=1


	NUM_FLAC_FILES=`ls -1 ${TMP_WORKING_DIR}/*.flac 2>/dev/null | wc -l`
	if [[ "$NUM_FLAC_FILES" -gt "0" ]]
	then
		if [[ "$NUM_FLAC_FILES" != "$NTRACK" ]]
		then
			e_warning "number of flac files ($NUM_FLAC_FILES) does not match number of tracks in cue file ($NTRACK)"
		fi

		for FLAC_FILE in ${TMP_WORKING_DIR}/*.flac
		do
			write_flac_tags	$TRACKNO "$FLAC_FILE" "$CUE_FILE"
			TRACKNO=$(($TRACKNO + 1))
		done

		# test
		test_flac_files
	fi
fi

#
rename_temp_dir

echo -e "\nWork complete! Have a nice day ;-)\n"
exit 0

