#!/bin/sh --this-shebang-is-just-here-to-inform-shellcheck--

# Expand $PATH to include the directory where snappy applications go.
if [ "${PATH#*/snap/bin}" = "${PATH}" ]; then
    export PATH=$PATH:/snap/bin
fi

# desktop files (used by desktop environments within both X11 and Wayland) are
# looked for in XDG_DATA_DIRS; make sure it includes the relevant directory for
# snappy applications' desktop files.
if [ "${XDG_DATA_DIRS#*/snapd/desktop}" = "${XDG_DATA_DIRS}" ]; then
    export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/var/lib/snapd/desktop"
fi

