#!/bin/sh
#
# A script for taking snapshot backups of local directories. The rsync's
# --link-dest feature is used to save space between two snapshots.
#
# Usage:
#     ./rsync-backup.sh <source> <target>
#
# <source> = The directory to backup. If the value differs from anything that
#            the script has seen before a full backup will be performed. Thus
#            when backing up the same directory, this value needs to be the
#            same or the backups will consume a lot more space.
# <target> = The target directory for the backup. The path can be anything
#            rsync supports. The directory will be the base for the snapshots
#            with each snapshot having their own directory named by the time
#            they were taken. The target MUST not be used for backing up other
#            directories.
#
# If you wish to pass options to the rsync command, specify them in an
# enviromental variable called RSYNC_OPTIONS. The options found there will be
# added to the rsync command invocation.
#
# TIP: RSYNC_RSH env var can also be used to set ssh related options.

set -e

START=$(date +%s.%N)

# Check correct usage
if [ $# != 2 ]; then
  echo "Usage: $0 <source> <target>"
  exit 1
fi

# The directory containing the identifiers for previous snapshots
STATE_DIR="$HOME/.config/rsync-backup"
if [ ! -d $STATE_DIR ]; then
  echo "Creating state directory to $STATE_DIR"
  mkdir -p "$STATE_DIR"
fi

# The source and target directories
DIR_TO_BACKUP="$1"
TARGET_DIR="$2"

# Check that the source directory exists
if [ ! -d "$DIR_TO_BACKUP" ]; then
  echo "ERROR: $DIR_TO_BACKUP is not a directory."
  exit 1
fi

echo "Backing up $DIR_TO_BACKUP to $TARGET_DIR"

# A path-safe identifier for the uploaded source directory.
SOURCE_HASH=$(echo -n "$DIR_TO_BACKUP" | sha1sum | cut -d " " -f 1)

# Read the previous identifier
STATE_FILE="$STATE_DIR/$SOURCE_HASH"
if [ -f "$STATE_FILE" ]; then
  PREV_ID=$(cat "$STATE_FILE")
fi

# The new identifier is the current ISO-8601 timestamp
NEW_ID=$(date --iso-8601=seconds)

# The target for new backup
BACKUP_TARGET="$TARGET_DIR/$NEW_ID/"

# The target DIRECTORY (without ssh host) of the previous backup. rrsync on
# the server mandates an absolute path - cutting the host part away from the
# destination works in most cases
PREVIOUS_TARGET=$(echo "$TARGET_DIR/$PREV_ID" | cut -d ":" -f2-)

# Options for rsync
DEFAULT_OPTIONS="\
  --archive \
  --delete \
  --verbose \
  --human-readable \
  --ignore-existing \
  --link-dest /$PREVIOUS_TARGET"

echo "Backup configuration:"
echo "  * Source Directory: $DIR_TO_BACKUP"
echo "  * Target Directory: $TARGET_DIR"
echo "  * Previous snapshot: $PREV_ID"
echo "  * New snapshot: $NEW_ID"
echo "  * Default rsync options: $DEFAULT_OPTIONS"
echo "  * Extra rsync options: $RSYNC_OPTIONS"
echo "  * rsync SSH options: $RSYNC_RSH"

echo "Performing backup:"
echo "rsync $DEFAULT_OPTIONS $RSYNC_OPTIONS $DIR_TO_BACKUP $BACKUP_TARGET"
rsync $DEFAULT_OPTIONS $RSYNC_OPTIONS $DIR_TO_BACKUP $BACKUP_TARGET

# Write the newest backup id to the state file
echo -n "$NEW_ID" > $STATE_FILE

END=$(date +%s.%N)
TIME_DELTA=$(echo "$END - $START" | bc)
echo "Backup completed in $TIME_DELTA seconds"
