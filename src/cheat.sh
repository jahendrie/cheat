#!/bin/bash
################################################################################
#   cheat.sh        |   version 1.3     |       GPL v3      |   2018-09-18
#   James Hendrie   |   hendrie.james@gmail.com
#
#   This script is a reimplementation of a Python script written by Chris Lane:
#       https://github.com/chrisallenlane
################################################################################

##  Script version
VERSION="1.3"

##  Default 'system' directory for cheat sheets
if [[ -d "/usr/local/share/cheat" ]]; then
    CHEAT_SYS_DIR=/usr/local/share/cheat
else
    CHEAT_SYS_DIR=/usr/share/cheat
fi

##  Default cheat viewer program
if [[ -z $CHEAT_TEXT_VIEWER ]]; then
    CHEAT_TEXT_VIEWER="cat"
fi

##  User directory for cheat sheets
if [[ -z $DEFAULT_CHEAT_DIR ]]; then
    DEFAULT_CHEAT_DIR="${HOME}/.cheat"
fi

##  Cheat path
if [[ -z $CHEATPATH ]]; then
    CHEATPATH="${DEFAULT_CHEAT_DIR}"
fi

##  Address of main git repository (Chris Allen Lane's version)
if [[ -z $MAIN_REPO_ADDR ]]; then
    MAIN_REPO_ADDR="https://github.com/chrisallenlane/cheat.git"
fi

##  Address of alt git repository (my version, usually out of date)
if [[ -z $ALT_REPO_ADDR ]]; then
    ALT_REPO_ADDR="https://github.com/jahendrie/cheat.git"
fi


##  Variable to determine if they want to compress, 0 by default
compress=0

##  The cheat sheet tarball file name
CSFILENAME="cheatsheets.tar.bz2"

##  Web location(s) of cheat sheets
WEB_PATH_1="http://www.someplacedumb.net/misc"
LOCATION_1="$WEB_PATH_1/$CSFILENAME"


function find_image_viewer
{
    viewers=( 'eog' 'viewnior' 'feh' 'xv' 'display' 'gpicview' 'gthumb' \
        'gwenview' )

    for v in "${viewers[@]}"; do
        if which "$v" > /dev/null; then
            export CHEAT_IMAGE_VIEWER="$v"
            return 0
        fi
    done


    echo -n "ERROR:  Cannot find an image viewer; use CHEAT_IMAGE_VIEWER "
    echo "environment variable"
    exit 1
}


function find_pdf_viewer
{
    viewers=( 'evince' 'xpdf' 'qpdfview' 'mupdf' 'okular' )

    for v in "${viewers[@]}"; do
        if which "$v" > /dev/null; then
            export CHEAT_PDF_VIEWER="$v"
            return 0
        fi
    done

    echo -n "ERROR:  Cannot find a PDF viewer; use CHEAT_PDF_VIEWER environment"
    echo "variable"
    exit 1
}


function find_editor
{
    editors=( 'vim' 'vi' 'nano' 'emacs' 'ed' 'ex' 'gedit' 'kate' 'geany' )

    for e in "${editors[@]}"; do
        if which "$e" > /dev/null; then
            export EDITOR="$e"
            return 0
        fi
    done

    echo 'ERROR:  Cannot find an editor.  Use EDITOR environment variable.'
    exit 1
}


function print_help
{
    echo "Usage:  cheat [OPTION] FILE[s]"
    echo -e "\nOptions:"
    echo -e "  -k:\t\t\tGrep for keyword(s) in filenames"
    echo -e "  -g:\t\t\tGrep for keyword(s) inside the files"
    echo -e "  -G:\t\t\tSame as above, but list full paths to files"
    echo -e "  -l or --link:\t\tLink to a file instead of copying it"
    echo -e "  -L:\t\t\tList all cheat sheets with full paths"
    echo -e "  -e or --edit:\t\tEdit a cheat file using EDITOR env variable"
    echo -e "  -a or --add:\t\tAdd file(s)"
    echo -e "  -A:\t\t\tAdd file(s) with gzip compression"
    echo -e "  -h or --help:\t\tThis help screen"
    echo -e "  -u or --update:\tUpdate cheat sheets (safe, lazy method)"
    echo -e "  -U\t\t\tUpdate/overwrite cheat sheets (non-safe)"
    echo -e "  --git\t\t\tUpdate with sheets from main (Python) cheat repository"
    echo -e "  --git-alt\t\tUpdate with sheets from alt repo (mine)"
    echo -e "  --version\t\tPrint version and author info"

    echo -e "\nExamples:"
    echo -e "  cheat tar:\t\tDisplay cheat sheet for tar"
    echo -e "  cheat -a FILE:\tAdd FILE to cheat sheet directory"
    echo -e "  cheat -a *.txt:\tAdd all .txt files in pwd to cheat directory"
    echo -e "  cheat -k KEYWORD:\tGrep for all filenames containing KEYWORD\n"

    echo "By default, cheat sheets are kept in the ~/.cheat directory.  See the"
    echo -e "README file for more details."
}

function print_version
{
    echo "cheat.sh, version ${VERSION}, James Hendrie: hendrie.james@gmail.com"
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
        newName="$(basename "$1")"
        newName="$(echo "$newName" | sed s/$extension//g)"
    else
        newName="$(basename "$1")"
    fi

    ##  Add the file to the directory
    if [ ! $2 -eq 1 ]; then
        cp -v "$1" "$DEFAULT_CHEAT_DIR/$newName"
    else
        cp -v "$1" "$DEFAULT_CHEAT_DIR/$newName"
        gzip -v -9 "$DEFAULT_CHEAT_DIR/$newName"
    fi
}


##  Args:
##      1   Filename
function add_rich_media
{
    if [[ ! -e "$1" ]]; then
        echo "ERROR:  File does not exist:  $1" 1>&2
        exit 1
    fi

    ##  Copy the file
    cp -v "$1" "$DEFAULT_CHEAT_DIR/$(basename "$1")"
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
    if [ ! $(file -bL $CSFILENAME | cut -f1 -d' ') = "bzip2" ]; then
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


##  Update using cheat sheets from the main branch's repository
##  Args
##  1   Using the main or alt repo (0 = main, 1 = alt)
function update_cheat_sheets_git
{

    if [[ ! -d /tmp ]] || [[ ! -w /tmp ]]; then
        echo "ERROR:  Write access to /tmp required to update cheat sheets" 1>&2
        exit 1
    fi

    if [[ $(which git &> /dev/null) -ne 0 ]]; then
        echo "ERROR:  Program 'git' required to update in this fashion" 1>&2
        exit 1
    fi

    ##  Create temporary directory and change over to it
    TEMP_DIR=$(mktemp -d)
    CUR_LOC=$PWD
    cd "$TEMP_DIR"

    if [[ $1 -eq 0 ]]; then
        ##  Clone the repo
        git clone "$MAIN_REPO_ADDR" &> /dev/null

        ##  Update the cheat sheets
        CPD=$(cp -vu "./cheat/cheat/cheatsheets/"* "$DEFAULT_CHEAT_DIR" | wc -l)

        ##  Subract one for __init__.py
        CPD=$(( $CPD - 1 ))
        rm "$DEFAULT_CHEAT_DIR/__init__.py"

    elif [[ $1 -eq 1 ]]; then
        git clone "$ALT_REPO_ADDR" &> /dev/null

        ##  Update the sheets
        CPD=$(cp -vu "./cheat/data/"* "$DEFAULT_CHEAT_DIR" | wc -l)
    fi

    ##  Finish up
    echo "$CPD files updated"
    cd "$CUR_LOC"
    rm -rf "$TEMP_DIR"
}


##  Greps for keywords inside of files
##  ARGS
##      1           Whether to list full paths to files.  0 = don't, 1 = do.
function grepper
{
    ##  For every directory in the CHEATPATH variable
    for arg in ${@:2}; do
        if [[ $1 -eq 0 ]]; then
            echo -e "$arg:"
        fi

        echo "$CHEATPATH" | sed 's/:/\n/g' | while read DIR; do


            ##  Change to directory with cheat sheets
            cd "$DIR"

            ##  Grep through all of the cheat sheets
            ls | while read LINE; do
                grep -i "$arg" "$LINE" &> /dev/null
                if [[ $? -eq 0 ]]; then
                    if [[ $1 -eq 0 ]]; then
                        echo "    $LINE"
                    else
                        echo "$PWD/$LINE"
                    fi
                fi
            done

            ##  Go back to previous directory
            cd - &> /dev/null

        done
    done

}


##  VIEW FILE
##      args:
##          1   The full file name, including path
function view_file
{
    ##  Text files
    if file -bL "$1" | grep text > /dev/null; then
        "$CHEAT_TEXT_VIEWER" "$1"
    elif file -bL "$1" | grep gzip > /dev/null; then
        gunzip --stdout "$dirName/$fileName" | "$CHEAT_TEXT_VIEWER" >& 1

    ##  Image files
    elif file -bL "$1" | grep image > /dev/null; then
        if [[ -z $CHEAT_IMAGE_VIEWER ]]; then
            find_image_viewer
        fi
        (nohup $CHEAT_IMAGE_VIEWER "$1" &) &> /dev/null

    ##  PDFs
    elif file -bL "$1" | grep PDF > /dev/null; then
        if [[ -z $CHEAT_PDF_VIEWER ]]; then
            find_pdf_viewer
        fi
        (nohup $CHEAT_PDF_VIEWER "$1" &) &> /dev/null
    fi

}


##  Too few args, tsk tsk
if [ $# -lt 1 ]; then
    print_help
    exit 0
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
if [ ! -n "$CHEATPATH" ]; then
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

##  If they want to update using git (main repo)
if [[ "$1" = "--git" ]]; then
    update_cheat_sheets_git 0
    exit 0
fi

##  Same, but alt repo
if [[ "$1" = "--git-alt" ]]; then
    update_cheat_sheets_git 1
    exit 0
fi

##  If they want to add stuff
if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    for arg in "${@:2}"; do
        if file -bL "$arg" | grep text > /dev/null; then
            add_cheat_sheet "$arg" $compress
        else
            add_rich_media "$arg"
        fi
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
    for arg in "${@:2}"; do
        if file -bL "$arg" | grep text > /dev/null; then
            add_cheat_sheet "$arg" $compress
        else
            echo "ERROR:  Cannot add rich media '$arg' with GZIP compression"
        fi
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
    if [[ -z $EDITOR ]]; then
        find_editor
    fi

    ##  Assemble the collection of files to edit
    filesToEdit=()
    existing=0
    for arg in ${@:2}; do
        while read F; do

            ##  Check and see if we get any hits on the 'edit' search
            if [[ -e "${F}/${arg}" ]]; then
                if file -b "${F}/${arg}" | grep text > /dev/null; then
                    let existing=$(( $existing + 1 ))
                    filesToEdit+=("${F}/${arg}")
                else
                    echo "WARNING:  Not a text file:  '$arg'"
                fi
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

    ##  If they did not supply a keyword, list everything
    if [[ $# -eq 1 ]]; then
        echo "$CHEATPATH" | sed 's/:/\n/g' | while read DIR; do
            ls -1 "$DIR"
        done

        exit 0
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


##  If they're grepping for words inside the files
if [[ "$1" = "-g" ]]; then

    ##  If they did not supply a keyword, tell them
    if [[ $# -eq 1 ]]; then
        echo "ERROR:  Keyword(s) required" 1>&2
        exit 1
    fi

    grepper 0 ${@:2}
    
    exit 0
fi

if [[ "$1" = "-G" ]]; then

    ##  If they did not supply a keyword, tell them
    if [[ $# -eq 1 ]]; then
        echo "ERROR:  Keyword(s) required" 1>&2
        exit 1
    fi

    grepper 1 ${@:2}
    
    exit 0
fi


##  If they want to link something
if [[ "$1" = "-l" ]] || [[ "$1" = "--link" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    for arg in "${@:2}"; do
        if [[ -e "$arg" ]]; then
            ln -sv "$(readlink -f "$arg")" "$DEFAULT_CHEAT_DIR"
        fi
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
        "$CHEAT_TEXT_VIEWER" "$DIR/$1"
        exit 0
    elif [[ -e "$DIR/${1}.gz" ]]; then
        echo -e "$1\n"
        gunzip --stdout "$DIR/${1}.gz" | "$CHEAT_TEXT_VIEWER" >& 1
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

        view_file "$dirName/$fileName"
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
