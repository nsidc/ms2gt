pro do3c, cols_in, rows_in, file_in, file_out, $
          shrink_factor=shrink_factor, min_in=min_in, max_in=max_in, $
          bytes_per_cell=bytes_per_cell, color_table=color_table, $
          histeq=histeq

!order = 1
if n_params() ne 4 then $
  message, "syntax: do3c, cols_in, rows_in, file_in, file_out, " + $
                         "shrink_factor=shrink_factor, " + $
                         "min_in=min_in, max_in=max_in, " + $
                         "bytes_per_cell=bytes_per_cell, " + $
                         "color_table=color_table"

if n_elements(shrink_factor) eq 0 then $
  shrink_factor = 1
if n_elements(bytes_per_cell) eq 0 then $
  bytes_per_cell = 2
if n_elements(color_table) eq 0 then $
  color_table = 0
if n_elements(histeq) eq 0 then $
  histeq = 0
rgb = bytarr(256, 3)
if color_table eq -1 then begin
    loadct, 0
    tvlct, rgb, /get
    black = 0               ; Sensor data missing
    magenta = 1             ; No decision
    dark_grey = 11          ; Darkness, terminator
    chocolate = 25          ; Land (no snow detected)
    blue = 37               ; Inland water
    olive_green = 39        ; Ocean
    sky_blue = 50           ; Cloud obscured
    dark_blue = 100         ; Snow-covered lake ice
    white = 200             ; Snow
    yellow = 253            ; Dead MODIS sensor detector
    grey = 254              ; Saturated MODIS sensor detector
    red = 255               ; Fill data (no data expected for pixel
    rgb[black,*]       = [  0,   0,   0]
    rgb[magenta,*]     = [255,   0, 255]
    rgb[dark_grey,*]   = [ 64,  64,  64]
    rgb[chocolate,*]   = [210, 105,  30]
    rgb[blue,*]        = [  0,   0, 255]
    rgb[olive_green,*] = [ 85, 107,  47]
    rgb[sky_blue,*]    = [135, 206, 235]
    rgb[dark_blue,*]   = [  0,   0, 139]
    rgb[white,*]       = [255, 255, 255]
    rgb[yellow,*]      = [255, 255,   0]
    rgb[grey,*]        = [128, 128, 128]
    rgb[red,*]         = [255,   0,   0]
    tvlct, rgb
endif else begin
    loadct, color_table
    tvlct, rgb, /get
endelse
cols_out = cols_in / shrink_factor
rows_out = rows_in / shrink_factor
if n_elements(file_in) eq 1 then begin
    if bytes_per_cell eq 2 then $
      img_in = intarr(cols_in, rows_in) $
    else $
      img_in = bytarr(cols_in, rows_in)
    openr, lun, file_in, /get_lun
    readu, lun, img_in
    free_lun, lun
    img_in = congrid(img_in, cols_out, rows_out)
    if n_elements(min_in) eq 0 then $
      min_in = min(img_in)
    if n_elements(max_in) eq 0 then $
      max_in = max(img_in)
    if histeq gt 0 then $
      img_in = hist_equal(img_in, min=min, max=max) $
    else $
      img_in = bytscl(img_in, min=min_in, max=max_in)
    img_in = reverse(img_in, 2)
    write_gif, file_out, img_in, rgb[*,0], rgb[*,1], rgb[*,2]
endif else begin
    img_out = bytarr(3, cols_out, rows_out)
    for i = 0, 2 do begin
        img_in = intarr(cols_in, rows_in)
        openr, lun, file_in[i], /get_lun
        readu, lun, img_in
        free_lun, lun
        img_in = congrid(img_in, cols_out, rows_out)
        if n_elements(min_in) eq 0 then $
            min = min(img_in) $
        else $
          min = min_in[i]
        if n_elements(max_in) eq 0 then $
          max = max(img_in) $
        else $
          max = max_in[i]
        j = where(img_in lt min, count)
        ;if count then $
        ;  img_in[j] = min
        print, 'count min:', count
        j = where(img_in gt max, count)
        ;if count then $
        ;  img_in[j] = max
        print, 'count max:', count
        print, min(img_in), max(img_in), min, max
        if histeq gt 0 then $
          img_in = hist_equal(img_in, min=min, max=max) $
        else $
          img_in = bytscl(img_in, min=min, max=max)
        img_out[i, *, *] = reverse(img_in, 2)
    endfor
    write_jpeg, file_out, img_out, quality=100, true=1 
endelse

end
