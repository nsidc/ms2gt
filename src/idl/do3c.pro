pro do3c, cols_in, rows_in, file_in, file_out, $
          shrink_factor=shrink_factor, min_in=min_in, max_in=max_in

!order = 1
if n_params() ne 4 then $
  message, "syntax: do3c, cols_in, rows_in, file_in, file_out, " + $
                         "shrink_factor=shrink_factor, " + $
                         "min_in=min_in, max_in=max_in"

if n_elements(shrink_factor) eq 0 then $
  shrink_factor = 1
cols_out = cols_in / shrink_factor
rows_out = rows_in / shrink_factor
if n_elements(file_in) eq 1 then begin
    img_in = intarr(cols_in, rows_in)
    openr, lun, file_in, /get_lun
    readu, lun, img_in
    free_lun, lun
    img_in = congrid(img_in, cols_out, rows_out)
    if n_elements(min_in) eq 0 then $
      min_in = min(img_in)
    if n_elements(max_in) eq 0 then $
      max_in = max(img_in)
    img_in = bytscl(img_in, min=min_in, max=max_in)
    write_jpeg, file_out, img_in, quality=100
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
        if count then $
          img_in[j] = min
        print, 'count min:', count
        j = where(img_in gt max, count)
        if count then $
          img_in[j] = max
        print, 'count max:', count
        print, min(img_in), max(img_in), min, max
        img_in = bytscl(img_in, min=min, max=max)
        img_out[i, *, *] = reverse(img_in, 2)
    endfor
    write_jpeg, file_out, img_out, quality=100, true=1 
endelse

end
