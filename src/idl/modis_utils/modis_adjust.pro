;*========================================================================
;* modis_adjust.pro - adjust modis data based on solar zenith and/or
;*                    regressions
;*
;* 15-Apr-2002  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/ms2gth/src/idl/modis_utils/modis_adjust.pro,v 1.3 2002/04/17 00:34:20 haran Exp haran $
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
;               [, y_tolerance=y_tolerance]
;               [, slope_delta_max=slope_delta_max]
;               [, regression_max=regression_max]
;               [, density_bin_width=density_bin_width]
;               [, plot_tag=plot_tag]
;               [, plot_max=plot_max]
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
;       y_tolerance: the value to use after the first linear regression
;           has been performed to find "outliers" that will be eliminated
;           from the second linear regression. That is, after k and m have
;           been determined from the first linear regression, the values
;           y'(i) = k + m * x(i) are calculated. Then outliers are defined
;           to be all points x(i) for which abs(y'(i) - y(i)) >= y_tolerance.
;           Then a second regression is performed on the remaining x(i) after
;           the outliers have been removed to determine the final k and m
;           values. The default value of y_tolerance is 0.0.
;           NOTE: If y_tolerance is 0.0, then no second linear regression
;                 is performed.
;       slope_delta_max: the outlier detection procedure described for
;           y_tolerance is repeated until slope_delta =
;           abs(slope - slope_old) / slope_old is less than or equal to
;           slope_delta_max. The default value of slope_delta_max is 0.001.
;           NOTE: If slope_delta_max is 0.0, then no third linear regression
;                 or higher is performed.
;       regression_max: the outlier detection procedure is repeated a maximum
;           of regression max total number of regressions.
;           The default value of regression_max is 10.
;       density_bin_width: the bin width used to create a weight map based on
;           the density of the scatterplot. If density_bin_width is 0 (default)
;           then all weights are set to 1 for the regressions.
;       plot_tag: string used to name and label regression plot files. Plot
;         files will be labelled plot_tag_xx.ps where xx is a 1-based sensor
;         sensor index. No plot will be generated for regress_sensor. The
;         default value of plot_tag is a null string indicating that no plots
;         should be created. If regress_sensor is 0, then plot_tag is ignored.
;       plot_max: maximum values to plot. Default is 0 meaning use the maximum
;         values in the data. if plot_tag is a null string, then plot_max is
;         ignored.
;
; EXAMPLE:
;         modis_adjust, 5416, 47, $
;                       'inst20020204_ref_ch01_5416_01880.img', $
;                       'inst20020204_ref_ch01_5416_01880_adj.img', $
;                       file_soze='instref20020204_soze_scaa_05416_00047_00000_40.img', $
;                       y_tolerance=0.1, density_bin_width=0.01, $
;                       plot_tag='inst20020204_ref_ch01', plot_max=1.5
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
                  y_tolerance=y_tolerance, $
                  slope_delta_max=slope_delta_max, $
                  regression_max=regression_max, $
                  density_bin_width=density_bin_width, $
                  plot_tag=plot_tag, $
                  plot_max=plot_max

  epsilon = 1e-6

  lf = string(10B)

  usage = lf + 'usage: modis_adjust, ' + lf + $
                'cols, scans, file_in, file_out, ' + lf + $
                '[, rows_per_scan=rows_per_scan] ' + lf + $
                '[, data_type=data_type] ' +   lf + $
                '[, regress_sensor=regress_sensor] ' + lf + $
                '[, file_soze=file_soze] ' + lf + $
                '[, /undo_soze] ' + lf + $
                '[, y_tolerance=y_tolerance] ' + lf + $
                '[, slope_delta_max=slope_delta_max] ' + lf + $
                '[, regression_max=regression_max] ' + lf + $
                '[, density_bin_width=density_bin_width] ' + lf + $
                '[, plot_tag=plot_tag] ' + lf + $
                '[, plot_max=plot_max]'

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
  if n_elements(y_tolerance) eq 0 then $
    y_tolerance = 0.0
  if n_elements(slope_delta_max) eq 0 then $
    slope_delta_max = 0.001
  if n_elements(regression_max) eq 0 then $
    regression_max = 10
  if n_elements(density_bin_width) eq 0 then $
    density_bin_width = 0
  if n_elements(plot_tag) eq 0 then $
    plot_tag = ''
  if n_elements(plot_max) eq 0 then $
    plot_max = 0

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
  print, '  y_tolerance:      ', y_tolerance
  print, '  slope_delta_max:  ', slope_delta_max
  print, '  regression_max:   ', regression_max
  print, '  density_bin_width:', density_bin_width
  print, '  plot_tag:         ', plot_tag
  print, '  plot_max:         ', plot_max

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
      i = 0

      ;  multiply swath data by 1/cos(soze)

      swath = temporary(swath) * soze
  endif

  if regress_sensor gt 0 then begin

      ;  perform regression

      n = long(cols) * scans

      ;  y is all the data for the regress_sensor

      y = reform(swath[*, regress_sensor - 1, *], n)

      ;  if using weights, then compute y density parameters

      if density_bin_width gt 0 then begin
          y_max = max(y, min=y_min)
          y_bin_count = floor((y_max - y_min) / density_bin_width) + 1L
          y_factor = y_bin_count / (y_max - y_min)
      endif

      ;  process one sensor at a time

      for sensor = 1, rows_per_scan do begin
          if sensor ne regress_sensor then begin

              ;  x is all the data for the sensor

              x = reform(swath[*, sensor - 1, *], 1, n)
              slope = 0.0
              intercept = 0.0
              status = 0L

              ;  if using weights, then compute x density parameters

              if density_bin_width gt 0 then begin
                  x_max = max(x, min=x_min)
                  x_bin_count = floor((x_max - x_min) / density_bin_width) + 1L
                  x_factor = x_bin_count / (x_max - x_min)
                  h = long((x - x_min) * x_factor) * y_bin_count + $
                      long((y - y_min) * y_factor)
                  h = histogram(h, reverse_indices=r)
                  weight = fltarr(n)
                  for i = 0L, n_elements(h) - 1 do begin
                      if (r[i] ne r[i+1]) then begin
                          weight[r[r[i] : r[i+1] - 1]] = h[i]
                      endif
                  endfor
                  h = 0
                  r = 0
                  i = where(weight lt epsilon, count)
                  if count gt 0 then $
                    weight[i] = epsilon
                  i = 0
                  weight = 1.0 / temporary(weight)
                  slope = regress(x, y, const=intercept, status=status, $
                                  measure_errors=weight)
              endif else begin
                  slope = regress(x, y, const=intercept, status=status)
              endelse
              regression_count = 1
              annot = string('sensor: ', sensor, $
                             '  regress: ', regression_count, $
                             '  status: ', status, $
                             '  intercept: ', intercept, $
                             '  slope: ', slope[0], $
                             format='(a,i2,a,i3,a,i2,a,e12.5,a,f8.5)')
              print, annot
              if (status eq 0) and (y_tolerance gt 0) then begin

                  ; compare original y values to computed y values and
                  ; select only those within y_tolerance

                  ; keep iterating until the change in slope is less than
                  ; slope_delta_max or until the number of iterations exceeds
                  ; regression_max

                  repeat begin
                      slope_old = slope[0]
                      i = where(abs(y - (slope[0] * x + intercept)) lt $
                                y_tolerance, n2)
                      if n2 eq 0 then begin
                          slope = 0.0
                          intercept = 0.0
                          regression_count = regression_max
                      endif else begin
                          x2 = reform(x[i], 1, n2)
                          y2 = y[i]
                          status = 0L
                          slope = 0.0
                          intercept = 0.0
                          if density_bin_width gt 0 then begin
                              weight2 = weight[i]
                              slope = regress(x2, y2, const=intercept, $
                                              status=status, $
                                              measure_errors=weight2)
                          endif else begin
                              slope = regress(x2, y2, const=intercept, $
                                              status=status)
                          endelse
                          i = 0
                          if (status ne 0) then begin
                              regression_count = regression_max
                          endif
                      endelse
                      regression_count = regression_count + 1
                      if abs(slope_old) gt epsilon then $
                        slope_delta = abs(slope[0] - slope_old) / slope_old $
                      else $
                        slope_delta = 0.0
                      annot = string('sensor: ', sensor, $
                                     '  regress: ', regression_count, $
                                     '  status: ', status, $
                                     '  intercept: ', intercept, $
                                     '  slope: ', slope[0], $
                                     '  slope_delta: ', slope_delta, $
                                     format='(a,i2,a,i3,a,i2,a,e12.5,2(a,f8.5))')
                      print, annot
                  endrep until ((slope_delta_max eq 0) or $
                                (slope_delta le slope_delta_max) or $
                                (regression_count ge regression_max))
                  x2 = 0
                  y2 = 0
              endif  ; if (status eq 0) and (y_tolerance gt 0)
              weight = 0

              if plot_tag ne '' then begin

                  ;  create the scatter plot for this sensor

                  file_plot = string(plot_tag + '_', sensor, '.ps', $
                                     format='(a, i2.2, a)')
                  mydev = !D.NAME
                  set_plot, 'ps'
                  
                  device, filename=file_plot, /landscape, /color, $
                    bits_per_pixel=8
                  device, xsize=10.0, ysize=7.5, /inches
                  x_min = 0
                  if plot_max eq 0 then $
                    plot_max = max(x)
                  plot, x, y, psym=3, xstyle=1, ystyle=1, charsize=1.0, $
                    xrange=[x_min, plot_max], yrange=[x_min, plot_max], $
                    title=plot_file, $
                    xtitle=string('sensor: ', sensor, $
                                  format='(a, i2.2)'), $
                    ytitle=string('sensor: ', regress_sensor, $
                                  format='(a, i2.2)')
                  xmm = [x_min, plot_max]
                  ymm = slope[0] * xmm + intercept
                  oplot, xmm, ymm, psym=0, color=125
                  if y_tolerance gt 0 then begin
                      ymm = slope[0] * xmm + intercept + y_tolerance
                      oplot, xmm, ymm, psym=0, color=125
                      ymm = slope[0] * xmm + intercept - y_tolerance
                      oplot, xmm, ymm, psym=0, color=125
                  endif
                  xyouts, .12, .92, annot, charsize=1.0, /normal
                  annot = string('y_tolerance: ', y_tolerance)
                  xyouts, .12, .89, annot, charsize=1.0, /normal
                  annot = string('regression count: ', regression_count)
                  xyouts, .12, .86, annot, charsize=1.0, /normal
              endif
              swath[*, sensor - 1, *] = slope[0] * x + intercept
          endif ; if sensor ne regress_sensor
      endfor ; for sensor = 1, rows_per_scan
  endif ; if regress_sensor eq 0

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
