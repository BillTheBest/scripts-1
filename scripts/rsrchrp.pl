#!/bin/bash
 
# recursive search and replace for a perl regexp pattern in files and sub-directories                         
 
PATH=/bin:/usr/bin:/usr/local/bin
 
function usage() {
  cat 1>&2 <<- EOB
$(basename "$0") - perform recursive search and replace using sed or perl
     
usage: $(basename "$0") [-s] [-n] [-p]    [args]
       directory to start recursive search from
                note that path including file name is accepted
       search string (POSIX/perl-compatible regex)
       replacement string
  [args]        additional arguments for 'find'
                for example, use the following command:
                $(basename "$0") . "myclass("  "-regex .*\.\(c\|cc\|h\|js\)"
                to search for files in the current directory tree
                with extensions: .c, .cc, .h and .js
  -p           use perl regex instead of POSIX regex
  -s           simulation: no actual replacement takes place
  -n           disable colours
EOB
  exit 1
}
 
#if [ -t 1 ]; then
  LNCOL=$(tput setaf 5)
  NWCOL=$(tput setaf 2)
  TOCOL=$(tput setaf 3)
  NOCOL=$(tput op)
#fi
 
unset simulation use_perl_regex add_grep_args add_find_args
while getopts "snph?" OPTION
do
     case $OPTION in
         s)
             simulation=1
             shift $((OPTIND-1)); OPTIND=1
             ;;
         n)
             # disable colours
             unset LNCOL
             unset NWCOL
             unset TOCOL
             unset NOCOL
             shift $((OPTIND-1)); OPTIND=1
             ;;
         p)
             # use perl regex
             use_perl_regex=1
             add_grep_args='P'
             shift $((OPTIND-1)); OPTIND=1
             ;;
         h|?)
             usage
             exit
             ;;
     esac
done
 
if [ -z "$1" ]; then
  usage "$0"
fi
 
if [ -z "$2" ]; then
  usage "$0"
fi
 
startdirectory=$1
if [ -f "$1" ]; then
  add_find_args="-path $startdirectory"
elif [ -d "$1" ]; then
  startdirectory=$1
else
  echo -e "\nInvalid search directory specified: \"$1\"\n\n"
  exit 1
fi
 
if [ ! -z "$4" ]; then
  add_find_args="$add_find_args $4"                                                
fi
 
### initializations
 
# do we have stat to obtain permissions? otherwise, we'll use perl
unset use_stat
stat=`type -p stat`
if [ ! -z $stat -a -x $stat ]; then
  # stat is available, so let's check whether it accepts necessary arguments
  use_stat=`$stat -c %u:%g:%a "$0" | grep '^[0-9]\+:[0-9]\+:[0-9]\+$'`
fi
 
###
 
chgFrom=$2
chgTo=$3
 
if [ ! -t 1 ]; then
  # write full command info into redirected stream
  echo "--- Date:" $(date)
  echo "--- Command with arguments:"
  echo $0 $@
  echo -e "\n\n"
fi
 
echo -e "\nReplacing all occurrences of \"$TOCOL$chgFrom$NOCOL\"\n" \
  "with \""$TOCOL$(printf "%q" $chgTo)$NOCOL"\"\n" \
  "in "$TOCOL$startdirectory$NOCOL"\n"
 
let files=0
 
ipcvardata=`tempfile`
tempfile=`tempfile`
trap "{ rm -f $ipcvardata $tempfile; exit 1; }" INT TERM EXIT
 
#set -e 
 
if [ ! -z "$simulation" ]; then
  echo -e "*** Simulating replacements (no actual changes will be made)\n"
fi
 
find "$startdirectory" $add_find_args -type f -print0 \
  | xargs -r0 grep -lI$add_grep_args "$chgFrom" \
  | while read file;
do
 
if [ -z $use_stat ]; then
  fchown=`perl -e 'printf "%u:%u", (stat $ARGV[0])[4], (stat $ARGV[0])[5]' "$file"`
  fchmod=`perl -e 'printf "%o", 07777 & (stat $ARGV[0])[2]' "$file"`
else
  fchown=`stat -c %u:%g "$file"`;
  fchmod=`stat -c %a "$file"`;
fi
 
if [ -z "$use_perl_regex" ]; then
  sed -e "s/$chgFrom/$chgTo/g" "$file" > $tempfile
else
  perl -pe "s/$chgFrom/$chgTo/g" < "$file" > $tempfile
fi
if [ "$?" -ne "0" ]; then
  exit 20
fi
 
if [ ! -z "$simulation" ]; then
  echo $LNCOL"$file"$NOCOL
  diff "$file" $tempfile | sed \
    -e 's/\([0-9,]\+\)c[0-9,]\+$/'$LNCOL'line \1:'$NOCOL'/g' \
    -e 's/^\(.*$\)/'$NWCOL'\1'$NOCOL'/g' \
  || echo -e "No replacements to be performed\n"
  echo
else
  cp $tempfile "$file" 
  chown $fchown "$file" 
  chmod $fchmod "$file"
  echo "Modified: " $file
fi
  ((files++))
  echo $files>$ipcvardata
done
 
files=`cat $ipcvardata`
if [ ! -z $files ]; then
  echo -e "\n$files file(s) processed\n"
else
  echo -e "No matches found\n"
fi
