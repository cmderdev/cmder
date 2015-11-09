# DO NOT EDIT FIS FILE IT WILL BE OVERWRITTEN ON UPDATE
# 
# Add your user customizations to $CMDER_ROOT\config/user-cmder.sh

ORIGINAL_CMDER_ROOT=$CMDER_ROOT
case "$CMDER_ROOT" in *\\*) CMDER_ROOT="$(cygpath -u "$CMDER_ROOT")";; esac
export CMDER_ROOT

if [ -d "/c/Program Files/Git" ] ; then
  GIT_INSTALL_ROOT="/c/Program Files/Git"
elif [ -d "/c/Program Files(x86)/Git" ] ; then
  GIT_INSTALL_ROOT="/c/Program Files(x86)/Git"
elif [ -d "$CMDER_ROOT\vendor/git-for-windows" ] ; then
  GIT_INSTALL_ROOT=$CMDER_ROOT\vendor/git-for-windows
fi

PATH=$GIT_INSTALL_ROOT/bin:$PATH

if [ -f $CMDER_ROOT\config/user-cmder.sh ] ; then
  . $CMDER_ROOT\config/user-cmder.sh
fi
