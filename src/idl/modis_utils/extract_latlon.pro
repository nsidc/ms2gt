;*========================================================================
;* extract_latlon.pro - extract latitude and longitude from a level1b
;                       modis file
;*
;* 25-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/extract_latlon.pro,v 1.3 2001/01/08 17:38:44 haran Exp haran $
;*========================================================================*/

;+
; NAME:
;	extract_latlon
;
; PURPOSE:
;
; CATEGORY:
;	Modis.
;
; CALLING SEQUENCE:
;       extract_latlon, hdf_file
;
; ARGUMENTS:
;
; KEYWORDS:
;
; EXAMPLE:
;
; ALGORITHM:
;
; REFERENCE:
;-

PRO extract_latlon, hdf_file

  usage = 'usage: extract_latlon, hdf_file'

  if n_params() ne 1 then $
    message, usage

  print, 'extract_latlon:'
  print, '  hdf_file:       ', hdf_file

  channel = 1
  modis_level1b_read, hdf_file, channel, image, /raw, $
                      latitude=lat, longitude=lon
  lat_dimen = size(lat, /dimensions)
  cols = lat_dimen[0]
  rows = lat_dimen[1]
  image = 0
  filestem = strmid(hdf_file, 0, 40)
  cols_string = string(cols, format='(I5.5)')
  rows_string = string(rows, format='(I5.5)')
  lat_file_out = filestem + '_latf_' + $
                 cols_string + '_' + rows_string + '.img'
  lon_file_out = filestem + '_lonf_' + $
                 cols_string + '_' + rows_string + '.img'
  openw, lat_lun, lat_file_out, /get_lun
  openw, lon_lun, lon_file_out, /get_lun
  writeu, lat_lun, lat
  writeu, lon_lun, lon
  free_lun, lat_lun
  free_lun, lon_lun

END ; extract_latlon
