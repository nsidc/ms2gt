; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; $Log$
;----------------------------
;revision 1.2	locked by: haran;
;date: 2001/03/08 01:00:16;  author: haran;  state: Exp;  lines: +7 -7
;changed uppercase procedure names to lowercase
;----------------------------
;revision 1.1
;date: 2001/03/08 00:50:25;  author: haran;  state: Exp;
;Initial revision
;
; Calling sequence:
; IDL > @Make
;
; Batch program to compile all the code into a ".sav" file.
;

.compile hdf_info

.compile nsidc_dist_get_latlon
.compile nsidc_dist_get_color
.compile nsidc_dist_table__define
.compile nsidc_dist_plot__define
.compile nsidc_dist_grid__define
.compile nsidc_dist_file__define
.compile nsidc_dist_main__define

.compile eosimagetool
.compile main

RESOLVE_ALL

SAVE, /ROUTINES, FILENAME='eosimagetool.sav'

