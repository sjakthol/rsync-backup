A script for taking snapshot backups of local directories. The rsync's
--link-dest feature is used to save space between two snapshots.

## Features
* Take snapshots of local directories and back them up to either local or remote
(via ssh) storage
* Interoperability with restricted rsync (rrsync) for remote backup storage

## Usage
To backup a directory, clone this repository and execute

```shell
  ./rsync-backup.sh <source> <target>
```
where
* `<source>` is a path to the directory to backup
* `<target>` is a path to the directory where the timestamped snapshots will be
saved.

You can use the environmental variable `RSYNC_OPTIONS` to pass extra arguments
(e.g. excludes) to rsync. Tip: `RSYNC_RSH` can be used to set the ssh command
rsync uses.

### Example
For example, to backup the directory `/home/bob/Documents` to
`~/backups/documents/` in remote machine `example.com`, execute

```shell
  ./rsync-backup.sh /home/bob/Documents/ bob@example.com:backups/documents/
```

### Notes
* Always provide the source directory path in the same form or the previous
snapshots won't be found and space is wasted. Also, the target should be the
same for each backup.
* The username or hostname for the remote target must not contain a colon. The
script needs to determine the target directory on the remote machine for rrsync
interoperability.
* The target directory must exist and must not be used to backup any other
directories.
* The script saves information about the latest snapshots to
`$HOME/.config/rsync-backup`. If you want to remove this program, you'll most
likely want to remove that directory too.
