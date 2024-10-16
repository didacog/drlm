# runbackup workflow

# DRLM 2.4.0 - Imports client configurations
# Now you can define DRLM options, like Max numbers of backups to keep in filesystem (HISTBKPMAX), for
# each client and for each client configuration.

# Also since DRLM 2.4.0 the base configuration is set without config files.
# For this in necessary to specify the default OUTPUT if is necessary for the workflow
OUTPUT="PXE"

# Import drlm specific client configuration if exists
if [ -f $CONFIG_DIR/clients/$CLI_NAME.drlm.cfg ] ; then
  source $CONFIG_DIR/clients/$CLI_NAME.drlm.cfg
  LogPrint "Sourcing ${CLI_NAME} client configuration ($CONFIG_DIR/clients/$CLI_NAME.drlm.cfg)"
fi

# Import client backup configuration 
if [ "$CLI_CFG" == "default" ]; then
  if [ -f $CONFIG_DIR/clients/$CLI_NAME.cfg ]; then
    source $CONFIG_DIR/clients/$CLI_NAME.cfg
    LogPrint "Sourcing ${CLI_NAME} client configuration ($CONFIG_DIR/clients/$CLI_NAME.cfg)"
  else
    LogPrint "$CONFIG_DIR/clients/$CLI_NAME.cfg config file not found, running with default values"
  fi
elif [ -n "$CLI_CFG" ]; then
  if [ -f $CONFIG_DIR/clients/$CLI_NAME.cfg.d/$CLI_CFG.cfg ]; then
    source $CONFIG_DIR/clients/$CLI_NAME.cfg.d/$CLI_CFG.cfg
    LogPrint "Sourcing ${CLI_NAME} client configuration ($CONFIG_DIR/clients/$CLI_NAME.cfg.d/$CLI_CFG.cfg)"
  else 
    Error "$CONFIG_DIR/clients/$CLI_NAME.cfg.d/$CLI_CFG.cfg config file $CLI_CFG.cfg not found"
  fi
fi
