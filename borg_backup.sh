#!/bin/sh
export BORG_REPO=/mnt/storage2/root.borg

# some helpers and error handling:
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup"

# Back up the most important directories into an archive named after
# the machine this script is currently running on:

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
    --exclude 'home/*/.cache/*'     \
    --exclude 'var/tmp/*'           \
                                    \
    '{hostname}'                    \
    /etc                            \
    /home                           \
    /root                           \
    /var

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}' matching is very important to
# limit prune's operation to archives with exactly that name and not apply
# to archives with other names also:

borg prune               \
    '{hostname}'         \
    --list               \
    --show-rc            \
    --keep-daily    7    \
    --keep-weekly   4    \

prune_exit=$?

# Switch repos
export BORG_REPO=/mnt/storage2/storage.borg

# Back up storage
# the machine this script is currently running on:

borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
    --exclude 'home/*/.cache/*'     \
    --exclude 'var/tmp/*'           \
                                    \
    'storage'                       \
    /mnt/storage                    \

backup_exit=$?

info "Pruning repository"

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}' matching is very important to
# limit prune's operation to archives with exactly that name and not apply
# to archives with other names also:

borg prune               \
    '{hostname}-storage'         \
    --list               \
    --show-rc            \
    --keep-daily    7    \
    --keep-weekly   4    \
    --keep-monthly  6

prune_exit=$?

# actually free repo disk space by compacting segments

info "Compacting repository"

borg compact -v

compact_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=$(( compact_exit > global_exit ? compact_exit : global_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup, Prune, and Compact finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup, Prune, and/or Compact finished with warnings"
else
    info "Backup, Prune, and/or Compact finished with errors"
fi

exit ${global_exit}
