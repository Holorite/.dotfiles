#
# History configuration
#

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000      # lines kept in memory per session
SAVEHIST=50000      # lines persisted to $HISTFILE

setopt HIST_IGNORE_DUPS         # collapse runs of the same command
setopt HIST_IGNORE_ALL_DUPS     # if a new command matches an older one, drop the older
setopt HIST_SAVE_NO_DUPS        # don't write duplicates to disk
setopt HIST_FIND_NO_DUPS        # skip dupes when searching
setopt HIST_REDUCE_BLANKS       # trim redundant whitespace
setopt HIST_IGNORE_SPACE        # commands prefixed with a space are not recorded
setopt HIST_VERIFY              # `!cmd` expands into the line for editing rather than running
setopt EXTENDED_HISTORY         # record timestamp + duration with each entry
setopt INC_APPEND_HISTORY       # append on each command, not at shell exit
setopt SHARE_HISTORY            # cross-session: re-read history before each prompt
