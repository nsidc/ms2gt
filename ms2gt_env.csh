#In your .cshrc file, set $MODIS_HOME to the directory into which the modis
#package was installed. Then source modis_setup.csh (this file). For example:
#setenv MODIS_HOME  /export/data/modis
#source $MODIS_HOME/modis_setup.csh

setenv PATH_MODIS_SRC         $MODIS_HOME/src
setenv PATH_MODIS_IDL         $PATH_MODIS_SRC/idl

# Set initial values for $IDL_DIR and $IDL_PATH if they aren't yet defined

if (!($?IDL_DIR)) then
    setenv IDL_DIR            /usr/local/rsi/idl
endif
if (!($?IDL_PATH)) then
    setenv IDL_PATH           \+$IDL_DIR/lib
endif
setenv IDL_PATH               $IDL_PATH\:\+$PATH_MODIS_IDL
setenv PATHMPP                $MODIS_HOME/lib/maps

set path = ( $path . $MODIS_HOME/bin \
		     $MODIS_HOME/src/scripts )
