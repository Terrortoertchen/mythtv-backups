# merges the changes in xterm for 256 color mode so it happens every time you log in:
#
if [ -f $HOME/.Xdefaults ]; then
  xrdb -merge $HOME/.Xdefaults
fi
