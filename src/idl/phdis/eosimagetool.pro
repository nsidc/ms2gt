; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; $Log$
;
; Calling sequence:
; EOSImageTool
;
; This application consists of 5 major objects:
;
; NSIDC_DIST_MAIN.   The main object, controls the other objects,
; manages the main window and the holding base for file objects.
;
; NSIDC_DIST_FILE.   One of these is created for each opened file.
; It creates/manages the file base for the corresponding file,
; and manges subsequent grid objects.
;
; NSIDC_DIST_GRID.   One of these is created for each image
; display window.   It handles all the image viewing and sometimes
; sends commands to other grid objects.
;
; NSIDC_DIST_PLOT.   Similar to the grid object, except displays
; line plots rather than images.   Stubbed out for future use.
;
; NSIDC_DIST_TABLE.   The data table display object, started from
; grid objects.
;
PRO EOSIMAGETOOL

   ; Create the main object.
   o = OBJ_NEW('NSIDC_DIST_MAIN')

   ; Start widget event processing.
   XMANAGER

   ; All done, destroy the main object.
   OBJ_DESTROY, o

END
