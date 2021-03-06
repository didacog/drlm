# bkpmgr workflow

if [ "$BKP_TYPE" == "PXE" ]; then

  LogPrint "Enabling PXE boot"

  # Unpack GRUB files if do not exist 
  if [[ ! -d ${STORDIR}/boot/grub ]]; then
    mkdir -p ${STORDIR}/boot/grub
    cp -r /var/lib/drlm/store/boot/grub ${STORDIR}/boot
  fi

  if [[ ! -d ${STORDIR}/boot/cfg ]]; then 
    mkdir -p ${STORDIR}/boot/cfg 
  fi

  CLI_MAC=$(get_client_mac $CLI_ID)
  F_CLI_MAC=$(format_mac ${CLI_MAC} ":")
  CLI_KERNEL_FILE=$(ls ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/*kernel | xargs -n 1 basename)
  CLI_INITRD_FILE=$(ls ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/*initrd* | xargs -n 1 basename)
  CLI_REAR_PXE_FILE=$(grep -l -w append ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/rear* | xargs -n 1 basename)
  CLI_KERNEL_OPTS=$(grep -h -w append ${STORDIR}/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_REAR_PXE_FILE} | awk '{print substr($0, index($0,$3))}' | sed 's/vga/gfxpayload=vga/')

  Log "PXE:${CLI_NAME}: Creating MAC Address (GRUB2) boot configuration file ..."

  cat << EOF > ${STORDIR}/boot/cfg/${F_CLI_MAC}

echo "Loading Linux kernel ..."
linux (tftp)/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_KERNEL_FILE} ${CLI_KERNEL_OPTS}
echo "Loading Linux Initrd image ..."
initrd (tftp)/${CLI_NAME}/${CLI_CFG}/PXE/${CLI_INITRD_FILE}

EOF

  if [ -f ${STORDIR}/boot/cfg/${F_CLI_MAC} ]; then
      LogPrint  "- Created MAC Address (GRUB2) boot configuration file for PXE"
  else
      Error "- Problem Creating MAC Address (GRUB2) boot configuration file for PXE"
  fi

fi