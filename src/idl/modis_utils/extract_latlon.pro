;*========================================================================
;* extract_latlon.pro - extract latitude and longitude from a level1b
;                       modis file
;*
;* 25-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/extract_chan.pro,v 1.1 2000/10/25 17:09:38 haran Exp $
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
;       extract_latlon, hdf_file, interp_factor, [channel=channel]
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

PRO extract_latlon, hdf_file, interp_factor

  usage = 'usage: extract_latlon, hdf_file, interp_factor, [channel=channel]'

  if n_params() ne 2 then $
    message, usage

  if n_elements(channel) eq 0 then $
    channel = 1

  print, 'extract_latlon:'
  print, '  hdf_file:       ', hdf_file
  print, '  interp_factor:  ', interp_factor
  print, '  channel:        ', channel

  modis_level1b_read, hdf_file, channel, image, /raw, $
                      latitude=lat, longitude=lon
  lat_dimen = size(lat, /dimensions)
  if interp_factor gt 1 then begin
  endif else begin
      image = 0
      hdf_file = strmid(hdf_file, 0, 5) + '1KM' + $
                 strmid(hdf_file, 8)
  endelse
  filestem = strmid(hdf_file, 0, 40)
  cols_string = string(lat_dimen[0], format='(I5.5)')
  rows_string = string(lat_dimen[1], format='(I5.5)')
  lat_file_out = filestem + '_latf_' + $
                 cols_string + '_' + rows_string + '.img'
  lon_file_out = filestem + '_lonf_' + $
                 cols_string + '_' + rows_string + '.img'
  openw, lun, lat_file_out, /get_lun
  writeu, lun, lat
  free_lun, lun
  openw, lun, lon_file_out, /get_lun
  writeu, lun, lon
  free_lun, lun

END ; extract_latlon
