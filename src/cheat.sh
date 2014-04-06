#!/bin/bash
################################################################################
#   cheat.sh        |   version 0.99    |       GPL v3      |   2014-04-05
#   James Hendrie   |   hendrie.james@gmail.com
#
#   This script is a reimplementation of a Python script written by Chris Lane:
#       https://github.com/chrisallenlane
################################################################################

##  Default 'system' directory for cheat sheets
if [[ -d "/usr/local/share/cheat" ]]; then
    CHEAT_SYS_DIR=/usr/local/share/cheat
else
    CHEAT_SYS_DIR=/usr/share/cheat
fi

##  User directory for cheat sheets
if [[ "$DEFAULT_CHEAT_DIR" = "" ]]; then
    DEFAULT_CHEAT_DIR="${HOME}/.cheat"
fi

##  Cheat path
if [[ "$CHEATPATH" = "" ]]; then
    CHEATPATH="${DEFAULT_CHEAT_DIR}"
fi

##  Variable to determine if they want to compress, 0 by default
compress=0

##  The cheat sheet tarball file name
CSFILENAME="cheatsheets.tar.bz2"

##  Web location(s) of cheat sheets
WEB_PATH_1="http://www.someplacedumb.net/misc"
LOCATION_1="$WEB_PATH_1/$CSFILENAME"


function find_editor
{
    FOUND=0
    editors=( 'vim' 'vi' 'nano' 'ed' 'ex' )

    if [ "$EDITOR" == "" ]; then
        for e in "${editors[@]}"; do
            which "$e" &> /dev/null

            if [ $? = 0 ]; then
                export EDITOR="$e"
                let FOUND=1
                break
            fi
        done

    else
        let FOUND=1

    fi


    if [ $FOUND = 0 ]; then
        echo 'ERROR:  Cannot find an editor.  Use $EDITOR environment variable.'
        exit 1
    fi
}


function print_help
{
    echo "Usage:  cheat [OPTION] FILE[s]"
    echo -e "\nOptions:"
    echo -e "  -k:\t\t\tGrep for keyword(s)"
    echo -e "  -l or --list:\t\tList all cheat sheets"
    echo -e "  -L:\t\t\tList all cheat sheets with full paths"
    echo -e "  -e or --edit:\t\tEdit a cheat file using EDITOR env variable"
    echo -e "  -a or --add:\t\tAdd file(s)"
    echo -e "  -A:\t\t\tAdd file(s) with gzip compression"
    echo -e "  -h or --help:\t\tThis help screen"
    echo -e "  -u or --update:\tUpdate cheat sheets (safe, lazy method)"
    echo -e "  -U\t\t\tUpdate/overwrite cheat sheets (non-safe)"

    echo -e "\nExamples:"
    echo -e "  cheat tar:\t\tDisplay cheat sheet for tar"
    echo -e "  cheat -a FILE:\tAdd FILE to cheat sheet directory"
    echo -e "  cheat -a *.txt:\tAdd all .txt files in pwd to cheat directory"
    echo -e "  cheat -k:\t\tList all available cheat sheets"
    echo -e "  cheat -k KEYWORD:\tGrep for all files containing KEYWORD\n"

    echo "By default, cheat sheets are kept in the ~/.cheat directory.  See the"
    echo -e "README file for more details.\n"

    echo "This script is still in its infancy, so beware loose ends."
}

function print_version
{
    echo "cheat.sh, version 0.99, James Hendrie: hendrie.james@gmail.com"
    echo -e "Original version by Chris Lane: chris@chris-allen-lane.com"
}

##  args:
##      $1: The file we're adding
##      $2: Whether to gzip or not (1 is yes)
function add_cheat_sheet
{
    ##  Check to make sure it exists
    if [ ! -e "$1" ]; then
        echo "ERROR:  File does not exist:  $1" 1>&2
        exit 1
    fi

    ##  If the file ends in .txt, we're going to rename it
    if [ `ls $1 | tail -c5` = ".txt" ] || [ `ls $1 | tail -c5` = ".TXT" ]; then
        extension=$(ls $1 | tail -c5)
        newName=$(echo $1 | sed s/$extension//g)
    else
        newName=$1
    fi

    ##  Add the file to the directory
    if [ ! $2 -eq 1 ]; then
        cp "$1" "$DEFAULT_CHEAT_DIR/$newName"
    else
        cp "$1" "$DEFAULT_CHEAT_DIR/$newName"
        gzip -9 "$DEFAULT_CHEAT_DIR/$newName"
    fi

    echo "$1 added to cheat sheet directory"
}


##  args:
##      $1: Whether or not to overwrite all files.  0 = update only,
##          1 = overwrite all files with versions in the archive
function update_cheat_sheets
{
    if [ ! -d /tmp ] || [ ! -w /tmp ]; then
        echo "ERROR:  Write access to /tmp required to update cheat sheets" 1>&2
        exit 1
    fi

    ##  Create temporary directory and change over to it
    TEMP_DIR=$(mktemp -d)
    CUR_LOC=$PWD
    cd "$TEMP_DIR"
    
    ##  Check for download programs; if found, use them to download file
    which wget &> /dev/null
    if [ $? -ne 0 ]; then
        which curl &> /dev/null
        if [ $? -ne 0 ]; then
            echo "ERROR:  Either wget or curl required to update" 1>&2
            rm -r "$TEMP_DIR"
            exit 1
        else
            curl -sO "$LOCATION_1"
        fi
    else
        wget -q "$LOCATION_1"
    fi

    ##  Check to make sure the file exists
    if [ ! -r $CSFILENAME ]; then
        echo "ERROR:  Could not read from $TEMP_DIR/$CSFILENAME.  Aborting" 1>&2
        rm -r "$TEMP_DIR"
        exit 1
    fi

    ##  Check to make sure the file is a tarball
    if [ ! $(file -b $CSFILENAME | cut -f1 -d' ') = "bzip2" ]; then
        echo "File $CSFILENAME is not a bzip2 file.  Aborting" 1>&2
        rm -r "$TEMP_DIR"
    fi

    ##  Extract file, then remove it
    tar -xf "$CSFILENAME"
    rm "$CSFILENAME"

    ##  If we're playing it safe, update cheat dir.  Otherwise, straight copy
    if [ $1 -eq 0 ]; then
        FILES_COPIED=$(cp -vu ./* "$DEFAULT_CHEAT_DIR" | wc -l)
    else
        FILES_COPIED=$(cp -v ./* "$DEFAULT_CHEAT_DIR" | wc -l)
    fi

    ##  Go back to where the user started, remove temp dir and all its contents
    cd "$CUR_LOC"
    rm -r "$TEMP_DIR"

    ##  Echo progress
    echo "$FILES_COPIED files updated"

}


##  Too few args, tsk tsk
if [ $# -lt 1 ]; then
    echo "ERROR:  Too few arguments" 1>&2
    exit 1
fi


##  If they want help, give it to 'em
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    print_help
    exit 0
fi

##  If they're looking for version/author info
if [ "$1" = "--version" ]; then
    print_version
    exit 0
fi


##  Check to make sure that their cheat directory exists.  If it does, great.
##  If not, exit and tell them.
if [ ! -d "$CHEATPATH" ]; then
    if [ ! -d "$CHEAT_SYS_DIR" ] && [ ! -d "$DEFAULT_CHEAT_DIR" ]; then
        echo "ERROR:  No cheat directory found." 1>&2
        echo -e "\tConsult the help (cheat -h) for more info" 1>&2
        exit 1
    else
        cp -r "$CHEAT_SYS_DIR" "$DEFAULT_CHEAT_DIR"
        CHEATPATH="$DEFAULT_CHEAT_DIR"
        if [ ! -d "$DEFAULT_CHEAT_DIR" ]; then
            echo "ERROR:  Cannot write to $DEFAULT_CHEAT_DIR" 1>&2
            exit 1
        fi
    fi
fi

##  If they want to update their cheat sheets (safe mode)
if [ "$1" = "-u" ] || [ "$1" = "--update" ]; then
    update_cheat_sheets 0
    exit 0
fi

##  If they want to update cheat sheets (non-safe mode)
if [ "$1" = "-U" ]; then
    update_cheat_sheets 1
    exit 0
fi

##  If they want to add stuff
if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    for arg in ${@:2}; do
        add_cheat_sheet "$arg" $compress
    done

    exit 0
fi

##  If they want to add and compress stuff
if [ "$1" = "-A" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    compress=1
    for arg in ${@:2}; do
        add_cheat_sheet "$arg" $compress
    done

    exit 0
fi


##  If they want to edit a file
if [ "$1" = "-e" ] || [ "$1" = "--edit" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    ##  Find an editor for the user
    find_editor

    ##  Assemble the collection of files to edit
    filesToEdit=()
    existing=0
    for arg in ${@:2}; do
        while read F; do

            ##  Check and see if we get any hits on the 'edit' search
            if [[ -e "${F}/${arg}" ]]; then
                let existing=$(( $existing + 1 ))
                filesToEdit+=("${F}/${arg}")
            fi
        done < <(echo "$CHEATPATH" | sed 's/:/\n/g')

        ##  If we didn't get any hits, create one in default dir
        if [[ $existing -eq 0 ]]; then
            filesToEdit+=("${DEFAULT_CHEAT_DIR}/${arg}")
        fi

    done

    ##  Edit 'em
    "$EDITOR" ${filesToEdit[@]}


    exit 0
fi


##  If they're searching for keywords
if [[ "$1" = "-k" ]]; then

    ##  If they did not supply a keyword, tell them
    if [[ $# -eq 1 ]]; then
        echo "ERROR:  Keyword(s) required" 1>&2
        exit 1
    fi

    ##  Grep for every subject they listed as an arg
    for arg in ${@:2}; do
        echo -e "$arg:\n"

        echo "$CHEATPATH" | sed 's/:/\n/g' | while read DIR; do
            ls "$DIR" | grep -i "$arg" | while read LINE; do
                echo "  $LINE" | sed 's/.gz//g'
            done

        done

    done

    exit 0
fi


##  If they want to list everything
if [[ "$1" = "-l" ]] || [[ "$1" = "--list" ]]; then
    echo "$CHEATPATH" | sed 's/:/\n/g' | while read DIR; do
        ls -1 "$DIR"
    done

    exit 0
fi


##  List everything with full paths
if [[ "$1" = "-L" ]]; then
    echo "$CHEATPATH" | sed 's/:/\n/g' | while read DIR; do
        ls "$DIR" | while read LINE; do
            echo "${DIR}/${LINE}"
        done
    done

    exit 0
fi


#==============================     MAIN    ====================================

RESULTS=0
declare RESULTS_ARRAY=()

while read DIR; do
    ##  If we hit an 'exact' match
    if [[ -e "$DIR/$1" ]]; then
        echo -e "$1\n"
        cat "$DIR/$1"
        exit 0
    elif [[ -e "$DIR/${1}.gz" ]]; then
        echo -e "$1\n"
        gunzip --stdout "$DIR/${1}.gz" | cat >& 1
        exit 0
    fi

    ##   grab the number of 'hits' given by the user's query
    DIR_RESULTS=$(ls "$DIR" | grep -i "$1" | wc -l)

    if [[ $DIR_RESULTS -gt 0 ]]; then
        while read R; do
            RESULTS_ARRAY+=("${R}:${DIR}")
        done < <(ls "$DIR" | grep -i "$1")
    fi

    let RESULTS=$(( $RESULTS + $DIR_RESULTS ))

done < <(echo "$CHEATPATH" | sed 's/:/\n/g')


##  If there are no results, inform the user and let the program quit
if [ $RESULTS -eq 0 ]; then
    echo "ERROR:  No file matching pattern '$1' in $CHEATPATH" 1>&2
    exit 1

##  If there is 1 result, display that cheat sheet
elif [ $RESULTS -eq 1 ]; then
    for R in ${RESULTS_ARRAY[@]}; do
        fileName="$(echo "$R" | cut -f1 -d':')"
        dirName="$(echo "$R" | cut -f2 -d':')"

        echo -e "$fileName\n"

        if [ `echo "$fileName" | tail -c4` = ".gz" ]; then
            gunzip --stdout "$dirName/$fileName" | cat >& 1
        else
            cat "$dirName/$fileName"
        fi
    done

##  If there's more than 1, display to the user his/her possibilities
elif [ $RESULTS -gt 1 ]; then
    for arg in ${@:1}; do
        echo "$arg:"
        echo ""

        for R in ${RESULTS_ARRAY[@]}; do
            echo "  $R" | cut -f1 -d':'
        done
    done

##  I felt weird about not having an 'else' here.  Don't judge me.
else
    echo "How the hell do you have fewer than zero results?" 1>&2
    exit 1
fi

#==============================  END MAIN    ===================================

exit 0
