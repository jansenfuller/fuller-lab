#!/bin/bash
CONFIG_VERSION="3.3.2"
######################
#   USER VARIABLES   #
######################

####################### USER CONFIGURATION START #######################

### NOTIFICATION SETTINGS ###

# Check for script updates.
# On each run, the script will check via GitHub if there's an update, and will
# inform the user via the configured notification systems.
# 1 to enable, 0 to disable.
CHECK_UPDATES=1

# Custom notification service
# Set this to a script/service to be used instead of the default email
# notification. You may want to use a service not natively supported by this
# script or a mail service with custom formatting.
# If you don't want to use this option, don't make changes to this.
# $CURRENT_DIR can be used to get the running directory of the script.
# This script will pass the following parameters to HOOK_NOTIFICATION:
# 1st parameter will be the subject
# 2nd parameter will be the body
HOOK_NOTIFICATION="curl -H 'Authorization: Bearer XXXXX' -H 'Title: $1' -d '$2' https://ntfy.sh/proxmox"

### SCRIPT AND SNAPRAID SETTINGS ###

# Set the threshold of deleted and updated files to stop the sync job from running.
# Note that depending on how active your filesystem is being used, a low number
# here may result in your parity info being out of sync often and/or you having
# to do lots of manual syncing.
DEL_THRESHOLD=250
UP_THRESHOLD=200

# Allow a sync that would otherwise violate the delete threshold, but only
# if the ratio of added to deleted files is greater than the value set.
# Set to 0 to disable this option.
# Example: A senario with 5000 deleted files and 3800 added files would
# result in an ADD_DEL_THRESHOLD of 0.76 (3800/5000)
ADD_DEL_THRESHOLD=0.5

# Set number of warnings before forcing a sync, or force the sync every time
# ignoring thresholds (Forced Sync). This option comes in handy when you cannot be
# bothered to manually start a sync job when DEL_THRESHOLD or UP_TRESHOLD are
# breached due to false alarm.
# Set to 0 to ALWAYS force a sync (Forced Sync, ignoring the thresholds above)
# Set to -1 to NEVER force a sync, the default behaviour (need to manual sync if
# thresholds are breached).
SYNC_WARN_THRESHOLD=-1

# Set percentage and age, in days, of blocks in array to scrub if it is in sync.
# i.e. 0 to disable and 100 to scrub the full array in one go.
# WARNING - depending on size of your array, setting to 100 can take a long time!
SCRUB_PERCENT=25
SCRUB_AGE=10

# Scrub new blocks after sync that have yet to be scrubbed. 1 to enable and any
# other value to disable.
SCRUB_NEW=1

# Set number of script runs before running a scrub. Use this option if you
# don't want to scrub the array every time.
# Set to 0 to disable this option and run scrub every time.
SCRUB_DELAYED_RUN=0

# Prehash Data To avoid the risk of a latent hardware issue, you can enable the
# "pre-hash" mode and have all the data read two times to ensure its integrity.
# This option also verifies the files moved inside the array, to ensure that
# the move operation went successfully, and in case to block the sync and to
# allow to run a fix operation. 1 to enable, any other value to disable.
PREHASH=1

# Set if disk spindown should be performed. Depending on your system, this may
# not work. 1 to enable, any other value to disable.
# hd-idle is required and must be already configured.
SPINDOWN=0

# Increase verbosity of the email output. NOT RECOMMENDED!
# If set to 1, TOUCH and DIFF outputs will be kept in the email, producing
# a mostly unreadable email. You can always check TOUCH and DIFF outputs
# using the TMP file or use the feature RETENTION_DAYS.
# 1 to enable, any other value to disable.
VERBOSITY=0

# SnapRAID detailed output retention for each run.
# Default behaviour is RETENTION_DAYS=0: every time your run SnapRAID, the
# output is saved to "/tmp" and is overridden during every run.
# To enable retention, set RETENTION_DAYS to the days of output you want to
# keep in your home folder. Files will have timestamps.
# SNAPRAID_LOG_DIR can be changed to any folder you like.
RETENTION_DAYS=14
SNAPRAID_LOG_DIR="$HOME"

# Set the option to log SMART info collected by SnapRAID.
# Use SMART_LOG_NOTIFY to send the output to Telegram/Discord
# 1 to enable, any other value to disable.
SMART_LOG=1
SMART_LOG_NOTIFY=0

# Run 'snapraid status' command to show array general information.
# Use SNAP_STATUS_NOTIFY to send the output to Telegram/Discord
# 1 to enable, any other value to disable.
SNAP_STATUS=1
SNAP_STATUS_NOTIFY=0

# SnapRAID configuration file location. The default path works on most
# installations, including OMV6.
# If you're using OMV7, the script will try to pick the file automatically.
# If you have multiple SnapRAID arrays, you must must manually specify the
# config file you want to use. On OMV7 the files are located at /etc/snapraid/
SNAPRAID_CONF="/etc/snapraid.conf"

### CUSTOM HOOKS ###

# Hooks are shell commands that the scripts executes for you.
# You can specify 'before_hook' to perform preparation steps before SnapRAID
# actions and 'after_hook' to perform steps afterwards.

# Set to 1 to enable custom hooks
CUSTOM_HOOK=1

# Custom hook before SnapRAID activities
# This custom hook executes when pre-processing is complete and before
# SnapRAID operations.
# This option does not have any effect if CUSTOM_HOOK is set to 0
# Use NAME for a friendly name, CMD for the command itself.
BEFORE_HOOK_NAME="CMD"
BEFORE_HOOK_CMD="curl -H 'Authorization: Bearer tk_*****' -H 'Title: Begin SnapRAID Scan' -d 'SnapRAID scan is starting' https://ntfy.sh/proxmox"

# Custom hook after SnapRAID activities
# This custom hook executes after SnapRAID operations and will be the
# last command.
# This option does not have any effect if CUSTOM_HOOK is set to 0
# Use NAME for a friendly name, CMD for the command itself.
AFTER_HOOK_NAME="CMD"
AFTER_HOOK_CMD="curl -H 'Authorization: Bearer tk_*****' -H 'Title: SnapRAID Scan Complete' -d 'SnapRAID scan has finished' https://ntfy.sh/proxmox"

####################### USER CONFIGURATION END #######################

####################### SYSTEM CONFIGURATION #######################
# Please make changes only if you know what you're doing

# location of the snapraid binary
SNAPRAID_BIN="/usr/bin/snapraid"
# location of the mail program binary
MAIL_BIN="/usr/bin/mailx"

# Init variables
CHK_FAIL=0
DO_SYNC=0
EMAIL_SUBJECT_PREFIX="(SnapRAID on $(hostname))"
SERVICES_STOPPED=0
SYNC_WARN_FILE="$CURRENT_DIR/snapRAID.warnCount"
SCRUB_COUNT_FILE="$CURRENT_DIR/snapRAID.scrubCount"
TMP_OUTPUT="/tmp/snapRAID.out"
SNAPRAID_LOG="/var/log/snapraid.log"
SECONDS=0 #Capture time

# Expand PATH for smartctl
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Extract info from SnapRAID config
SNAPRAID_CONF_LINES=$(grep -E '^[^#;]' $SNAPRAID_CONF)

IFS=$'\n'
# Build an array of content files
CONTENT_FILES=(
$(echo "$SNAPRAID_CONF_LINES" | grep snapraid.content | cut -d ' ' -f2)
)

# Build an array of parity all files...
PARITY_FILES=(
  $(echo "$SNAPRAID_CONF_LINES" | grep -E '^([2-6z]-)*parity' | cut -d ' ' -f2- | tr ',' '\n')
)
unset IFS
