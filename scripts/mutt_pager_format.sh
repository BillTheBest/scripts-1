#!/bin/bash

while IFS= read -r LINE; do
    if [[ "${LINE}" =~ ^Date:\ .* ]]; then
        DATE=${LINE#Date: }
        # convert to the current timezone (defined by TZ)
        DATE=$(date -d "${DATE}")
        printf '%s' "Date: ${DATE}"
    elif [[ -n $LINE ]]; then
      # We've reach the end of the headers, so stop parsing
      echo
      exec cat
    else
        printf '%s\n' "${LINE}"
    fi
done
