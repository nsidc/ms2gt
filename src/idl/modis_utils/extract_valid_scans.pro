;*========================================================================
;* extract_valid_scans.pro - extract latitude and longitude from a mod02 or
;                       mod03 file
;*
;* 19-Nov-2004  Terry Haran  tharan@colorado.edu  492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /data/haran/ms2gth/src/idl/modis_utils/extract_valid_scans.pro,v 1.2 2004/11/21 02:24:19 haran Exp haran $
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
;                                   band_index, area=area)
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
                              area=area

  usage = 'usage: image = extract_valid_scans(sd_id, sds_name, ' + $
          'lines_per_scan, band_index, [area=area]'

  if n_params() ne 4 then $
    message, usage

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

;- Get fill value
    attname = '_FillValue'
    attinfo = hdf_sd_attinfo(sd_id, sds_name, attname)
    if (attinfo.name eq attname) then $
      fill = attinfo.data[0] $
    else $
      fill = 0

;- Create a scan's worth of fill values
    npixels_per_scan = npixels_across * lines_per_scan
    scan_fill = make_array(npixels_per_scan, /float, value=fill)

;- Remove any scans that are all fill
    if npixels_along mod lines_per_scan ne 0 then $
      message, 'Number of lines in ' + sds_name + ':' + $
               string(npixels_across) + ' is not evenly divisible by ' + $
               string(lines_per_scan)
    nscans = npixels_along / lines_per_scan
    got_fill_scan = 0
    for i = 0L, nscans - 1 do begin
        first = i * npixels_per_scan
        last  = first + npixels_per_scan - 1

    ;- count gets number of elements where scan is not fill
        j = where((image[first:last] ne scan_fill) eq 1b, count)
        if count eq 0 then begin

        ;- scan was all fill
            got_fill_scan = 1
            if i lt nscans - 1 then begin
                image[first:(nscans - 1) * npixels_per_scan - 1] = $
                  image[first + npixels_per_scan:nscans * npixels_per_scan - 1]
                if got_mirror then $
                  mirror[i:nscans - 2] = mirror[i + 1:nscans - 1]
            endif
            i = i - 1
            nscans = nscans - 1
            npixels_along = npixels_along - lines_per_scan
        endif
    endfor
    if got_fill_scan then $
      image = image[*, 0:npixels_along - 1]

    if got_mirror then begin
        if got_fill_scan then $
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
            image = image[start[0]:last[0], last[0]:last[1]]
        endif
    endelse

    return, image
END ; extract_valid_scans
