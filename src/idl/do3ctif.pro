pro do3ctif, file_in, file_out, $
          shrink_factor=shrink_factor, min_in=min_in, max_in=max_in, $
          soze_in=soze_in, $
          color_table=color_table, $
          histeq=histeq

!order = 1
if n_params() ne 2 then $
  message, "syntax: do3ctif, file_in, file_out, " + $
                         "shrink_factor=shrink_factor, " + $
                         "min_in=min_in, max_in=max_in, " + $
                         "color_table=color_table, histeq=histeq"

if n_elements(shrink_factor) eq 0 then $
  shrink_factor = 1
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
if n_elements(soze_in) eq 1 then begin
    soze = read_tiff(soze_in)
    i = where(abs(90.0 - soze) lt 0.000001, icount)
    j = where(abs(90.0 - soze) ge 0.000001, jcount)
    if icount gt 0 then $
      soze[i] = 0
    if jcount gt 0 then $
      soze[j] = 1.0 / cos(soze[j] * !dtor)
endif
img_in = read_tiff(file_in[0], geotiff=geotiff)
bytes_per_cell = size(img_in, /type)
dims_img_in = size(img_in, /dimensions)
cols_in = dims_img_in[0]
rows_in = dims_img_in[1]
cols_out = cols_in / shrink_factor
rows_out = rows_in / shrink_factor
if n_elements(file_in) eq 1 then begin
    if n_elements(soze_in) eq 1 then begin
        img_in = img_in * soze
        if bytes_per_cell eq 1 then begin
            i = where (img_in gt 255.0, count)
            if count gt 0 then $
              img_in[i] = 255.0
            img_in = byte(img_in)
        endif
        if bytes_per_cell eq 2 then begin
            i = where (img_in gt 32767.0, count)
            if count gt 0 then $
              img_in[i] = 32767.0
            img_in = fix(img_in)
        endif
    endif
    img_in = congrid(img_in, cols_out, rows_out)
    if n_elements(min_in) eq 0 then $
      min_in = min(img_in)
    if n_elements(max_in) eq 0 then $
      max_in = max(img_in)
    if bytes_per_cell ne 1 then begin
        if histeq gt 0 then $
          img_in = hist_equal(img_in, min=min, max=max) $
        else $
          img_in = bytscl(img_in, min=min_in, max=max_in)
    endif
    img_in = reverse(img_in, 2)
    write_tiff, file_out, img_in, 0, geotiff=geotiff, $
      red=rgb[*,0], green=rgb[*,1], blue=rgb[*,2]
endif else begin
    img_out = bytarr(3, cols_out, rows_out)
    for i = 0, 2 do begin
        img_in = read_tiff(file_in[i], geotiff=geotiff)
        if (n_elements(file_in) eq 4) and (i eq 1) then begin
            img_in2 = img_in
            img_in = read_tiff(file_in[2])
            img_in = img_in / 2 + img_in2 / 2
            img_in2 = 0
            file_in[2] = file_in[3]
        endif
        if n_elements(soze_in) eq 1 then begin
            img_in = img_in * soze
            if bytes_per_cell eq 1 then begin
                i = where (img_in gt 255.0, count)
                if count gt 0 then $
                  img_in[i] = 255.0
                img_in = byte(img_in)
            endif
            if bytes_per_cell eq 2 then begin
                i = where (img_in gt 32767.0, count)
                if count gt 0 then $
                  img_in[i] = 32767.0
                img_in = fix(img_in)
            endif
        endif
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
        print, 'count min:', count
        j = where(img_in gt max, count)
        print, 'count max:', count
        print, min(img_in), max(img_in), min, max
        if histeq gt 0 then $
          img_in = hist_equal(img_in, min=min, max=max) $
        else $
          img_in = bytscl(img_in, min=min, max=max)
        img_out[i, *, *] = img_in
    endfor
    write_tiff, file_out, img_out, geotiff=geotiff
endelse

end
