#!/usr/bin/bash
# 

#-------------------------------------------------------------------------------
# Script:	check_mounts.ksh	
#
# Desc:		Simple check to ensure all filesystems in /etc/[v]fstab with the 
# 		mount at boot option set to "yes" - are actaully mounted
#
# Author:	Karl Hampel
#
# History:	27/10/2010	KH	Created
# Amended:	13/06/2012	KH 	Modified
#
#-------------------------------------------------------------------------------

DEBUG=0

MOUNTED_FS_LIST=""
UNMOUNTED_FS_LIST=""


get_solaris_fs_list(){
    VFSTAB_FS_LIST=$(echo $(${AWK} ' $0 !~ /^#/ && $6 == "yes"  { print $3 }' ${FSTAB}))
    echo ${VFSTAB_FS_LIST}
}


get_linux_fs_list(){
    FSTAB_FS_LIST=$(echo $(${AWK} ' $0 !~ /^#/ { if ( $4 ~ /defaults|auto/ && $4 !~ /noauto/ && $3 !~ /tmpfs|devpts|sysfs|proc|swap/ )  { print $2 } }' ${FSTAB}))
    echo ${FSTAB_FS_LIST}
}





#--------------
# START OF MAIN
#--------------

[[ $1 == "-x" ]] && DEBUG=1

case $(uname -s) in
    Linux)
	AWK=awk
	FSTAB=/etc/fstab
	FS_LIST=$(get_linux_fs_list)
	;;
    SunOS)
	AWK=nawk
	FSTAB=/etc/vfstab
	FS_LIST=$(get_solaris_fs_list)
	;;
esac


for FS in ${FS_LIST} ; do
	if [ -z "$(df -k ${FS} 2>/dev/null | ${AWK} -v fs="${FS}" ' $NF == fs { print $0 }')" ] ; then
	    UNMOUNTED_FS_LIST="$(echo ${UNMOUNTED_FS_LIST} ${FS})"
	else
	    MOUNTED_FS_LIST="$(echo ${MOUNTED_FS_LIST} ${FS})"
	fi
done


if [[ -n "${UNMOUNTED_FS_LIST}" ]] ; then
    echo "$(uname -n):$(basename $0):1:Filesystem/s: ${UNMOUNTED_FS_LIST} are in ${FSTAB} but not currently mounted"
else
    echo "$(uname -n):$(basename $0):0:Success: all filesystems in ${FSTAB} are currently mounted"
fi

[[ ${DEBUG} -eq 1 ]] && echo "  DEBGUG: FSTAB_FS_LIST:     ${FS_LIST}"
[[ ${DEBUG} -eq 1 ]] && echo "  DEBGUG: MOUNTED_FS_LIST:   ${MOUNTED_FS_LIST}"
[[ ${DEBUG} -eq 1 ]] && echo "  DEBGUG: UNMOUNTED_FS_LIST: ${UNMOUNTED_FS_LIST}"


exit
