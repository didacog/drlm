# file with default nfs functions to implement.
# $NETDB is the default.conf variable of Network file
# $CLIDB is the default.conf variable of Client file
# $NFS_DIR is the default.conf variable of dhcp dir file
# $NFS_FILE is the default.conf variable of dhcp configuration file


function generate_nfs_exports_old() {

cp $NFS_FILE $NFS_DIR/exports.bkp
cat /dev/null > $NFS_FILE

for NFS_STORE in $PXEDIR $BKPDIR ; do

	local SCOUNT=1
	local CCOUNT=1
	local NCLI=$(cat $CLIDB | grep -v "^#" | wc -l)

	for CLIENT in $(cat $CLIDB | grep -v "^#") ; do
	   local CLI_ID=$(echo $CLIENT | awk -F":" '{print $1}')
	   local CLI_NAME=$(echo $CLIENT | awk -F":" '{print $2}')
	   local CLI_MAC=$(echo $CLIENT | awk -F":" '{print $3}')
	   local CLI_IP=$(echo $CLIENT | awk -F":" '{print $4}')
	   local CLI_OS=$(echo $CLIENT | awk -F":" '{print $5}')
	   local CLI_NET=$(echo $CLIENT | awk -F":" '{print $6}')

	if [ $SCOUNT -eq 1 ]; then		
		if [ $NCLI -gt 1 ]; then
			echo "$NFS_STORE $CLI_NAME(rw,sync,no_root_squash,no_subtree_check) \\" | tee -a $NFS_FILE > /dev/null
			let SCOUNT=SCOUNT+1
			let CCOUNT=CCOUNT+1
		else
			echo "$NFS_STORE $CLI_NAME(rw,sync,no_root_squash,no_subtree_check)" | tee -a $NFS_FILE > /dev/null
			let SCOUNT=SCOUNT+1
                	let CCOUNT=CCOUNT+1
		fi
	else
		if [ $CCOUNT -lt $NCLI ]; then
			echo "	$CLI_NAME(rw,sync,no_root_squash,no_subtree_check) \\" | tee -a $NFS_FILE > /dev/null
			let CCOUNT=CCOUNT+1
		else
			echo "	$CLI_NAME(rw,sync,no_root_squash,no_subtree_check)" | tee -a $NFS_FILE > /dev/null
		fi
	fi
  
	done
done
#Generates the nfs configuration file from CLIDB
}

function generate_nfs_exports() {

	cp $NFS_FILE $NFS_DIR/exports.bkp
	cat /dev/null > $NFS_FILE


	for CLIENT in $(cat $CLIDB | grep -v "^#") ; do
		local CLI_ID=$(echo $CLIENT | awk -F":" '{print $1}')
		local CLI_NAME=$(echo $CLIENT | awk -F":" '{print $2}')
		local CLI_MAC=$(echo $CLIENT | awk -F":" '{print $3}')
		local CLI_IP=$(echo $CLIENT | awk -F":" '{print $4}')
		local CLI_OS=$(echo $CLIENT | awk -F":" '{print $5}')
		local CLI_NET=$(echo $CLIENT | awk -F":" '{print $6}')

		echo "$STORDIR/$CLI_NAME $CLI_NAME(rw,sync,no_root_squash,no_subtree_check)" | tee -a $NFS_FILE > /dev/null

	done

#Generates the nfs configuration file from CLIDB
}

function enable_nfs_fs_ro() {
        local CLI_NAME=$1

        exportfs -vo ro,sync,no_root_squash,no_subtree_check ${CLI_NAME}:${STORDIR}/${CLI_NAME}
        if [ $? -eq 0 ]; then sleep 1; return 0; else return 1; fi

# Return 0 if OK or 1 if NOK
}

function enable_nfs_fs_rw() {
        local CLI_NAME=$1

        exportfs -vo rw,sync,no_root_squash,no_subtree_check ${CLI_NAME}:${STORDIR}/${CLI_NAME}
        if [ $? -eq 0 ]; then sleep 1; return 0; else return 1; fi

# Return 0 if OK or 1 if NOK
}

function disable_nfs_fs() {
        local CLI_NAME=$1

        exportfs -vu ${CLI_NAME}:${STORDIR}/${CLI_NAME}
        if [ $? -eq 0 ]; then sleep 1; return 0; else return 1; fi

# Return 0 if OK or 1 if NOK
}

function reload_nfs() {
	exportfs -a
	if [ $? -ne 0 ]; then
		mv $NFS_DIR/exports.bkp $NFS_FILE
		exportfs -a
		return 1
	else
		return 0
	fi
}

function add_nfs_export(){

	local CLI_NAME=$1
	local EXIST=$(grep -w ${CLI_NAME} ${NFS_FILE} | grep -w ${CLI_NAME})
	if [ -z "${EXIST}" ]; then
		echo "$STORDIR/$CLI_NAME $CLI_NAME(rw,sync,no_root_squash,no_subtree_check)" | tee -a $NFS_FILE > /dev/null
		if [ $? -eq 0 ]; then
			return 0
		else
			return 1
		fi
	fi
# Return 0 if OK or 1 if NOK
}


function del_nfs_export(){

	local CLI_NAME=$1
	local EXIST=$(grep -w ${CLI_NAME} ${NFS_FILE} | grep -w ${CLI_NAME})
	if [ -n "${EXIST}" ]; then
		ex -s -c ":/${STORDIR}\/${CLI_NAME} ${CLI_NAME}/d" -c ":wq" ${NFS_FILE}
		if [ $? -eq 0 ]; then
			return 0
		else
			return 1
		fi
	fi
# Return 0 if OK or 1 if NOK
}
