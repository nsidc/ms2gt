;*========================================================================
;* extract_valid_scans.pro - extract latitude and longitude from a mod02 or
;                       mod03 file
;*
;* 19-Nov-2004  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /data/haran/ms2gth/src/idl/modis_utils/extract_valid_scans.pro,v 1.10 2004/12/04 19:16:01 haran Exp haran $
;*========================================================================*/

;+
; NAME:
;	extract_valid_scans
;
; PURPOSE:
;
; CATEGORY:
;	Modis.
;
; CALLING SEQUENCE:
;       image = extract_valid_scans(sd_id, sds_name, lines_per_scan,
;                                   band_index, area=area,
;                                   invalid_fraction_max=invalid_fraction_max,
;                                   valid_fill=valid_fill)
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

FUNCTION extract_valid_scans, sd_id, sds_name, lines_per_scan, band_index, $
                              area=area, $
                              invalid_fraction_max=invalid_fraction_max, $
                              valid_fill=valid_fill

  usage = 'usage: image = extract_valid_scans(sd_id, sds_name, ' + $
          'lines_per_scan, band_index, [area=area, ' + $
          'invalid_fraction_max=invalid_fraction_max, valid_fill=valid_fill]'

  if n_params() ne 4 then $
    message, usage

  if n_elements(invalid_fraction_max) eq 0 then $
    invalid_fraction_max = 0.5
  if n_elements(valid_fill) eq 0 then $
    valid_fill = 0

  got_mirror = 0
  if sds_name eq 'Mirror side' then begin

  ;- Read mirror side data
      got_mirror = 1
      hdf_sd_varread, sd_id, sds_name, mirror
      sds_name = 'Latitude'
  endif

  ;- Get information about the image array
    varinfo = hdf_sd_varinfo(sd_id, sds_name)
    if (varinfo.name eq '') then $
      message, 'Image array was not found: ' + sds_name
    npixels_across = varinfo.dims[0]
    npixels_along  = varinfo.dims[1]

  ;- If band_index is -1, then we have a two-dimensional array;
  ;- otherwise we have a band sequential, three-dimensional array,
  ;- with band_index the element number of the third dimension
    if band_index eq -1 then begin

  ;- Read two-dimensional data
        hdf_sd_varread, sd_id, sds_name, image

    endif else begin

  ;- Set start and count values
        start = [0L, 0L, band_index]
        count = [npixels_across, npixels_along, 1L]

  ;- Read the three-dimensional image array
  ;- (hdf_sd_varread not used because of bug in IDL 5.1)
        var_id = hdf_sd_select(sd_id, hdf_sd_nametoindex(sd_id, sds_name))
        hdf_sd_getdata, var_id, image, start=start, count=count
        hdf_sd_endaccess, var_id

    endelse

;- Read valid range attribute
    valid_name = 'valid_range'
    att_info = hdf_sd_attinfo(sd_id, sds_name, valid_name)
    if (att_info.name eq '') then message, 'Attribute not found: ' + valid_name
    valid_range = att_info.data

;- Get fill value
    attname = '_FillValue'
    attinfo = hdf_sd_attinfo(sd_id, sds_name, attname)
    if (attinfo.name eq attname) then $
      fill = attinfo.data[0] $
    else $
      fill = 0

;- Set invalid_count_max
    npixels_per_scan = npixels_across * lines_per_scan
    nscans = npixels_along / lines_per_scan
    invalid_count = 0L
    invalid_count_max = long(invalid_fraction_max * npixels_per_scan)

    if invalid_count_max gt 0 then begin

    ;- Remove any scans that have too many values outside of valid range
        if npixels_along mod lines_per_scan ne 0 then $
          message, 'Number of lines in ' + sds_name + ':' + $
                   string(npixels_across) + ' is not evenly divisible by ' + $
                   string(lines_per_scan)
        for i = 0L, nscans - 1 do begin
            k = i - invalid_count
            n = nscans - invalid_count
            first = k * npixels_per_scan
            last  = first + npixels_per_scan - 1

        ;- count gets number of invalid
        ;  treat all values for channel data (i.e. valid_fill)
        ;  except 65534 as valid because apparently lat-lon is valid
        ;  when chan is equal to anything other than 65534

            image_scan = image[first:last]
            test_scan0 = ((image_scan lt valid_range[0]) or $
                          (image_scan gt valid_range[1]))
            if valid_fill then begin
                test_scan1 = image_scan eq 65534
                j = where((test_scan0 and test_scan1) eq 1, count)
            endif else begin
                j = where(test_scan0 eq 1, count)
            endelse
            if count ge invalid_count_max then begin

            ;- scan was almost all invalid
                if i lt nscans - 1 then begin
                    image[first:(n - 1) * npixels_per_scan - 1] = $
                      image[first + npixels_per_scan: $
                            n * npixels_per_scan - 1]
                    if got_mirror then $
                      mirror[k:n - 2] = $
                        mirror[k + 1:n - 1]
                endif
                invalid_count = invalid_count + 1
                npixels_along = npixels_along - lines_per_scan
            endif else begin
                if valid_fill then $
                  j = where(test_scan0 eq 1, count)
                if count gt 0 then begin

                ;- set invalids to fill
                    image_scan[j] = fill
                    image[first:last] = image_scan
                endif
            endelse
        endfor
    endif

    if invalid_count gt 0 then begin
        nscans = nscans - invalid_count
        image = image[*, 0:npixels_along - 1]
    endif

    if got_mirror then begin
        if invalid_count gt 0 then $
          mirror = mirror[0:nscans - 1]

    ;- Use AREA keyword if it was supplied
        if (n_elements(area) eq 4) then begin
            area10 = area / 10
            start = (long(area10[1]) > 0L) < (nscans - 1L)
            last  = (long(area10[3] + start - 1L) > 0L) < (nscans - 1L)
            mirror = mirror[start:last]
        endif
        image = mirror
        sds_name = 'Mirror side'
            
    endif else begin

    ;- Use AREA keyword if it was supplied
        if (n_elements(area) eq 4) then begin
            start = lonarr(2)
            last  = lonarr(2)
            start[0] = (long(area[0]) > 0L) < (npixels_across - 1L)
            start[1] = (long(area[1]) > 0L) < (npixels_along  - 1L)
            last[0]  = (long(area[2] + start[0] - 1L) > 0L) < $
                                              (npixels_across - 1L)
            last[1]  = (long(area[3] + start[1] - 1L) > 0L) < $
                                              (npixels_along  - 1L)
            image = image[start[0]:last[0], start[1]:last[1]]
        endif
    endelse

    return, image
END ; extract_valid_scans
