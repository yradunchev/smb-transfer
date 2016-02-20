#!/bin/bash

### Config
LCK="/_scr/lock/isrunning"
CRD="/_scr/.cifs"
DLS="/_scr/dirlist"
LOG="/_scr/log/$(date "+%Y%m%d%H%M%S").log"
WIN="//WINSERVER/SHARE"
RDR='\REMOTE\DIR'

### Ensure we are not running
mkdir ${LCK} || exit 1

### Clear file lsit from previous runs
[ -f ${DLS} ] && rm ${DLS}

### Get file list
smbclient ${WIN} -A ${CRD} -E -c "cd ${RDR};ls" > ${DLS} 2>&1
FLS=( $( sed -e :a -e '1,6d;$d;N;2,2ba' -e 'P;D' ${DLS} | cut -d' ' -f3 ) )

### Process files
if [ ${#FLS[@]} -gt 0 ]; then
        for FN in "${FLS[@]}"
        do
                PFN="processed\\$(date "+%Y%m%d%H%M%S")_${FN}"
                smbclient ${WIN} -A ${CRD} -E -c "cd ${RDR};get ${FN}" >> ${LOG} 2>&1
                smbclient ${WIN} -A ${CRD} -E -c "cd ${RDR};rename ${FN} ${PFN}" >> ${LOG} 2>&1
                unset PFN
        done
else
        echo 'Nothing to download!' >> ${LOG}
fi

### Clear log files older than 24 hours
find ${LOG} -type f -mmin +4320 -delete

### Remove lock
rm -f ${LCK}
