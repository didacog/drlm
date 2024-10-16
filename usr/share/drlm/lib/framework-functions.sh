# framework functions for Disaster Recovery Linux Manager
#
#    Disaster Recovery Linux Manager is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.

#    Disaster Recovery Linux Manager is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Disaster Recovery Linux Manager; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#

# source a file given in $1
function Source () {
  local source_file="$1"
  local source_return_code=0
  # Skip if source file name is empty:
  if test -z "$source_file" ; then
    Debug "Skipping Source() because it was called with empty source file name"
    return
  fi
  # Ensure source file is not a directory:
  test -d "$source_file" && Error "Source file '$source_file' is a directory, cannot source"
  # Skip if source file does not exist of if its content is empty:
  if ! test -s "$source_file" ; then
    Debug "Skipping Source() because source file '$source_file' not found or empty"
    return
  fi
  # Clip leading standard path to rear files (usually /usr/share/rear/):
  local relname="${source_file##$SHARE_DIR/}"
  # Simulate sourcing the scripts in $SHARE_DIR
  if test "$SIMULATE" && expr "$source_file" : "$SHARE_DIR" >/dev/null; then
    LogPrint "Source $relname"
    return
  fi
  # Step-by-step mode or breakpoint if needed
  : ${BREAKPOINT:=}
  if [[ "$STEPBYSTEP" || ( "$BREAKPOINT" && "$relname" == "$BREAKPOINT" ) ]] ; then
    read -p "Press ENTER to include '$source_file' ... " 0<&6 1>&7 2>&8
  fi
  Log "======================================================================="
  Log "= Including --> ${1##$SHARE_DIR/}"
  Log "======================================================================="
  
  # DEBUGSCRIPTS mode settings:
  if test "$DEBUGSCRIPTS" ; then
    Debug "Entering debugscript mode via 'set -x'."
    local saved_bash_flags_and_options_commands="$( get_bash_flags_and_options_commands )"
    set -x
  fi

  # The actual work (source the source file):
  source "$source_file"
  source_return_code=$?
  test "0" -eq "$source_return_code" || Debug "Source function: 'source $source_file' returns $source_return_code"
  
  # Ensure that after each sourced file we are back in usual working directory
  cd "$WORKING_DIR" || LogPrintError "Failed to 'cd $WORKING_DIR'"
  
  # Undo DEBUGSCRIPTS mode settings:
  if test "$DEBUGSCRIPTS" ; then
    Debug "Leaving debugscript mode (back to previous bash flags and options settings)."
    { apply_bash_flags_and_options_commands "$saved_bash_flags_and_options_commands" ; } 2>/dev/null
  fi
  
  # Breakpoint if needed:
  if [[ "$BREAKPOINT" && "$relname" == "$BREAKPOINT" ]] ; then
    # Use the original STDIN STDOUT and STDERR when 'rear' was launched by the user
    # to get input from the user and to show output to the user (cf. _input-output-functions.sh):
    read -p "Press ENTER to continue ... " 0<&6 1>&7 2>&8
  fi
  # Return the return value of the actual work (source the source file):
  return $source_return_code
}

# collect scripts given in $1 in the standard subdirectories and
# sort them by their script file name and source them
function SourceStage() {
  stage="$1"
  shift
  STARTSTAGE=$SECONDS
  Log "Running '$stage' stage"
  scripts=(
    $(
    cd $SHARE_DIR/$stage ;
    # We always source scripts in the same subdirectory structure. The {..,..,..} way of writing
    # it is just a shell shortcut that expands as intended.
    ls -d  {custom,default,"$ARCH","$OS","$OS_MASTER_VENDOR","$OS_MASTER_VENDOR_ARCH","$OS_MASTER_VENDOR_VERSION","$OS_VENDOR","$OS_VENDOR_ARCH","$OS_VENDOR_VERSION"}/*.sh \
      "$BACKUP"/{default,"$ARCH","$OS","$OS_MASTER_VENDOR","$OS_MASTER_VENDOR_ARCH","$OS_MASTER_VENDOR_VERSION","$OS_VENDOR","$OS_VENDOR_ARCH","$OS_VENDOR_VERSION"}/*.sh \
      "$OUTPUT"/{default,"$ARCH","$OS","$OS_MASTER_VENDOR","$OS_MASTER_VENDOR_ARCH","$OS_MASTER_VENDOR_VERSION","$OS_VENDOR","$OS_VENDOR_ARCH","$OS_VENDOR_VERSION"}/*.sh \
      "$OUTPUT"/"$BACKUP"/{default,"$ARCH","$OS","$OS_MASTER_VENDOR","$OS_MASTER_VENDOR_ARCH","$OS_MASTER_VENDOR_VERSION","$OS_VENDOR","$OS_VENDOR_ARCH","$OS_VENDOR_VERSION"}/*.sh \
    | sed -e 's#/\([0-9][0-9][0-9]\)_#/!\1!_#g' | sort -t \! -k 2 | tr -d \!
    )
    # This sed hack is neccessary to sort the scripts by their 2-digit number INSIDE indepentand of the
    # directory depth of the script. Basicall sed inserts a ! before and after the number which makes the
    # number always field nr. 2 when dividing lines into fields by !. The following tr removes the ! to
    # restore the original script name. But now the scripts are already in the correct order.
    )
  # if no script is found, then $scripts contains only .
  # remove the . in this case
  test "$scripts" = . && scripts=()
  
  # Variables per controlar la carrega de l'script més prioritari
  prev_script="empty"
  actu_script="empty"

  if test "${#scripts[@]}" -gt 0 ; then
    for script in ${scripts[@]} ; do
      actu_script=`echo $(basename $script) | cut -c1,2`
      if test $actu_script != $prev_script; then
        Source $SHARE_DIR/$stage/"$script"
        # echo "Carrego l\'script: " $script
      fi
      prev_script=$actu_script
    done
    Log "Finished running '$stage' stage in $((SECONDS-STARTSTAGE)) seconds"
  else
    Log "Finished running empty '$stage' stage"
  fi
}
