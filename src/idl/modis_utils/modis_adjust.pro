;*========================================================================
;* modis_adjust.pro - adjust modis data based on solar zenith and/or
;*                    regressions
;*
;* 15-Apr-2002  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /hosts/icemaker/temp/tharan/inst/modis_adjust.pro,v 1.10 2002/11/24 21:43:55 haran Exp haran $
;*========================================================================*/

;+
; NAME:
;	modis_adjust
;
; PURPOSE:
;       1) Optionally modify modis data with a solar zenith correction.
;       2) Optionally compute a regression for every reg_col_stride column
;          relative to the mean of the preceding and following columns
;          for a particular set of detectors at a given column offset.
;       3) Optionally compute a regression for each pair of detectors
;          relative to their mean, then regress each pair of means
;          against its mean, and so on until only one mean is left,
;          and then adjust the data accordingly.
;       4) Optionally undo the solar zenith correction.
;
; CATEGORY:
;	Modis.
;
; CALLING SEQUENCE:
;       MODIS_ADJUST, cols, scans, file_in, file_out,
;               [, rows_per_scan=rows_per_scan]
;               [, data_type=data_type]
;               [, file_soze=file_soze]
;               [, /undo_soze]
;               [, reg_col_detectors=reg_col_detectors]
;               [, reg_col_stride=reg_col_stride]
;               [, reg_col_offset=reg_col_offset]
;               [, /reg_rows]
;               [, col_y_tolerance=col_y_tolerance]
;               [, col_slope_delta_max=col_slope_delta_max]
;               [, col_regression_max=col_regression_max]
;               [, col_density_bin_width=col_density_bin_width]
;               [, col_plot_tag=col_plot_tag]
;               [, col_plot_max=col_plot_max]
;               [, row_y_tolerance=row_y_tolerance]
;               [, row_slope_delta_max=row_slope_delta_max]
;               [, row_regression_max=row_regression_max]
;               [, row_density_bin_width=row_density_bin_width]
;               [, row_plot_tag=row_plot_tag]
;               [, row_plot_max=row_plot_max]
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
;       rows_per_scan: number of rows in each scan in file_in. Valid
;         values are limited to 40 (the default), 20, or 10.
;       data_type: 2-character string specifying the data type of the data
;         if file in to be adjusted:
;           u1: unsigned 8-bit integer.
;           u2: unsigned 16-bit integer.
;           s2: signed 16-bit integer.
;           u4: unsigned 32-bit integer.
;           s4: signed 32-bit integer.
;           f4: 32-bit floating-point (default).
;       file_soze: file containing solar zenith values in 32-bit floating-point
;         degrees. Should have the same number of cols and scans as file_in.
;         Each input value is divided by the cosine of the corresponding
;         solar zenith value before any regressions are performed. The default
;         value of file_soze is a null string indicating that no solar zenith
;         file should be read.
;       undo_soze: If set then each input value is multiplied by the cosine
;         of the corresponding solar zenith value after regressions are
;         performed. If file_soze is a null string, then undo_soze is
;         ignored.
;       reg_col_detectors: Array of zero-based detector numbers to use for
;         column regressions. If reg_col_detectors is -1 or is not
;         specified, then no column regressions are performed.
;       reg_col_stride: the stride value to use for performing column
;         regressions. The default value of reg_col_stride is 4.
;       reg_col_offset: the offset value to use for performing column
;         regressions. The default value of reg_col_offset is 0.
;       reg_rows: If set then row regressions are computed.
;       NOTE: The keywords below are preceded by either col_ or row_
;         indicating to which set of regressions they refer.
;       y_tolerance: the value to use after the first linear regression
;         has been performed to find "outliers" that will be eliminated
;         from the second linear regression. That is, after k and m have
;         been determined from the first linear regression, the values
;         y'(i) = k + m * x(i) are calculated. Then outliers are defined
;         to be all points x(i) for which abs(y'(i) - y(i)) >= y_tolerance.
;         Then a second regression is performed on the remaining x(i) after
;         the outliers have been removed to determine the final k and m
;         values. The default value of y_tolerance is 0.0.
;         NOTE: If y_tolerance is 0.0, then no second linear regression
;               is performed.
;       slope_delta_max: the outlier detection procedure described for
;         y_tolerance is repeated until slope_delta =
;         abs(slope - slope_old) / slope_old is less than or equal to
;         slope_delta_max. The default value of slope_delta_max is 0.001.
;         NOTE: If slope_delta_max is 0.0, then no third linear regression
;               or higher is performed.
;       regression_max: the outlier detection procedure is repeated a maximum
;         of regression max total number of regressions.
;         The default value of regression_max is 10.
;       density_bin_width: the bin width used to create a weight map based on
;         the density of the scatterplot. If density_bin_width is 0 (default)
;         then all weights are set to 1 for the regressions.
;       plot_tag: string used to name and label regression plot files.
;         Row plot files will be labelled row_plot_tag_p_rr.ps where p is a
;         zero-based pass index and rr is a zero-based regression index
;         within the pass.
;         The default value of plot_tag is a null string indicating
;         that no plots should be created.
;       plot_max: maximum values to plot. Default is 0 meaning use the maximum
;         values in the data. if plot_tag is a null string, then plot_max is
;         ignored.
;
; EXAMPLE:
;       modis_adjust, $
;         5416, 51, $
;         'modis_inst_2001341_ref_ch01_5416_02040.img', $
;         'modis_inst_2001341_ref_ch01_5416_02040_nor.img', $
;         file_soze='modis_inst_2001341_soze_scaa_05416_00051_00000_40.img'
;
;       modis_adjust, $
;         5416, 51, $
;         'modis_inst_2001341_ref_ch01_5416_02040_nor.img', $
;         'modis_inst_2001341_ref_ch01_5416_02040_adj.img', $
;         reg_col_detectors=[28,29], $
;         reg_col_offset=3, $
;         /reg_rows, $
;         col_y_tolerance=0.1, $
;         col_density_bin_width=0.01, $
;         col_plot_tag='modis_inst_2001341_ch01_col', $
;         col_plot_max=1.5, $
;         row_y_tolerance=0.1, $
;         row_density_bin_width=0.01, $
;         row_plot_tag='modis_inst_2001341_ch01_row', $
;         row_plot_max=1.5
;
;       modis_adjust, $
;         5416, 51, $
;         'modis_inst_2001341_ref_ch02_5416_02040.img', $
;         'modis_inst_2001341_ref_ch02_5416_02040_nor.img', $
;         file_soze='modis_inst_2001341_soze_scaa_05416_00051_00000_40.img', $
;         reg_col_detectors=0
;
;       modis_adjust, $
;         5416, 51, $
;         'modis_inst_2001341_ref_ch02_5416_02040_nor.img', $
;         'modis_inst_2001341_ref_ch02_5416_02040_adj.img', $
;         reg_col_detectors=[28,29], $
;         reg_col_offset=0, $
;         /reg_rows, $
;         col_y_tolerance=0.1, $
;         col_density_bin_width=0.01, $
;         col_plot_tag='modis_inst_2001341_ch02_col', $
;         col_plot_max=1.5, $
;         row_y_tolerance=0.1, $
;         row_density_bin_width=0.01, $
;         row_plot_tag='modis_inst_2001341_ch02_row', $
;         row_plot_max=1.5
;
; ALGORITHM:
;
; REFERENCE:
;-

Pro modis_adjust, cols, scans, file_in, file_out, $
                  rows_per_scan=rows_per_scan, $
                  data_type=data_type, $
                  file_soze=file_soze, $
                  undo_soze=undo_soze, $
                  reg_col_detectors=reg_col_detectors, $
                  reg_col_stride=reg_col_stride, $
                  reg_col_offset=reg_col_offset, $
                  reg_rows=reg_rows, $
                  col_y_tolerance=col_y_tolerance, $
                  col_slope_delta_max=col_slope_delta_max, $
                  col_regression_max=col_regression_max, $
                  col_density_bin_width=col_density_bin_width, $
                  col_plot_tag=col_plot_tag, $
                  col_plot_max=col_plot_max, $
                  row_y_tolerance=row_y_tolerance, $
                  row_slope_delta_max=row_slope_delta_max, $
                  row_regression_max=row_regression_max, $
                  row_density_bin_width=row_density_bin_width, $
                  row_plot_tag=row_plot_tag, $
                  row_plot_max=row_plot_max

  epsilon = 1e-6

  lf = string(10B)

  usage = lf + 'usage: modis_adjust, ' + lf + $
                'cols, scans, file_in, file_out, ' + lf + $
                '[, rows_per_scan=rows_per_scan] ' + lf + $
                '[, data_type=data_type] ' +   lf + $
                '[, file_soze=file_soze] ' + lf + $
                '[, /undo_soze] ' + lf + $
                '[, reg_col_detectors=reg_col_detectors] ' + lf + $
                '[, reg_col_stride=reg_col_stride] ' + lf + $
                '[, reg_col_offset=reg_col_offset] ' + lf + $
                '[, /reg_rows] ' + lf + $
                '[, col_y_tolerance=col_y_tolerance] ' + lf + $
                '[, col_slope_delta_max=col_slope_delta_max] ' + lf + $
                '[, col_regression_max=col_regression_max] ' + lf + $
                '[, col_density_bin_width=col_density_bin_width] ' + lf + $
                '[, col_plot_tag=col_plot_tag] ' + lf + $
                '[, col_plot_max=col_plot_max] ' + lf + $
                '[, row_y_tolerance=row_y_tolerance] ' + lf + $
                '[, row_slope_delta_max=row_slope_delta_max] ' + lf + $
                '[, row_regression_max=row_regression_max] ' + lf + $
                '[, row_density_bin_width=row_density_bin_width] ' + lf + $
                '[, row_plot_tag=row_plot_tag] ' + lf + $
                '[, row_plot_max=row_plot_max]'

  if n_params() ne 4 then $
    message, usage

  if n_elements(rows_per_scan) eq 0 then $
    rows_per_scan = 40
  if n_elements(data_type) eq 0 then $
    data_type = 'f4'
  if n_elements(file_soze) eq 0 then $
    file_soze = ''
  if n_elements(undo_soze) eq 0 then $
    undo_soze = 0
  if n_elements(reg_col_detectors) eq 0 then $
    reg_col_detectors = -1
  if n_elements(reg_col_stride) eq 0 then $
    reg_col_stride = 4
  if n_elements(reg_col_offset) eq 0 then $
    reg_col_offset = 0
  if n_elements(reg_rows) eq 0 then $
    reg_rows = 0
  if n_elements(col_y_tolerance) eq 0 then $
    col_y_tolerance = 0.0
  if n_elements(col_slope_delta_max) eq 0 then $
    col_slope_delta_max = 0.001
  if n_elements(col_regression_max) eq 0 then $
    col_regression_max = 10
  if n_elements(col_density_bin_width) eq 0 then $
    col_density_bin_width = 0
  if n_elements(col_plot_tag) eq 0 then $
    col_plot_tag = ''
  if n_elements(col_plot_max) eq 0 then $
    col_plot_max = 0
  if n_elements(row_y_tolerance) eq 0 then $
    row_y_tolerance = 0.0
  if n_elements(row_slope_delta_max) eq 0 then $
    row_slope_delta_max = 0.001
  if n_elements(row_regression_max) eq 0 then $
    row_regression_max = 10
  if n_elements(row_density_bin_width) eq 0 then $
    row_density_bin_width = 0
  if n_elements(row_plot_tag) eq 0 then $
    row_plot_tag = ''
  if n_elements(row_plot_max) eq 0 then $
    row_plot_max = 0

  reg_col_detectors_count = n_elements(reg_col_detectors)

  print, 'modis_adjust: $Header$' 
  print, '  cols:                 ', cols
  print, '  scans:                ', scans
  print, '  file_in:              ', file_in
  print, '  file_out:             ', file_out
  print, '  rows_per_scan:        ', rows_per_scan
  print, '  data_type:            ', data_type
  print, '  file_soze:            ', file_soze
  print, '  undo_soze:            ', undo_soze
  for i = 0, reg_col_detectors_count - 1 do begin
      s = string(i, format='(i1)')
      print, '  reg_col_detectors[' + s + ']: ', reg_col_detectors[i]
  endfor
  print, '  reg_col_stride:       ', reg_col_stride
  print, '  reg_col_offset:       ', reg_col_offset
  print, '  reg_rows:             ', reg_rows
  print, '  col_y_tolerance:      ', col_y_tolerance
  print, '  col_slope_delta_max:  ', col_slope_delta_max
  print, '  col_regression_max:   ', col_regression_max
  print, '  col_density_bin_width:', col_density_bin_width
  print, '  col_plot_tag:         ', col_plot_tag
  print, '  col_plot_max:         ', col_plot_max
  print, '  row_y_tolerance:      ', row_y_tolerance
  print, '  row_slope_delta_max:  ', row_slope_delta_max
  print, '  row_regression_max:   ', row_regression_max
  print, '  row_density_bin_width:', row_density_bin_width
  print, '  row_plot_tag:         ', row_plot_tag
  print, '  row_plot_max:         ', row_plot_max

  ; check for valid input

  if (rows_per_scan ne 40) and $
     (rows_per_scan ne 20) and $
     (rows_per_scan ne 10) then $
    message, 'rows_per_scan must be 40, 20, or 10'

  for i = 0, reg_col_detectors_count - 1 do begin
      if reg_col_detectors[i] ge rows_per_scan then $
        message, 'Each element of reg_col_detector ' + $
                 'must be less than rows_per_scan' + $
                 usage
  endfor

  if scans lt 2 then $
    message, 'scans must be 2 or greater'

  if (rows_per_scan mod 2) ne 0 then $
    message, 'rows_per_scan must be even'

  rows = scans * rows_per_scan
  cells_per_scan = long(cols) * rows_per_scan
  cells_per_swath = cells_per_scan * scans

  ; allocate arrays

  case data_type of
      'u1': begin
          swath = bytarr(cells_per_swath)
          bytes_per_element = 1
          min_out = 0.0
          max_out = 255.0
      end
      'u2': begin
          swath = uintarr(cells_per_swath)
          bytes_per_element = 2
          min_out = 0.0
          max_out = 65535.0
      end
      's2': begin
          swath = intarr(cells_per_swath)
          bytes_per_element = 2
          min_out = -32768.0
          max_out = 32767.0
      end
      'u4': begin
          swath = ulonarr(cells_per_swath)
          bytes_per_element = 4
          min_out = 0.0
          max_out = 4294967295.0
      end
      's4': begin
          swath = lonarr(cells_per_swath)
          bytes_per_element = 4
          min_out = -2147483648.0
          max_out = 2147483647.0
      end
      'f4': begin
          swath = fltarr(cells_per_swath)
          bytes_per_element = 4
      end
      else: message, 'invalid data_type' + usage
  end
  type_code = size(swath, /type)

  if file_soze ne '' then $
    soze = fltarr(cells_per_swath)

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

  if reg_rows ne 0 then begin

      ;  perform row regressions

      ;  compute the number of double-sided scans,
      ;  and the number of rows per double-sided scan

      ds_scans = scans / 2
      rows_per_ds_scan = 2 * rows_per_scan

      ;  if scans is odd, then increment the number of double scans,
      ;  duplicate the penultimate scan, and concatenate it onto the end

      if (scans mod 2) eq 1 then begin
          ds_scans = ds_scans + 1
          ipen_first = cells_per_scan * (scans - 2)
          ipen_last = ipen_first + cells_per_scan - 1
          ipen = swath[ipen_first:ipen_last]
          swath = [temporary(swath), ipen]
          ipen = 0
      endif

      ;  calculate the number of cells for a double-sided detector

      cells_per_ds_det = long(cols) * ds_scans

      ; reform swath so that it holds double-sided scans

      swath = reform(swath, cols, rows_per_ds_scan, ds_scans, /overwrite)

      case rows_per_scan of
          40: pass_count = 6
          20: pass_count = 5
          10: pass_count = 4
      endcase
      mean_count = rows_per_ds_scan
      for pass_ctr = 0, pass_count - 1 do begin
          mean_count = mean_count / 2
          if (mean_count mod 2) eq 1 then $
            mean_count = mean_count - 1
          vectors_per_mean = rows_per_ds_scan / mean_count
          ds_det = 0
          for mean_ctr = 0, mean_count - 1 do begin
              weight_per_vector = 1.0 / vectors_per_mean
              mean = 0
              vectors = fltarr(cells_per_ds_det, vectors_per_mean)
              for vec_ctr = 0, vectors_per_mean - 1 do begin
                  vector = reform(swath[*, ds_det + vec_ctr, *], $
                                       1, cells_per_ds_det)
                  mean = vector * weight_per_vector + mean
                  vectors[*, vec_ctr] = temporary(vector)
              endfor ; vec_ctr
              for vec_ctr = 0, vectors_per_mean - 1 do begin
                  vector = reform(vectors[*, vec_ctr])
                  plot_tag = row_plot_tag
                  if plot_tag ne '' then $
                    plot_tag = string(plot_tag + '_', pass_ctr, '_', ds_det, $
                                      format='(a, i1.1, a, i2.2)')
                  xtitle=string('pass_ctr: ', pass_ctr, $
                                '  mean_ctr: ', mean_ctr, $
                                format='(a, i1, a, i2.2)')
                  ytitle=string('ds_det: ', ds_det, $
                                format='(a, i2.2)')
                  modis_regress, mean, vector, $
                                 slope, intcp, $
                                 y_tolerance=row_y_tolerance, $
                                 slope_delta_max=row_slope_delta_max, $
                                 regression_max=row_regression_max, $
                                 density_bin_width=row_density_bin_width, $
                                 plot_tag=plot_tag, $
                                 plot_max=row_plot_max, $
                                 plot_titles=[xtitle,ytitle]
                  if abs(slope) ge epsilon then $
                    swath[*, ds_det, *] = (vector - intcp) / slope
                  ds_det = ds_det + 1
              endfor ; vec_ctr
              vectors = 0
              vector = 0
              mean = 0
          endfor ; mean_ctr
      endfor ; pass_ctr

      ; reform the swath array back into its original structure

      swath = reform(swath, cols, rows_per_scan, ds_scans * 2, /overwrite)

      ; remove bogus scan at end if necessary

      if (scans mod 2) eq 1 then $
        swath = temporary(swath[*, *, 0:scans - 1])

  endif  ; if reg_rows ne 0


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
