; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; Calling sequence:
; IDL > @Make
;
; Batch program to compile all the code into a ".sav" file.
;

.compile hdf_info
.compile NSIDC_DIST_GET_LATLON
.compile NSIDC_DIST_GET_COLOR

.compile NSIDC_DIST_TABLE__DEFINE
.compile NSIDC_DIST_PLOT__DEFINE
.compile NSIDC_DIST_GRID__DEFINE
.compile NSIDC_DIST_FILE__DEFINE
.compile NSIDC_DIST_MAIN__DEFINE

.compile eosimagetool
.compile main

RESOLVE_ALL

SAVE, /ROUTINES, FILENAME='eosimagetool.sav'

