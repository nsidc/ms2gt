;*========================================================================
;* congridx.pro - expand a 2d array by extrapolation and interpolation
;*
;* 11-Jan-2001  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/congridx.pro,v 1.1 2001/01/11 15:34:55 haran Exp $
;*========================================================================*/

;+
; NAME:
;	congridx
;
; PURPOSE:
;       Expand a n x m array by extrapolation to a (n+2) x (m+2) array,
;       followed by interpolation to a (N/n)(n+2) x (M/m)(m+2) array,
;       followed by extraction of the final N x M array.
;
; CATEGORY:
;	Modis.
;
; CALLING SEQUENCE:
;       result = CONGRIDX(array, cols_out, rows_out,
;                         [, col_offset=col_offset]
;                         [, row_offset=row_offset]
;                         [, cubic=value{-1 to 0}]
;                         [, /interp]
;                         [, /minus_one])
;
; ARGUMENTS:
;    Inputs:
;       array: a 2-dimensional floating-point array to expand.
;       cols_out: number of columns in the expanded array.
;       rows_out: number of rows in the expanded array.
;    Outputs:
;       None.
;    Result:
;       An array consisting of cols_out columns and rows_out rows is returned.
;
; KEYWORDS:
;    col_offset: the column number in the final array which will contain
;       the values from column 0 in the original array. The default is 0.
;       col_offset must be less than cols_out / cols_in.
;    row_offset: the row number in the final array which will contain
;       the values from row 0 in the original array. The default is 0.
;       row_offset must be less than rows_out / rows_in.
;    cubic, /interp, and /minus_one if present are passed to congrid.
;
; EXAMPLE:
;      scan_of_cols_out = congridx(scan_of_cols, cols_out, rows_out, $
;                                  col_offset=col_offset, $
;                                  row_offset=row_offset, $
;                                  cubic=0.5)
;
; ALGORITHM:
;
; REFERENCE:
;-

Function congridx, array, cols_out, rows_out, $
                   col_offset=col_offset, row_offset=row_offset, $
                   
usage = 'usage: congridx, ' + $
                  'interp_factor, colsin, scansin, rowsperscanin, ' + $
                  'colfilein, rowfilein, tag' + $
                  '[, grid_check=[col_min, col_max, row_min, row_max]]' + $
                  '[, col_offset=col_offset]' + $
                  '[, row_offset=row_offset]'

  if n_params() ne 7 then $
    message, usage
  if n_elements(grid_check) ne 4 then $
    check_grid = 0 $
  else begin
      check_grid = 1
      col_min = grid_check[0]
      col_max = grid_check[1]
      row_min = grid_check[2]
      row_max = grid_check[3]
  endelse
    
  if n_elements(col_offset) eq 0 then $
    col_offset = 0
  if n_elements(row_offset) eq 0 then $
    row_offset = 0

  print, 'congridx:'
  print, '  interp_factor: ', interp_factor
  print, '  colsin:        ', colsin
  print, '  scansin:       ', scansin
  print, '  rowsperscanin: ', rowsperscanin
  print, '  colfilein:     ', colfilein
  print, '  rowfilein:     ', rowfilein
  print, '  tag:           ', tag
  print, '  grid_check:    ', grid_check
  print, '  col_offset:    ', col_offset
  print, '  row_offset:    ', row_offset

  ; allocate arrays

  scan_of_cols_in = fltarr(colsin, rowsperscanin)
  scan_of_rows_in = fltarr(colsin, rowsperscanin)

  ; open input files

  openr, col_lun_in, colfilein, /get_lun
  openr, row_lun_in, rowfilein, /get_lun

  ;  Create preliminary names of output files as if check_grid is FALSE.
  ;  If check_grid is FALSE, then these will be the final names.
  ;  If check_grid is TRUE, then we will rename the output files once
  ;  we're done and we know the final values of scansout and scanfirst.

  scansout = scansin
  scanfirst = 0
  rowsperscanout = rowsperscanin * interp_factor
  colsout = colsin * interp_factor
  rowsout = rowsin * interp_factor

  suffix = string(colsin, format='(I5.5)') + '_' + $
           string(scansout, format='(I5.5)') + '_' + $
           string(scanfirst, format='(I5.5)') + '_' + $
           string(rowsperscanout, format='(I2.2)') + '.img'
  colfileout = tag + '_cols_' + suffix
  rowfileout = tag + '_rows_' + suffix

  ;  Open output files

  openw, col_lun_out, colfileout, /get_lun
  openw, row_lun_out, rowfileout, /get_lun

  ;  set scanfirst to -1 to indicate we haven't found a point within
  ;  the grid yet.

  if check_grid eq 1 then begin
      scanfirst = -1
      scanlast  = -1
  endif
  for scan = 0, scansin - 1 do begin

      ;  read in a scan's worth of data

      readu, col_lun_in, scan_of_cols_in
      readu, row_lun_in, scan_of_rows_in

      scan_of_cols_out = $
        congridx(scan_of_cols, cols_out, rows_out, $
                 col_offset=col_offset, row_offset=row_offset, $
                 cubic=0.5)
      scan_of_rows_out = $
        congridx(scan_of_rows, cols_out, rows_out, $
                 col_offset=col_offset, row_offset=row_offset, $
                 cubic=0.5)

      if check_grid eq 1 then begin
          this_col_min = min(scan_of_cols_out, max=this_col_max)
          this_row_min = min(scan_of_rows_out, max=this_row_max)
          if (this_col_min ge col_min) and (this_col_max le col_max) and $
             (this_row_min ge row_min) and (this_row_max le row_max) then begin
              scanlast = scan
              if scanfirst lt 0 then $
                scanfirst = scan
          endif
      endif else begin
          scanlast = scan
      endelse

      if (check_grid eq 1) and (scanfirst ge 0) and (scanlast ne scan) then $
        goto, DONE
      if scanfirst ge 0 then begin

          ;  write out a scan's worth of data

          writeu, col_lun_out, scan_of_cols_out
          writeu, row_lun_out, scan_of_rows_out
      endif

  endfor

  DONE:

  ; close files

  free_lun, col_lun_in
  free_lun, row_lun_in
  free_lun, col_lun_out
  free_lun, row_lun_out

  ;  rename the output files if check grid is true

  if check_grid eq 1 then begin
      scansout = scanlast - scanfirst + 1
      suffix = string(colsin, format='(I5.5)') + '_' + $
               string(scansout, format='(I5.5)') + '_' + $
               string(scanfirst, format='(I5.5)') + '_' + $
               string(rowsperscanout, format='(I2.2)') + '.img'
      colfileout_new = tag + '_cols_' + suffix
      rowfileout_new = tag + '_rows_' + suffix
      spawn, 'mv ' + colfileout + ' ' + colfileout_new, /sh
      spawn, 'mv ' + rowfileout + ' ' + rowfileout_new, /sh
  endif

END ; congridx
