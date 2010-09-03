;*========================================================================
;* extract_latlon.pro - extract latitude and longitude from a mod02 or
;                       mod03 file
;*
;* 25-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /data/tharan/ms2gth/src/idl/modis_utils/extract_latlon.pro,v 1.8 2010/09/03 19:07:39 tharan Exp tharan $
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
;       extract_latlon, hdf_file, tag
;                       [, swath_width_fraction=swath_width_fraction]
;
; ARGUMENTS:
;
; KEYWORDS:
;       swath_width_fraction: specifies the central fraction of the swath to
;         extract. The default value is 1.0.
;
; EXAMPLE:
;
; ALGORITHM:
;
; REFERENCE:
;-

PRO extract_latlon, hdf_file, tag, swath_width_fraction=swath_width_fraction

  usage = 'usage: extract_latlon, hdf_file, tag ' + $
          '[, swath_width_fraction=swath_width_fraction]'

  if n_params() ne 2 then $
    message, usage

  if n_elements(swath_width_fraction) eq 0 then $
     swath_width_fraction = 1.0

  print, 'extract_latlon:'
  print, '  hdf_file:             ', hdf_file
  print, '  tag:                  ', tag
  print, '  swath_width_fraction: ', swath_width_fraction

  ancillary = 'none'
  modis_ancillary_read, hdf_file, ancillary, image, $
                        latitude=lat, longitude=lon, $
                        swath_width_fraction=swath_width_fraction
  lat_dimen = size(lat, /dimensions)
  cols = lat_dimen[0]
  rows = lat_dimen[1]
  cols_string = string(cols, format='(I5.5)')
  rows_string = string(rows, format='(I5.5)')
  lat_file_out = tag + '_latf_' + $
                 cols_string + '_' + rows_string + '.img'
  lon_file_out = tag + '_lonf_' + $
                 cols_string + '_' + rows_string + '.img'
  openw, lat_lun, lat_file_out, /get_lun
  openw, lon_lun, lon_file_out, /get_lun
  writeu, lat_lun, lat
  writeu, lon_lun, lon
  free_lun, lat_lun
  free_lun, lon_lun

END ; extract_latlon
;       swath_width_factor: specifies the central fraction of the swath to
;         extract. The default value is 1.0.
