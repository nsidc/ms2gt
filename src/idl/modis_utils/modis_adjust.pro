;*========================================================================
;* modis_adjust.pro - adjust modis data based on solar zenith and/or
;*                    regressions
;*
;* 15-Apr-2002  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/ms2gth/src/idl/modis_utils/modis_adjust.pro,v 1.2 2001/02/19 16:07:24 haran Exp $
;*========================================================================*/

;+
; NAME:
;	modis_adjust
;
; PURPOSE:
;       Optionally modify modis data with solar zenith correction. Then
;       optionally compute a regression for each sensor relative to a
;       particular sensor and adjust the data accordingly. Optionally
;       undo the solar zenith correction.
;
; CATEGORY:
;	Modis.
;
; CALLING SEQUENCE:
;       MODIS_ADJUST, cols, scans, file_in, file_out,
;               [, rows_per_scan=rows_per_scan]
;               [, data_type=data_type]
;               [, regress_sensor=regress_sensor]
;               [, file_soze=file_soze]
;               [, /undo_soze]
;               [, plot_tag=plot_tag]
;               [, x_max=x_max]
;
; ARGUMENTS:
;    Inputs:
;       cols: number of columns in the input file.
;       scans: number of scans to process in the input file.
;       file_in: file containing the channel data to be adjusted.
;    Outputs:
;       file_out: file containing adjusted channel data.
;
; KEYWORDS:
;       rows_per_scan: number of rows in each scan in file_in. The default
;         is 40.
;       data_type: 2-character string specifying the data type of the data
;         if file in to be adjusted:
;           u1: unsigned 8-bit integer.
;           u2: unsigned 16-bit integer.
;           s2: signed 16-bit integer.
;           u4: unsigned 32-bit integer.
;           s4: signed 32-bit integer.
;           f4: 32-bit floating-point (default).
;       regress_sensor: the 1-based sensor index indicating which sensor to
;         use as the dependent variable when performing regressions.
;         Use 0 to indicate that regressions should not be performed. Must
;         be less than or equal to rows_per_scan. The default value is 20.
;       file_soze: file containing solar zenith values in 32-bit floating-point
;         degrees. Should have the same number of cols and scans as file_in.
;         Each input value is divided by the cosine of the corresponding
;         solar zenith value before any regressions are performed. The default
;         value of file_soze is a null string indicating that no solar zenith
;         file should be read.
;       undo_soze: If set then each input value is multiplied by the cosine
;         of the corresponding solar zenith value after regressions are
;         performed. If file_soze is a null string, then unod_soze is ignored.
;       plot_tag: string used to name and label regression plot files. Plot
;         files will be labelled plot_tag_xx.ps where xx is a 1-based sensor
;         sensor index. No plot will be generated for regress_sensor. The
;         default value of plot_tag is a null string indicating that no plots
;         should be created. If regress_sensor is 0, then plot_tag is ignored.
;       x_max: maximum x value to plot. Default is 0 meaning use the maximum
;         value in the data. if plot_tag is a null string, then x_max is
;         ignored.
;
; EXAMPLE:
;         modis_adjust, 5416, 47, $
;                       'inst20020204_ref_ch01_5416_01880.img', $
;                       'inst20020204_ref_ch01_5416_01880_adj.img', $
;                       file_soze='instref20020204_soze_scaa_05416_00047_00000_40.img', $
;                       plot_tag='inst20020204_ref_ch01', x_max=1.5
;
; ALGORITHM:
;
; REFERENCE:
;-

Pro modis_adjust, cols, scans, file_in, file_out, $
                  rows_per_scan=rows_per_scan, $
                  data_type=data_type, $
                  regress_sensor=regress_sensor, $
                  file_soze=file_soze, $
                  undo_soze=undo_soze, $
                  plot_tag=plot_tag, $
                  x_max=x_max

  epsilon = 1e-6

  lf = string(10B)

  usage = lf + 'usage: modis_adjust, ' + lf + $
                'cols, scans, file_in, file_out, ' + lf + $
                '[, rows_per_scan=rows_per_scan] ' + lf + $
                '[, data_type=data_type] ' +   lf + $
                '[, regress_sensor=regress_sensor] ' + lf + $
                '[, file_soze=file_soze] ' + lf + $
                '[, /undo_soze] ' + lf + $
                '[, plot_tag=plot_tag] ' + lf + $
                '[, x_max=x_max]'

  if n_params() ne 4 then $
    message, usage

  if n_elements(rows_per_scan) eq 0 then $
    rows_per_scan = 40
  if n_elements(data_type) eq 0 then $
    data_type = 'f4'
  if n_elements(regress_sensor) eq 0 then $
    regress_sensor = 20
  if n_elements(file_soze) eq 0 then $
    file_soze = ''
  if n_elements(undo_soze) eq 0 then $
    undo_soze = 0
  if n_elements(plot_tag) eq 0 then $
    plot_tag = ''
  if n_elements(x_max) eq 0 then $
    x_max = 0

  print, 'modis_adjust:'
  print, '  cols:             ', cols
  print, '  scans:            ', scans
  print, '  file_in:          ', file_in
  print, '  file_out:         ', file_out
  print, '  rows_per_scan:    ', rows_per_scan
  print, '  data_type:        ', data_type
  print, '  regress_sensor:   ', regress_sensor
  print, '  file_soze:        ', file_soze
  print, '  undo_soze:        ', undo_soze
  print, '  plot_tag:         ', plot_tag

  if regress_sensor gt rows_per_scan then $
    message, 'regress_sensor must be less than or equal to rows_per_scan' + $
             usage

  ; allocate arrays

  case data_type of
      'u1': begin
          swath = bytarr(cols, rows_per_scan, scans)
          bytes_per_element = 1
          min_out = 0.0
          max_out = 255.0
      end
      'u2': begin
          swath = uintarr(cols, rows_per_scan, scans)
          bytes_per_element = 2
          min_out = 0.0
          max_out = 65535.0
      end
      's2': begin
          swath = intarr(cols, rows_per_scan, scans)
          bytes_per_element = 2
          min_out = -32768.0
          max_out = 32767.0
      end
      'u4': begin
          swath = ulonarr(cols, rows_per_scan, scans)
          bytes_per_element = 4
          min_out = 0.0
          max_out = 4294967295.0
      end
      's4': begin
          swath = lontarr(cols, rows_per_scan, scans)
          bytes_per_element = 4
          min_out = -2147483648.0
          max_out = 2147483647.0
      end
      'f4': begin
          swath = fltarr(cols, rows_per_scan, scans)
          bytes_per_element = 4
      end
      else: message, 'invalid data_type' + usage
  end
  type_code = size(swath, /type)

  if file_soze ne '' then $
    soze = fltarr(cols, rows_per_scan, scans)

  ; open, read, and close input files

  openr, lun, file_in, /get_lun
  readu, lun, swath
  free_lun, lun
  if file_soze ne '' then begin
      openr, lun, file_soze, /get_lun
      readu, lun, soze
      free_lun, lun
      
      ;  compute cos(soze)
      
      soze = cos(temporary(soze) * !dtor)

      ;  compute 1/cos(soze)
      ;  don't divide by small cosines

      i = where(abs(soze) lt epsilon, count)
      if count gt 0 then $
        soze[i] = 1.0
      i = where(abs(soze) ge epsilon, count)
      if count gt 0 then $
        soze[i] = 1.0 / temporary(soze[i])

      ;  multiply swath data by 1/cos(soze)

      swath = temporary(swath) * soze
  endif

  ;  Process a sensor's worth of data at a time

  if regress_sensor gt 0 then begin
      n = long(cols) * scans

      ;  y is all the data for the regress_sensor

      y = reform(swath[*, regress_sensor - 1, *], n)

      ;  process one sensor at a time

      for sensor = 1, rows_per_scan do begin
          if sensor ne regress_sensor then begin

              ;  x is all the data for the sensor

              x = reform(swath[*, sensor - 1, *], 1, n)
              slope = regress(x, y, const=intercept)
              if plot_tag ne '' then begin

                  ;  create the scatter plot for this sensor

                  file_plot = string(plot_tag + '_', sensor, '.ps', $
                                     format='(a, i2.2, a)')
                  mydev = !D.NAME
                  set_plot, 'ps'
                  
                  device, filename=file_plot, /landscape, /color, $
                    bits_per_pixel=8
                  device, xsize=10.0, ysize=7.5, /inches
                  plot, x, y, psym=3, ystyle=1, charsize=1.0, $
                    title=plot_file, $
                    xtitle=string('sensor: ', sensor, $
                                  format='(a, i2.2)'), $
                    ytitle=string('sensor: ', regress_sensor, $
                                  format='(a, i2.2)')
                  x_min = 0
                  if x_max eq 0 then $
                    x_max = max(x)
                  xmm = [x_min, x_max]
                  ymm = slope[0] * xmm + intercept
                  oplot, xmm, ymm, psym=0, color=125
                  annot = string('sensor: ', sensor, $
                                 '  slope: ', slope[0], $
                                 '  intercept: ', intercept, $
                                 format='(a,i2,a,f7.4,a,f)')
                  xyouts, .12, .92, annot, charsize=1.0, /normal
                  print, annot
              endif
              swath[*, sensor - 1, *] = slope[0] * x + intercept
          endif
      endfor
  endif

  ;  undo soze normalization if required

  if (file_soze ne '') and (undo_soze ne 0) then begin
      swath = temporary(swath) / soze
      soze = 0
  endif

  ;  put the swath back into original data type

  if data_type ne 'f4' then begin
      i = where(swath lt min_out, count)
      if count gt 0 then $
        swath[i] = min_out
      i = where(swath gt max_out, count)
      if count gt 0 then $
        swath[i] = max_out
      swath = fix(round(temporary(swath)), type=type_code)
  endif

  ;  open, write, and close output file

  openw, lun, file_out, /get_lun
  writeu, lun, swath
  free_lun, lun

END ; modis_adjust
