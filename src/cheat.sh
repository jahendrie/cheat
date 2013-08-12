#!/bin/bash
################################################################################
#   cheat.sh        |   version 0.8     |       GPL v3      |   2013-08-11
#   James Hendrie   |   hendrie dot james at gmail dot com
#
#   This script is a reimplementation of a Python script written by Chris Lane:
#       https://github.com/chrisallenlane
################################################################################

#   Cheat directory.  This is where the cheatsheet text files go.
sysCheatDir=/usr/share/cheat
cheatDir=~/.cheat


function print_help
{
    echo "Usage:  cheat [OPTION] FILE[s]"
    echo -e "\nOptions:"
    echo -e "  -k or -l or --list:\tGrep for keyword(s)"
    echo -e "  -a or --add:\t\tAdd file(s)"
    echo -e "  -h or --help:\t\tThis help screen"

    echo -e "\nExamples:"
    echo -e "  cheat tar:\t\tDisplay cheat sheet for tar"
    echo -e "  cheat -a FILE:\tAdd FILE to cheat sheet directory"
    echo -e "  cheat -k:\t\tList all available cheat sheets"
    echo -e "  cheat -k KEYWORD:\tGrep for all files containing KEYWORD\n"

    echo "Cheat sheets are kept in the ~/.cheat directory.  If you don't have"
    echo "read/write permissions for that directory, you won't be able to make"
    echo -e "use of this script.\n"

    echo "This script is still in its infancy, so beware loose ends."
}

function print_version
{
    echo "cheat.sh, version 0.8, James Hendrie: hendrie.james at gmail.com"
    echo -e "Original version by Chris Lane: chris at chris-allen-lane dot com"
}

function add_cheat_sheet
{
    ##  Check to make sure it exists
    if [ ! -e "$1" ]; then
        echo "ERROR:  File does not exist:  $1" 1>&2
        exit 1
    fi

    if [ `ls $1 | tail -c5` = ".txt" ] || [ `ls $1 | tail -c5` = ".TXT" ]; then
        extension=$(ls $1 | tail -c5)
        newName=$(echo $1 | sed s/$extension//g)
    else
        newName=$1
    fi

    ##  Add the file to the directory
    if [ `ls $1 | tail -c4` = '.gz' ]; then
        cp "$1" $cheatDir
    else
        cp "$1" "$cheatDir/$newName"
        gzip -9 "$cheatDir/$newName"
    fi

    echo "$1 added to cheat sheet directory"
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


##  If they want to add stuff
if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
    if [ "$#" -lt 2 ]; then
        echo "ERROR:  No files specified" 1>&2
        exit 1
    fi

    currentArg=1

    for arg in $@; do
        if [ $currentArg -ne 1 ]; then
            add_cheat_sheet "$arg"
        fi

        let currentArg=$[ $currentArg + 1 ]
    done

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

    currentArg=1

    ##  Grep for every subject they listed as an arg
    for arg in $@; do
        if [ $currentArg -ne 1 ]; then
            echo  "$arg:"
            ls $cheatDir | grep -i "$arg" | while read LINE; do
                newLine=$(echo "$LINE" | sed 's/.gz//g')
                echo  "  $newLine"
            done
            echo ""
        fi

        let currentArg=$[ $currentArg + 1 ]
    done

    exit 0
fi

##  The full file name
fileName="$cheatDir/$1"

##  Make sure it exists
if [ ! -e "$fileName" ]; then
    if [ -e "$fileName.gz" ]; then
        fileName="$fileName.gz"
    else
        echo "ERROR:  File does not exist:  $fileName" 1>&2
        exit 1
    fi
fi

##  If the file exists, cat it out
if [ `ls "$fileName" | tail -c4` = ".gz" ]; then
    gunzip --stdout "$fileName" | cat >& 1
else
    cat "$fileName"
fi
