;*========================================================================
;* extract_chan.pro - extract a channel file from a level1b modis file
;*
;* 25-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/extract_chan.pro,v 1.1 2000/10/25 17:09:38 haran Exp haran $
;*========================================================================*/

;+
; NAME:
;	extract_chan
;
; PURPOSE:
;
; CATEGORY:
;	Modis.
;
; CALLING SEQUENCE:
;       extract_chan, hdf_file, channel, /get_latlon
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

PRO extract_chan, hdf_file, channel, get_latlon=get_latlon

  usage = 'usage: extract_chan, hdf_file, channel [, /get_latlon]'

  if n_params() ne 2 then $
    message, usage

  if n_elements(get_latlon) eq 0 then $
    get_latlon = 0
  print, 'extract_chan:'
  print, '  hdf_file:   ', hdf_file
  print, '  channel:    ', channel
  print, '  get_latlon: ', get_latlon

  if get_latlon ne 0 then begin
      modis_level1b_read, hdf_file, channel, image, /raw, $
        latitude=lat, longitude=lon
      lat_dimen = size(lat, /dimensions)
      cols = lat_dimen[0]
      rows = lat_dimen[1]
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
  endif else begin
      modis_level1b_read, hdf_file, channel, image, /raw
  endelse
  image_dimen = size(image, /dimensions)
  filestem = strmid(hdf_file, 0, 40)
  channel_string = string(channel, format='(I2.2)')
  cols_string = string(image_dimen[0], format='(I5.5)')
  rows_string = string(image_dimen[1], format='(I5.5)')
  file_out = filestem + '_ch' + channel_string + '_' + $
             cols_string + '_' + rows_string + '.img'
  openw, lun, file_out, /get_lun
  writeu, lun, image
  free_lun, lun

END ; extract_channel
