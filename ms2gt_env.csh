#In your .cshrc file, set $MS2GT_HOME to the directory into which the ms2gt
#package was installed. Then source ms2gt_setup.csh (this file). For example:
#setenv MS2GT_HOME  /export/data/ms2gt
#source $MS2GT_HOME/ms2gt_setup.csh

setenv PATH_MS2GT_SRC         $MS2GT_HOME/src
setenv PATH_MS2GT_IDL         $PATH_MS2GT_SRC/idl

# Set initial values for $IDL_DIR and $IDL_PATH if they aren't yet defined

if (!($?IDL_DIR)) then
    setenv IDL_DIR            /usr/local/rsi/idl
endif
if (!($?IDL_PATH)) then
    setenv IDL_PATH           \+$IDL_DIR/lib
endif
setenv IDL_PATH               $IDL_PATH\:\+$PATH_MS2GT_IDL
setenv PATHMPP                $MS2GT_HOME/lib/maps

set path = ( $path . $MS2GT_HOME/bin \
		     $MS2GT_HOME/src/scripts )
