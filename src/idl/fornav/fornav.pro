;*========================================================================
;* fornav.pro - forward navigate a swath image to a projected image
;*
;* 23-Oct-2000  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/fornav/fornav.pro,v 1.3 2000/10/25 23:58:29 haran Exp haran $
;*========================================================================*/

;+
; NAME:
;	fornav
;
; PURPOSE:
;       For each pixel in a swath image, distribute the pixel among one or
;       pixels in a projected image.
;
; CATEGORY:
;	Modis.
;
; CALLING SEQUENCE:
;       FORNAV, swath_cols, swath_scans, swath_rows_per_scan,
;               swath_col_file, swath_row_file, swath_chan_files,
;               grid_cols, grid_rows,
;               grid_chan_files
;               [, dirin=dirin]
;               [, dirout=dirout]
;               [, swath_scan_first=swath_scan_first]
;               [, grid_col_start=grid_col_start]
;               [, grid_row_start=grid_row_start]
;               [, weight_count=weight_count]
;               [, weight_min=weight_min]
;               [, weight_factor=weight_factor]
;               [, weight_sum_min=weight_sum_min]
;               [, bytes_per_cell=bytes_per_cell]
;               [, fill=fill]
;
; ARGUMENTS:
;    Inputs:
;       swath_cols: number of columns in each swath file.
;       swath_scans: number of scans in each swath file.
;       swath_rows_per_scan: number of swath rows constituting a scan
;       swath_col_file: file containing the projected column number of each
;         swath cell and consisting of swatch_cols x swath_rows of 4 byte
;         floating-point numbers. 
;       swath_row_file: file containing the projected row number of each
;         swath cell and consisting of swatch_cols x swath_rows of 4 byte
;         floating-point numbers. 
;       swath_chan_files: string array of 1 or more swath channel filenames.
;         Each file consists of swath_cols x swath_rows of 2 byte signed
;         integers (unless bytes_per_cell is equal to 1).
;       grid_cols: number of columns in each grid file.
;       grid_rows: number of rows in each grid file.
;    Outputs:
;       grid_chan_files: string array of 1 or more grid channel filenames.
;         Each file consists of grid_cols x grid_rows of 2 byte signed
;         integers. There must be the same number of elements in
;         grid_chan_files as in swath_chan_files.
;
; KEYWORDS:
;       dirin: directory containing input files. Default is ''.
;       dirout: directory containing output files. Default is ''.
;       swath_scan_first: the first scan number to process. Default is 0.
;       grid_col_start: starting grid column to output. Default is 0. 
;       grid_row_start: starting grid row to output. Default is 0. 
;       weight_count: number of elements to create in the gaussian weight
;         table. Default is 10000.
;       weight_min: the minimum value to store in the last position of the
;         weight table. Default is 0.01, which, with a weight factor of 1.0,
;         produces a weight of 0.01 at a distance of 2.14597.
;       weight_factor: scale factor to use in converting distance to weight.
;         Doubling the weight_factor doubles the distance at which the
;         minimum weight is reached. Default is 1.0.
;       weight_sum_min: minimum weight sum value. Pixels whose weight sums
;         are less than weight_sum_min are set to the fill value.
;         Default is 0.001.
;       bytes_per_cell: the number of bytes per input swath cell. The
;         default is 2, indicating signed integers. The only other valid
;         value is 1, indicating byte data. If bytes_per_cell is equal to 1,
;         then weighting is used only for detecting missing data; final cell
;         values are simply a reflection of the most recently assigned value
;         given to each cell.
;       fill: fill value for missing channel data. If a scalar is provided,
;         the value is used for all channel files. If an array is provided,
;         it must have the same number of elements as swath_chan_files.
;         If bytes_per_cell equals 1, then default value of fill is -1;
;         otherwise it is 0.
;
; EXAMPLE:
;         fornav, 1354, 203, 10, $
;                 'col.1354.2030.img', 'row.1354.2030.img', $
;                 'ch1.1354.2030.int2', $
;                 560, 400, $
;                 'ch1.560.400.int2', $
;                 dirin='/export/data/modis/data/', $
;                 dirout='/export/data/modis/data/'
;
; ALGORITHM:
;
; REFERENCE:
;-

PRO fornav, swath_cols, swath_scans, swath_rows_per_scan, $
            swath_col_file, swath_row_file, swath_chan_files, $
            grid_cols, grid_rows, $
            grid_chan_files, $
            dirin=dirin, $
            dirout=dirout, $
            swath_scan_first=swath_scan_first, $
            grid_col_start=grid_col_start, $
            grid_row_start=grid_row_start, $
            weight_count=weight_count, $
            weight_min=weight_min, $
            weight_factor=weight_factor, $
            weight_sum_min=weight_sum_min, $
            bytes_per_cell=bytes_per_cell, $
            fill=fill

  usage = 'usage: fornav, swath_cols, swath_scans, swath_rows_per_scan, ' + $
          'swath_col_file, swath_row_file, swath_chan_files, ' + $
          'grid_cols, grid_rows, ' + $
          'grid_chan_files' + $
          '[, dirin=dirin] ' + $
          '[, dirout=dirout] ' + $
          '[, swath_scan_first=swath_scan_first], ' + $
          '[, grid_col_start=grid_col_start] ' + $
          '[, grid_row_start=grid_row_start] ' + $
          '[, weight_count=weight_count] ' + $
          '[, weight_min=weight_min] ' + $
          '[, weight_factor=weight_factor] ' + $
          '[, weight_sum_min=weight_sum_min] ' + $
          '[, bytes_per_cell=bytes_per_cell] ' + $
          '[, fill=fill]'

  if n_params() ne 9 then $
    message, usage
  if n_elements(dirin) eq 0 then $
    dirin = ''
  if n_elements(dirout) eq 0 then $
    dirout = ''
  if n_elements(swath_scan_first) eq 0 then $
    swath_scan_first = 0
  if n_elements(grid_col_start) eq 0 then $
    grid_col_start = 0
  if n_elements(grid_row_start) eq 0 then $
    grid_row_start = 0
  if n_elements(weight_count) eq 0 then $
    weight_count = 10000L
  if n_elements(weight_min) eq 0 then $
    weight_min = 0.01
  if n_elements(weight_factor) eq 0 then $
    weight_factor = 1.0
  if n_elements(weight_sum_min) eq 0 then $
    weight_sum_min = 0.001
  if n_elements(bytes_per_cell) eq 0 then $
    bytes_per_cell = 2
  if n_elements(fill) eq 0 then begin
      if bytes_per_cell eq 2 then $
        fill = -1 $
      else $
        fill = 0B
  endif

  print, 'fornav:'
  print, '  swath_cols:          ', swath_cols
  print, '  swath_scans:         ', swath_scans
  print, '  swath_rows_per_scan: ', swath_rows_per_scan
  print, '  swath_col_file:      ', swath_col_file
  print, '  swath_row_file:      ', swath_row_file
  print, '  swath_chan_files:    ', swath_chan_files
  print, '  dirin:               ', dirin
  print, '  dirout:              ', dirout
  print, '  swath_scan_first:    ', swath_scan_first
  print, '  grid_cols:           ', grid_cols
  print, '  grid_rows:           ', grid_rows
  print, '  grid_chan_files:     ', grid_chan_files
  print, '  grid_col_start:      ', grid_col_start
  print, '  grid_row_start:      ', grid_row_start
  print, '  weight_count:        ', weight_count
  print, '  weight_min:          ', weight_min
  print, '  weight_factor:       ', weight_factor
  print, '  weight_sum_min:      ', weight_sum_min
  print, '  bytes_per_cell:      ', bytes_per_cell
  print, '  fill:                ', fill

  chan_count = n_elements(swath_chan_files)
  if chan_count ne n_elements(grid_chan_files) then begin
      message, 'swath_chan_files and grid_chan_files must have the same ' + $
               'number of elements', /informational
      message, usage
  endif

  if n_elements(fill) eq 1 then begin
      fill_val = fill
      if bytes_per_cell eq 2 then $
        fill = intarr(chan_count) $
      else $
        fill = bytarr(chan_count)
      fill[*] = fill_val
  endif
  if chan_count ne n_elements(fill) then begin
      message, 'swath_chan_files and fill must have the same ' + $
               'number of elements', /informational
      message, usage
  endif

  ; allocate arrays

  swath_col = fltarr(swath_cols, swath_rows_per_scan)
  swath_row = fltarr(swath_cols, swath_rows_per_scan)

  if bytes_per_cell eq 2 then begin
      swath_chan = intarr(swath_cols, swath_rows_per_scan, chan_count)
      grid_chan = fltarr(grid_cols, grid_rows, chan_count)
      grid_weight = fltarr(grid_cols, grid_rows)
  endif else begin
      swath_chan = bytarr(swath_cols, swath_rows_per_scan, chan_count)
      grid_chan = bytarr(grid_cols, grid_rows, chan_count)
      grid_weight = bytarr(grid_cols, grid_rows)
  endelse

  grid_col = intarr(grid_cols, grid_rows)
  for i = 0, grid_rows - 1 do $
    grid_col[*, i] = indgen(grid_cols)

  grid_row = intarr(grid_cols, grid_rows)
  for i = 0, grid_cols - 1 do $
    grid_row[i, *] = indgen(grid_rows)

  ; open input files

  openr, swath_col_lun, dirin + swath_col_file, /get_lun
  openr, swath_row_lun, dirin + swath_row_file, /get_lun

  swath_chan_lun = lonarr(chan_count)
  for i = 0, chan_count - 1 do begin
      openr, lun, dirin + swath_chan_files[i], /get_lun
      swath_chan_lun[i] = lun
  endfor

  ; create the gaussian weight table
  ; we will use distance squared to lookup elements in the weight table

  weight_factor_squared = weight_factor * weight_factor
  dist_squared_max = -weight_factor_squared * alog(weight_min)
  weight_element_max = weight_count - 1
  weight = exp(-findgen(weight_count) / (weight_element_max) * $
               dist_squared_max / weight_factor_squared)
  dist_max = sqrt(dist_squared_max)
  print, '  maximum distance: ', dist_max
  col_radius = dist_max
  row_radius = dist_max
  icol_radius = fix(col_radius) + 1
  irow_radius = fix(row_radius) + 1
  grid_col_max = grid_cols - 1
  grid_row_max = grid_rows - 1

  first_scan_with_data = -1
  last_scan_with_data = -1

  ; seek to first scan in each input file

  if swath_scan_first gt 0 then begin
      first_element = long(swath_scan_first) * swath_rows_per_scan * $
                      swath_cols
      point_lun, swath_col_lun, first_element * 4
      point_lun, swath_row_lun, first_element * 4
      for i = 0, chan_count - 1 do $
        point_lun, swath_chan_lun[i], first_element * 2
  endif

  for scan = 0, swath_scans - 1 do begin

      ;  read in a scan's worth of data

      if scan mod 10 eq 0 then $
        print, scan
      readu, swath_col_lun, swath_col
      readu, swath_row_lun, swath_row
      if bytes_per_cell eq 2 then $
        swath_chan_1 = intarr(swath_cols, swath_rows_per_scan) $
      else $
        swath_chan_1 = bytarr(swath_cols, swath_rows_per_scan)
      for i = 0, chan_count - 1 do begin
          readu, swath_chan_lun[i], swath_chan_1
          swath_chan[*,*,i] = swath_chan_1
      endfor
      swath_chan_1 = 0

      ;  offset the column and row numbers

      swath_col = swath_col - grid_col_start
      swath_row = swath_row - grid_row_start

      ;  for each row in scan

      for row_in_scan = 0, swath_rows_per_scan - 1 do begin
          
          ;  process each cell in a swath row separately

          for col = 0, swath_cols - 1 do begin
              this_swath_col = swath_col[col, row_in_scan]
              this_swath_row = swath_row[col, row_in_scan]

              if (scan eq 10) and (row_in_scan eq 5) and (col eq 1200) then $
                debug = 1 $
              else $
                debug = 0

              ;  if the projected cell falls out of our region of interest,
              ;  then skip it

              if (this_swath_col ge 0) and $
                (this_swath_col le grid_col_max) and $
                (this_swath_row ge 0) and $
                (this_swath_row le grid_row_max) then begin
                  
                  ;  this cell falls within our region of interest

                  if first_scan_with_data eq -1 then $
                    first_scan_with_data = scan
                  last_scan_with_data = scan
                  this_swath_chan = reform(swath_chan[col, row_in_scan, *])

                  ; determine the box over which this cell will be distributed

                  col_center = fix(this_swath_col + 0.5)
                  row_center = fix(this_swath_row + 0.5)
                  col_first = max([0, col_center - icol_radius])
                  row_first = max([0, row_center - icol_radius])
                  col_last = min([grid_col_max, col_center + icol_radius])
                  row_last = min([grid_row_max, row_center + icol_radius])

                  ; cutout the box from each grid

                  this_grid_chan = grid_chan[col_first:col_last, $
                                             row_first:row_last, *]
                  this_grid_weight = grid_weight[col_first:col_last, $
                                                 row_first:row_last]
                  this_grid_col = grid_col[col_first:col_last, $
                                           row_first:row_last]
                  this_grid_row = grid_row[col_first:col_last, $
                                           row_first:row_last]

                  ; compute the distance squared for each point in the box

                  dist_squared = (this_grid_col - this_swath_col) ^ 2 + $
                                 (this_grid_row - this_swath_row) ^ 2
                  i = where(dist_squared le dist_squared_max, count)

                  if debug then begin
                      help, col_center
                      help, row_center
                      help, col_first
                      help, row_first
                      help, col_last
                      help, row_last
                      help, this_grid_chan
                      print, this_grid_chan
                      help, this_grid_weight
                      print, this_grid_weight
                      help, this_grid_col
                      print, this_grid_col
                      help, this_grid_row
                      print, this_grid_row
                      help, dist_squared
                      print, dist_squared
                      help, i
                      print, i
                  endif

                  if count gt 0 then begin
                      if (bytes_per_cell eq 2) then begin
                          this_weight = weight[fix(dist_squared[i] / $
                                                   dist_squared_max * $
                                                   weight_element_max)]
                          for j = 0, chan_count - 1 do begin
                              chan = reform(this_grid_chan[*,*,j])
                              chan[i] = chan[i] + $
                                this_swath_chan[j] * this_weight
                              this_grid_chan[*,*,j] = chan
                          endfor
                          this_grid_weight[i] = $
                            this_grid_weight[i] + this_weight
                      endif else begin
                          for j = 0, chan_count - 1 do begin
                              chan = reform(this_grid_chan[*,*,j])
                              chan[i] = this_swath_chan[j]
                              this_grid_chan[*,*,j] = chan
                          endfor
                          this_grid_weight[i] = 1B
                      endelse
                  endif

                  ; put the cutouts back into the grids

                  grid_chan[col_first:col_last, $
                            row_first:row_last, *] = this_grid_chan
                  grid_weight[col_first:col_last, $
                              row_first:row_last] = this_grid_weight
              endif
          endfor
      endfor
  endfor

  ; close input files

  free_lun, swath_col_lun
  free_lun, swath_row_lun

  ; deallocate arrays we don't need

  swath_col = 0
  swath_row = 0
  swath_chan = 0
  weight = 0

  ; set grid values to fill value wherever we didn't get any data

  if bytes_per_cell eq 2 then begin
      i = where(grid_weight lt weight_sum_min, count)
      if count gt 0 then $
        grid_weight[i] = 1
  endif else begin
      i = where(grid_weight eq 0B, count)
  endelse

  ; open, write, and close output files

  for j = 0, chan_count - 1 do begin
      free_lun, swath_chan_lun[j]
      chan = reform(grid_chan[*,*,j])
      openw, lun, dirout + grid_chan_files[j], /get_lun
      if bytes_per_cell eq 2 then $
        chan = fix(chan / grid_weight + 0.5)
      if count gt 0 then $
        chan[i] = fill[j]
      writeu, lun, chan
      free_lun, lun
  endfor

  swath_scan_first = swath_scan_first + first_scan_with_data
  swath_scans = last_scan_with_data - first_scan_with_data + 1
  print, 'On next call to fornav, set:'
  print, '  swath_scan_first:    ', swath_scan_first
  print, '  swath_scans:         ', swath_scans

END ; fornav
