;*========================================================================
;* extract_latlon.pro - extract latitude and longitude from a level1b
;                       modis file
;*
;* 25-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/extract_latlon.pro,v 1.1 2000/10/25 22:25:39 haran Exp haran $
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

PRO extract_latlon, hdf_file, interp_factor, channel=channel

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
  cols = lat_dimen[0]
  rows = lat_dimen[1]
  if interp_factor gt 1 then begin
      cols_in = cols
      rows_in = rows
      cols = cols_in * interp_factor
      rows = rows_in * interp_factor
  endif else begin
      image = 0
      hdf_file = strmid(hdf_file, 0, 5) + '1KM' + $
                 strmid(hdf_file, 8)
  endelse
  filestem = strmid(hdf_file, 0, 40)
  cols_string = string(cols, format='(I5.5)')
  rows_string = string(rows, format='(I5.5)')
  lat_file_out = filestem + '_latf_' + $
                 cols_string + '_' + rows_string + '.img'
  lon_file_out = filestem + '_lonf_' + $
                 cols_string + '_' + rows_string + '.img'
  openw, lat_lun, lat_file_out, /get_lun
  openw, lon_lun, lon_file_out, /get_lun
  if interp_factor gt 1 then begin
      chan_string = string(channel, format='(I2.2)')
      chan_file_out = filestem + '_ch' + chan_string + '_' + $
                      cols_string + '_' + rows_string + '.img'
      openw, chan_lun, chan_file_out, /get_lun
      writeu, chan_lun, image
      free_lun, chan_lun
      rows_per_scan_in = 10
      scans = rows_in / rows_per_scan_in
      rows_per_scan_out = interp_factor * rows_per_scan_in
      for scan = 0, scans - 1 do begin
          if scan mod 10 eq 0 then $
            print, scan
          first_row_in = scan * rows_per_scan_in
          last_row_in  = first_row_in + rows_per_scan_in - 1
          image = congrid(lat[*,first_row_in:last_row_in], $
                          cols, rows_per_scan_out, cubic=0.5)
          writeu, lat_lun, image
          image = congrid(lon[*,first_row_in:last_row_in], $
                          cols, rows_per_scan_out, cubic=0.5)
          writeu, lon_lun, image
      endfor
  endif else begin
      writeu, lat_lun, lat
      writeu, lon_lun, lon
  endelse
  free_lun, lat_lun
  free_lun, lon_lun

END ; extract_latlon
