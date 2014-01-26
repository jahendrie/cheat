#!/bin/bash
################################################################################
#   cheat.sh        |   version 0.97    |       GPL v3      |   2014-01-26
#   James Hendrie   |   hendrie dot james at gmail dot com
#
#   This script is a reimplementation of a Python script written by Chris Lane:
#       https://github.com/chrisallenlane
################################################################################

#   Cheat directory.  This is where the cheatsheet text files go.
sysCheatDir=/usr/share/cheat
cheatDir=~/.cheat

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
    echo -e "  -k or -l or --list:\tGrep for keyword(s)"
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

    echo "Cheat sheets are kept in the ~/.cheat directory.  If you don't have"
    echo "read/write permissions for that directory, you won't be able to make"
    echo -e "use of this script.\n"

    echo "This script is still in its infancy, so beware loose ends."
}

function print_version
{
    echo "cheat.sh, version 0.97, James Hendrie: hendrie.james at gmail.com"
    echo -e "Original version by Chris Lane: chris at chris-allen-lane dot com"
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
        cp "$1" "$cheatDir/$newName"
    else
        cp "$1" "$cheatDir/$newName"
        gzip -9 "$cheatDir/$newName"
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
        FILES_COPIED=$(cp -vu ./* "$cheatDir" | wc -l)
    else
        FILES_COPIED=$(cp -v ./* "$cheatDir" | wc -l)
    fi

    ##  Go back to where the user started, remove temp dir and all its contents
    cd "$CUR_LOC"
    rm -r "$TEMP_DIR"

    ##  Echo progress
    echo "$FILES_COPIED files updated"

}


##  Check to make sure that their cheat directory exists.  If it does, great.
##  If not, exit and tell them.
if [ ! -d "$cheatDir" ]; then
    if [ ! -d "$sysCheatDir" ]; then
        echo "ERROR:  No cheat directory found." 1>&2
        echo -e "\tConsult the help (cheat -h) for more info" 1>&2
        exit 1
    else
        cp -r "$sysCheatDir" "$cheatDir"
        if [ ! -d "$cheatDir" ]; then
            echo "ERROR:  Cannot write to $cheatDir" 1>&2
            exit 1
        fi
    fi
fi


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
        echo "ERROR:  No file files specified" 1>&2
        exit 1
    fi

    ##  Find an editor for the user
    find_editor

    ##  Assemble the collection of files to edit
    filesToEdit=()
    for arg in ${@:2}; do
        filesToEdit+=("$cheatDir/$arg")
    done

    ##  Edit 'em
    "$EDITOR" ${filesToEdit[@]}


    exit 0
fi


##  If they're searching for keywords
if [ "$1" = "-k" ] || [ "$1" = "-l" ] || [ "$1" = "--list" ]; then

    ##  If all they typed was 'cheat -k', list everything (minus .gz extension)
    if [ $# -eq 1 ]; then
        ls "$cheatDir" | while read LINE; do
            newLine=$(echo "$LINE" | sed 's/.gz//g')
            echo  "$newLine"
        done

        exit 0
    fi

    ##  Grep for every subject they listed as an arg
    for arg in ${@:2}; do
        echo  "$arg:"
        ls $cheatDir | grep -i "$arg" | while read LINE; do
            newLine=$(echo "$LINE" | sed 's/.gz//g')
            echo  "  $newLine"
        done
        echo ""

    done

    exit 0
fi


#==============================     MAIN    ====================================

##  If an exact match for the user's query exists, display it
if [ -r `echo "$cheatDir/$1" | sed 's/.gz//g'` ]; then
    echo -e "$cheatDir/$1\n"
    if [ `echo "$cheatDir/$1" | tail -c4` = ".gz" ]; then
        gunzip --stdout "$cheatDir/$1" | cat >& 1
    else
        cat "$cheatDir/$1"
    fi

    exit 0
fi

##  Otherwise, grab the number of 'hits' given by the user's query
RESULTS=$(ls "$cheatDir" | grep -i $1 | wc -l)

##  If there are no results, inform the user and let the program quit
if [ $RESULTS -eq 0 ]; then
    echo "ERROR:  No file matching pattern '$1' in $cheatDir" 1>&2
    exit 1

##  If there is 1 result, display that cheat sheet
elif [ $RESULTS -eq 1 ]; then
    fileName=$(ls "$cheatDir" | grep -i "$1")
    echo -e "$cheatDir/$fileName\n"

    if [ `echo "$fileName" | tail -c4` = ".gz" ]; then
        gunzip --stdout "$cheatDir/$fileName" | cat >& 1
    else
        cat "$cheatDir/$fileName"
    fi

##  If there's more than 1, display to the user his/her possibilities
elif [ $RESULTS -gt 1 ]; then
    for arg in ${@:1}; do
        echo "$arg:"
        ls "$cheatDir" | grep -i "$arg" | while read LINE; do
            echo "  $LINE" | sed 's/.gz//g'
        done
        echo ""
    done

##  I felt weird about not having an 'else' here.  Don't judge me.
else
    echo "How the hell do you have fewer than zero results?" 1>&2
    exit 1
fi

#==============================  END MAIN    ===================================
