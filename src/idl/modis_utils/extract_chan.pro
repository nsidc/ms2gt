;*========================================================================
;* extract_chan.pro - extract a channel file from a level1b modis file
;*
;* 25-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/fornav.pro,v 1.1 2000/10/24 22:53:52 haran Exp haran $
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
;       extract_chan, hdf_file, channel
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

PRO extract_chan, hdf_file, channel

  usage = 'usage: extract_chan, hdf_file, channel'

  if n_params() ne 2 then $
    message, usage

  print, 'extract_chan:'
  print, '  hdf_file: ', hdf_file
  print, '  channel:  ', channel

  modis_level1b_read, hdf_file, channel, image, /raw
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
