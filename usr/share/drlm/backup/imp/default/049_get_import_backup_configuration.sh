# impbackup workflow

# Get configuration from backup to import
if [ -n "$IMP_BKP_ID" ]; then
  # If is a backup ID, check first if is enabled
  IMP_ACTIVE="$(get_backup_status_by_backup_id $IMP_BKP_ID)"
  if [ "$IMP_ACTIVE" == "1" ]; then
    # Case that backup is get the mountpoint
    IMP_CLI_ID="$(get_backup_client_id_by_backup_id $IMP_BKP_ID)"
    IMP_CLI_NAME="$(get_client_name $IMP_CLI_ID)"
    IMP_CLI_CFG="$(get_backup_config_by_backup_id $IMP_BKP_ID)"
    TMP_MOUNTPOINT="$STORDIR/$IMP_CLI_NAME/$IMP_CLI_CFG"
  else 
    # If backup is not enabled generate backup source variable with the path to the DR file.
    BKP_SRC=${ARCHDIR}/$(get_backup_drfile_by_backup_id "$IMP_BKP_ID")
  fi
else
  # If backup is a file initialitze backup source with this file name.
	BKP_SRC="$IMP_FILE_NAME"
fi

# If backup source is not empty means that the backup is not actually mounted
# A temporal directory will be created and mounted there the DR file.
if [ -n "$BKP_SRC" ]; then 
  TMP_MOUNTPOINT="/tmp/drlm_$(date +"%Y%m%d%H%M%S")"
  mkdir $TMP_MOUNTPOINT &> /dev/null
  if [ $? -ne 0 ]; then Error "Error creating mountpoint directory $TMP_MOUNTPOINT"; fi
  # Get a free NBD device
  NBD_DEVICE=$(get_free_nbd)
  if [ $? -ne 0 ]; then Error "Error getting a free NBD"; fi
  # Attach DR file to a NBD
  qemu-nbd -c $NBD_DEVICE $BKP_SRC -r --cache=none --aio=native >> /dev/null 2>&1
  if [ $? -ne 0 ]; then Error "Error attching $BKP_SRC to $NBD_DEVICE"; fi
  # Mount image:
  /bin/mount -t ext4 -o ro $NBD_DEVICE $TMP_MOUNTPOINT >> /dev/null 2>&1
  if [ $? -ne 0 ]; then Error "Error mounting $NBD_DEVICE $TMP_MOUNTPOINT"; fi
fi

# At this point is available the content of the DR file
# If exists *.*.drlm.cfg file it means that is a backup done with a DRLM 2.4.0 or superior
if [ -f $TMP_MOUNTPOINT/*.*.drlm.cfg ]; then

  IMP_CFG_FILE="$(ls $TMP_MOUNTPOINT/*.*.drlm.cfg)"
  IMP_CLI_NAME="$(basename $(ls $TMP_MOUNTPOINT/*.*.drlm.cfg) | awk -F'.' {'print $1'})"
  IMP_CLI_CFG="$(basename $(ls $TMP_MOUNTPOINT/*.*.drlm.cfg) | awk -F'.' {'print $2'})"

  IMPORT_CONFIGURATION_CONTENT="$(cat $IMP_CFG_FILE)"

  # Get backup type and remove quotes if exists
  IMP_BKP_TYPE="$(cat $IMP_CFG_FILE | grep DRLM_BKP_TYPE | awk -F'=' {'print $2'})"
  temp="${IMP_BKP_TYPE%\"}"
  IMP_BKP_TYPE="${temp#\"}"

  # Get backup protocol and remove quotes if exists
  IMP_BKP_PROT="$(cat $IMP_CFG_FILE | grep DRLM_BKP_PROT | awk -F'=' {'print $2'})"
  temp="${IMP_BKP_PROT%\"}"
  IMP_BKP_PROT="${temp#\"}"

  # Get backup program and remove quotes if exists
  IMP_BKP_PROG="$(cat $IMP_CFG_FILE | grep DRLM_BKP_PROG | awk -F'=' {'print $2'})"
  temp="${IMP_BKP_PROG%\"}"
  IMP_BKP_PROG="${temp#\"}"

  if [ -z "$IMP_BKP_TYPE" ]; then 
    IMP_BKP_TYPE="ISO"
  fi

  # Initialize backup protocol and backup program if empty in function of backup type after loading config file
  if [ "$IMP_BKP_TYPE" == "ISO" ] || [ "$IMP_BKP_TYPE" == "PXE" ] || [ "$IMP_BKP_TYPE" == "DATA" ]; then
    if [ "$IMP_BKP_PROT" == "" ]; then
      IMP_BKP_PROT="RSYNC"
      if [ "$IMP_BKP_PROG" == "" ]; then
        IMP_BKP_PROG="RSYNC"
      fi
    elif [ "$IMP_BKP_PROT" == "RSYNC" ] && [ "$IMP_BKP_PROG" == "" ]; then
        IMP_BKP_PROG="RSYNC"
    elif [ "$IMP_BKP_PROT" == "NETFS" ] && [ "$IMP_BKP_PROG" == "" ]; then
        IMP_BKP_PROG="TAR"
    fi
  elif [ "$IMP_BKP_TYPE" == "ISO_FULL" ] || [ "$IMP_BKP_TYPE" == "ISO_FULL_TMP" ]; then
    if [ "$IMP_BKP_PROT" != "NETFS" ] && [ "$IMP_BKP_PROT" != "" ]; then
      Log "Warning: Backup type ISO_FULL or ISO_FULL_TMP only supports NETFS protocol. Will be setup to NETFS."
    fi
    if [ "$IMP_BKP_PROG" != "TAR" ] && [ "$IMP_BKP_PROG" != "" ]; then
      Log "Warning: Backup type ISO_FULL or ISO_FULL_TMP only supports TAR program. Will be setup to TAR."
    fi
    IMP_BKP_PROT="NETFS"
    IMP_BKP_PROG="TAR"
  fi
# If no exists *.*.drlm.cfg file the backup to import is done with a DRLM prior to 2.4.0 and only have a 
# default configuration with PXE rescue , NETFS protocol and TAR program.
else
  IMP_CLI_CFG="default"
  IMP_BKP_TYPE="PXE"
  IMP_BKP_PROT="NETFS"
  IMP_BKP_PROG="TAR"
fi

# umount the backup to import
if [ -n "$BKP_SRC" ]; then 
  /bin/umount $TMP_MOUNTPOINT >> /dev/null 2>&1
  if [ $? -ne 0 ]; then Error "Error umounting $TMP_MOUNTPOINT"; fi
  qemu-nbd -d $NBD_DEVICE >> /dev/null 2>&1
  if [ $? -ne 0 ]; then Error "Error dettching $NBD_DEVICE"; fi
  rm -rf $TMP_MOUNTPOINT >> /dev/null 2>&1
  if [ $? -ne 0 ]; then Error "Error deleting mountpoint directory $TMP_MOUNTPOINT"; fi
fi
