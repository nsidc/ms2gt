;*========================================================================
;* extract_chan.pro - extract a channel file from a level1b modis file
;*
;* 25-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/extract_chan.pro,v 1.3 2001/01/26 17:27:48 haran Exp haran $
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
;       extract_chan, hdf_file, channel, /get_latlon, conversion=conversion
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

  usage = 'usage: extract_chan, hdf_file, channel ' + $
          '[, /get_latlon]' + $
          '[, conversion=conversion]'

  if n_params() ne 2 then $
    message, usage
  if n_elements(get_latlon) eq 0 then $
    get_latlon = 0
  if n_elements(conversion) eq 0 then $
    conversion = 'raw'

  raw = 0
  corrected = 0
  reflectance = 0
  temperature = 0

  if conversion eq 'raw' then $
    raw = 1
  if conversion eq 'corrected' then $
    corrected = 1
  if conversion eq 'reflectance' then $
    reflectance = 1
  if conversion eq 'temperature' then $
    temperature = 1

  print, 'extract_chan:'
  print, '  hdf_file:   ', hdf_file
  print, '  channel:    ', channel
  print, '  get_latlon: ', get_latlon
  print, '  conversion: ', conversion

  modis_type = strmid(hdf_file, 0, 5)
  if get_latlon ne 0 then begin
      if modis_type eq 'MOD02' then begin
          modis_level1b_read, hdf_file, channel, image, $
            latitude=lat, longitude=lon, $
            raw=raw, corrected=corrected, reflectance=reflectance, $
            temperature=temperature
      endif else begin
          modis_snow_read, hdf_file, channel, image, $
            latitude=lat, longitude=lon
      endelse
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
      if modis_type eq 'MOD02' then begin 
          modis_level1b_read, hdf_file, channel, image, $
            raw=raw, corrected=corrected, reflectance=reflectance, $
            temperature=temperature
      endif else begin
          modis_snow_read, hdf_file, channel, image
      endelse
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
