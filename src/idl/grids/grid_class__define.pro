;*========================================================================
;* grid_class__define.pro - idl grid_class object
;*
;* 28-Feb-2001  Terry Haran  tharan@kryos.colorado.edu  303-492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/ms2gth/src/idl/grids/grid_class__define.pro,v 1.7 2001/10/22 17:58:25 haran Exp haran $
;*========================================================================*/

;+
; NAME:
;	grid_class::init
;
; PURPOSE:
;       Creates an idl object that can be used to set-up a grid
;       defined by a gpd file. Makes call to call_grid_init in C sharable
;       library call_grids.so.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = obj_new('grid_class', gpd_filename)
;
; ARGUMENTS:
;       gpd_filename - name of a gpd file that defines a particular grid.
;
; KEYWORDS:
;       help: if set, then the newly created object's full help
;       information is displayed after the object is initialized.
;
; RESULT:
;       A newly created grid_class object instance associated
;       with the given gpd file is returned. If an error occurs, then the
;       null object is returned. 
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;-

function grid_class::init, gpd_filename, help=help
    if n_elements(help) eq 0 then $
      help = 0
    gcs = self.gcs
    init_grid_ok = call_external('call_grids.so', 'call_init_grid', $
                                 gpd_filename, gcs)
    self.gcs = gcs
    if help ne 0 then begin
        help, self, /object, /full
        help, self.gcs, /struct
    endif
    if not init_grid_ok then begin
        message, 'call_init_grid failed', /informational
        return_code = 0
    endif else $
      return_code = 1
    return, return_code
end


;+
; NAME:
;	grid_class::get_grid_origin
;
; PURPOSE:
;       Return grid origin from a grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_origin()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A two element float array containing the column and row numbers of the
;       grid origin relative to the center of the upper left pixel of the
;       grid which is considered to be at column 0, row 0.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_origin = og->get_grid_origin()
;-

function grid_class::get_grid_origin
    return, [self.gcs.map_origin_col, self.gcs.map_origin_row]
end


;+
; NAME:
;	grid_class::get_grid_scales
;
; PURPOSE:
;       Return grid scales from a grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_scales()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A two element float array containing the horizontal and vertical
;       grid scales.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_scales = og->get_grid_scales()
;-

function grid_class::get_grid_scales
    if self.gcs.cols_per_map_unit gt 1e-10 then $
      col_scale = self.gcs.scale / self.gcs.cols_per_map_unit $
    else $
      col_scale = 0.0
    if self.gcs.rows_per_map_unit gt 1e-10 then $
      row_scale = self.gcs.scale / self.gcs.rows_per_map_unit $
    else $
      row_scale = 0.0
    return, [col_scale, row_scale]
end


;+
; NAME:
;	grid_class::get_grid_dimensions
;
; PURPOSE:
;       Return grid_dimensions from a grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_dimensions()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A two element long integer array containing the number of columns
;       and rows in the grid.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_dimensions = og->get_grid_dimensions()
;-

function grid_class::get_grid_dimensions
    return, [self.gcs.cols, self.gcs.rows]
end


;+
; NAME:
;	grid_class::get_gpd_filename
;
; PURPOSE:
;       Return the name of the gpd file from a grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_gpd_filename()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A string containing the name of the gpd file that defines the grid.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       gpd_filename = og->get_gpd_filename()
;-

function grid_class::get_gpd_filename
    return, self.gcs.gpd_filename
end

;+
; NAME:
;	grid_class::get_grid_coordinates
;
; PURPOSE:
;       Return the geographic coordinates of the standard parallel(s) and
;       meridian(s) associated with a grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_coordinates()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       An anonymous structure containing four float tags named:
;         lat0: latitude of first standard parallel.
;         lon0: longitude of first standard meridian.
;         lat1: latitude of second standard parallel.
;         lon1: longitude of second standard meridian.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_coordinates = og->get_grid_coordinates()
;-

function grid_class::get_grid_coordinates
    return, {lat0:self.gcs.lat0, lon0:self.gcs.lon0, $
             lat1:self.gcs.lat1, lon1:self.gcs.lon1}
end


;+
; NAME:
;	grid_class::get_grid_rotation
;
; PURPOSE:
;       Return grid rotation grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_rotation()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A float representing the grid rotation.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_rotation = og->get_grid_rotation()
;-

function grid_class::get_grid_rotation
    return, self.gcs.rotation
end


;+
; NAME:
;	grid_class::get_grid_bounds
;
; PURPOSE:
;       Return the geographic bounds associated with a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_bounds()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       An anonymous structure containing four float tags named:
;         south: southern-most latitude.
;         north: northern-most latitude.
;         west: western-most longitude.
;         east: eastern-most longitude.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_bounds = og->get_grid_bounds()
;-

function grid_class::get_grid_bounds
    return, {south:self.gcs.south, north:self.gcs.north, $
             west:self.gcs.west, east:self.gcs.east}
end


;+
; NAME:
;	grid_class::get_grid_center
;
; PURPOSE:
;       Return the geographic center associated with a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_center()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       An anonymous structure containing two float tags named:
;         center_lat: latitude of the projection center.
;         center_lon: longitude of the projection center.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_center = og->get_grid_center()
;-

function grid_class::get_grid_center
    return, {center_lat:self.gcs.center_lat, center_lon:self.gcs.center_lon}
end


;+
; NAME:
;	grid_class::get_grid_labels
;
; PURPOSE:
;       Return the geographic labels associated with a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_labels()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       An anonymous structure containing two float tags named:
;         label_lat: latitude label.
;         label_lon: longitude label.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_labels = og->get_grid_labels()
;-

function grid_class::get_grid_labels
    return, {label_lat:self.gcs.label_lat, $
             label_lon:self.gcs.label_lon}
end


;+
; NAME:
;	grid_class::get_grid_intervals
;
; PURPOSE:
;       Return the geographic intervals associated with a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_intervals()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       An anonymous structure containing two float tags named:
;         lat_interval: latitude interval.
;         lon_interval: longitude interval.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_intervals = og->get_grid_intervals()
;-

function grid_class::get_grid_intervals
    return, {lat_interval:self.gcs.lat_interval, $
             lon_interval:self.gcs.lon_interval}
end


;+
; NAME:
;	grid_class::get_grid_details
;
; PURPOSE:
;       Return the geographic details associated with a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_grid_details()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       An anonymous structure containing three long integer tags named:
;         cil_detail: coastline detail.
;         bdy_detail: boundary detail.
;         riv_detail: river detail.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       grid_details = og->get_grid_details()
;-

function grid_class::get_grid_details
    return, {cil_detail:self.gcs.cil_detail, $
             bdy_detail:self.gcs.bdy_detail, $
             riv_detail:self.gcs.riv_detail}
end


;+
; NAME:
;	grid_class::get_equatorial_radius
;
; PURPOSE:
;       Return the equatorial radius associated with a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_equatorial_radius()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A double containing the equatorial radius associated with a grid. 
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       equatorial_radius = og->get_equatorial_radius()
;-

function grid_class::get_equatorial_radius
    return, self.gcs.equatorial_radius
end


;+
; NAME:
;	grid_class::get_eccentricity
;
; PURPOSE:
;       Return the eccentricity associated with a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_eccentricity()
;
; ARGUMENTS:
;       None.
;
; RESULT:
;       A double containing the eccentricity associated with the grid.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       eccentricity = og->get_eccentricity()
;-

function grid_class::get_eccentricity
    return, self.gcs.eccentricity
end


;+
; NAME:
;	grid_class::get_map_origin
;
; PURPOSE:
;       Return x0 and y0 from a grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_map_origin()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A two element float array containing the translated map x,y origin
;       in map units.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       map_origin = og->get_map_origin()
;-

function grid_class::get_map_origin
    return, [self.gcs.x0, self.gcs.y0]
end


;+
; NAME:
;	grid_class::get_map_offset
;
; PURPOSE:
;       Return false_easting and false_northing from a grid_class object
;       instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_map_offset()
;
; ARGUMENTS:
;       None.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A two element float array containing the offset map x,y origin
;       in map units.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       map_offset = og->get_map_offset()
;-

function grid_class::get_map_offset
    return, [self.gcs.false_easting, self.gcs.false_northing]
end


;+
; NAME:
;	grid_class::get_center_scale
;
; PURPOSE:
;       Return the center_scale value used by the transverse mercator and
;       universal transverse mercator projections.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_center_scale()
;
; ARGUMENTS:
;       None.
;
; RESULT:
;       A float containing the center_scale associated with the grid.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       center_scale = og->get_center_scale()
;-

function grid_class::get_center_scale
    return, self.gcs.center_scale
end


;+
; NAME:
;	grid_class::get_utm_zone
;
; PURPOSE:
;       Return the utm zone value used by the universal transverse
;       mercator projection.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_utm_zone()
;
; ARGUMENTS:
;       None.
;
; RESULT:
;       A long integer containing the utm zone associated with the grid.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       utm_zone = og->get_utm_zone()
;-

function grid_class::get_utm_zone
    return, self.gcs.utm_zone
end


;+
; NAME:
;	grid_class::get_isin_params
;
; PURPOSE:
;       Return the isin_nzone and isin_justify parameters used by the
;       integerized sinusoidal projection.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_isin_params()
;
; ARGUMENTS:
;       None.
;
; RESULT:
;       An anonymous structure containing two long integer tags named:
;         nzone: Number of equally spaced latitudinal zones used by
;             the integerized sinusoidal projection.
;         justify: indicates what to do with zones with an odd number of
;             columns. If it has a value of 0 or 1, it indicates the extra
;             column is on the right (zero) or left (one) of the
;             projection y-axis. If the flag is set to 2, the number of
;             columns is calculated so there is always an even number of
;             columns in each zone. 
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       isin_params = og->get_isin_params()
;-

function grid_class::get_isin_params
    return, {nzone:self.gcs.isin_nzone, $
             justify:self.gcs.isin_justify}
end


;+
; NAME:
;	grid_class::get_projection_name
;
; PURPOSE:
;       Return the name of the projection from a grid_class object instance.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->get_projection_name()
;
; ARGUMENTS:
;       None.
;
; RESULT:
;       A string containing the name of the projection associated with
;       the grid.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       projection_name = og->get_projection_name()
;-

function grid_class::get_projection_name
    return, self.gcs.projection_name
end


;+
; NAME:
;	grid_class::forward
;
; PURPOSE:
;       Perform a forward mapping of latitude-longitude pairs to
;       column-row pairs.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->forward(lat, lon, col, row)
;
; ARGUMENTS:
;       lat: float latitude array to be used as input.
;       lon: float longitude array to be used as input.
;       col: float array of column numbers to be used as output.
;       row: float array of row numbers to be used as output.
;    NOTE: all the above arrays must be allocated prior to calling
;          grid_class::forward(), and must all have the same dimensions.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A byte array having the same dimensions as the output arrays. Each
;       element of the Result array is as follows:
;         1B: corresponding column-row pair is in the grid.
;         0B: otherwise.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       lat = [ 70.0,   70.0]
;       lon = [-40.0, -100.0]
;       col = lat
;       row = lon
;       status = og->forward(lat, lon, col, row)
;       print, 'status: ', status
;       print, 'col: ', col
;       print, 'row: ', row
;-

function grid_class::forward, lat, lon, col, row

    ; check for correct number of parameters

    if n_params() ne 4 then begin
        message, 'incorrect number of params', /informational
        return, 0
    endif

    ; check that all input arrays are the same size

    n = n_elements(lat)
    if (n_elements(lon) ne n) or $
       (n_elements(col) ne n) or $
       (n_elements(row) ne n) then $
      message, 'lat, lon, col, and row must all have the same element count'

    ; make sure that each input array is floating-point

    if size(lat, /type) ne 4 then $
      lat = float(lat)
    if size(lon, /type) ne 4 then $
      lat = float(lon)
    if size(col, /type) ne 4 then $
      lat = float(col)
    if size(row, /type) ne 4 then $
      lat = float(row)

    ; create a byte array for status the same size as the lat array

    status = byte(lat)
    
    ; call the function

    gcs = self.gcs
    forward_ok = call_external('call_grids.so', 'call_forward_grid', $
                               gcs, n, lat, lon, col, row, status)
    if not forward_ok then begin
        message, 'call_forward_grid failed', /informational
        return, 0
    endif
    return, status
end


;+
; NAME:
;	grid_class::inverse
;
; PURPOSE:
;       Perform a inverse mapping of column-row pairs to
;       latitude-longitude pairs.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       Result = grid_class_object_instance->inverse(col, row, lat, lon)
;
; ARGUMENTS:
;       col: float array of column numbers to be used as input.
;       row: float array of row numbers to be used as input.
;       lat: float latitude array to be used as output.
;       lon: float longitude array to be used as output.
;    NOTE: all the above arrays must be allocated prior to calling
;          grid_class::inverse(), and must all have the same dimensions.
;
; KEYWORDS:
;       None.
;
; RESULT:
;       A byte array having the same dimensions as the output arrays. Each
;       element of the Result array is as follows:
;         1B: corresponding latitude-longitude pair is within the map
;             boundaries.
;         0B: otherwise.
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       lat = [ 70.0,   70.0]
;       lon = [-40.0, -100.0]
;       col = lat
;       row = lon
;       status = og->inverse(lat, lon, col, row)
;       print, 'status: ', status
;       print, 'col: ', col
;       print, 'row: ', row
;-

function grid_class::inverse, col, row, lat, lon

    ; check for correct number of parameters

    if n_params() ne 4 then begin
        message, 'incorrect number of params', /informational
        return, 0
    endif

    ; check that all input arrays are the same size

    n = n_elements(col)
    if (n_elements(row) ne n) or $
       (n_elements(lat) ne n) or $
       (n_elements(lon) ne n) then $
      message, 'col, row, lat, and lon must all have the same element count'

    ; make sure that each input array is floating-point

    if size(col, /type) ne 4 then $
      lat = float(col)
    if size(row, /type) ne 4 then $
      lat = float(row)
    if size(lat, /type) ne 4 then $
      lat = float(lat)
    if size(lon, /type) ne 4 then $
      lat = float(lon)

    ; create a byte array for status the same size as the lat array

    status = byte(col)
    
    ; call the function

    gcs = self.gcs
    inverse_ok = call_external('call_grids.so', 'call_inverse_grid', $
                               gcs, n, col, row, lat, lon, status)
    if not inverse_ok then begin
        message, 'call_inverse_grid failed', /informational
        return, 0
    endif
    return, status
end


;+
; NAME:
;	grid_class::cleanup
;
; PURPOSE:
;       Cleans up a grid_class object instance prior to being
;       destroyed. Makes  call to call_grid_close in C sharable
;       library call_grids.so.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       obj_destroy(grid_class_object_instance)
;
; ARGUMENTS:
;       grid_class_object_instance: grid_class object instance returned
;         by obj_new('grid_class', gpd_filename).
;
; KEYWORDS:
;       help: if set, then the cleaned up object's full help
;       information is displayed before the object is destroyed.
;
; RESULT:
;       A newly created grid_class object instance associated
;       with the given gpd file is returned. If an error occurs, then the
;       null object is returned. 
;
; EXAMPLE:
;       og = obj_new('grid_class', 'Gl1250.gpd')
;       obj_destroy, og
;-

pro grid_class::cleanup, help=help
    if n_elements(help) eq 0 then $
      help = 0
    gcs = self.gcs
    close_grid_ok = call_external('call_grids.so', 'call_close_grid', $
                                  gcs)
    self.gcs = gcs
    if help ne 0 then begin
        help, self, /object, /full
        help, self.gcs, /struct
    endif
    if not close_grid_ok then begin
        message, 'call_close_grid failed', /informational
    end
end


;-----------------------------------------------------------------------------
; grid_class_struct__define -- defines grid_class structure
;
pro grid_class_struct__define
    struct = { grid_class_struct, $
;
;  C pointer to the grid class instance returned by grid_init.
;  Not used by IDL code; just a token passed to the C mapx library
;  routines. This would have to be hacked on a 64-bit machine.
;
;
               grid_class_ptr: 0L, $
;
;  public members of grid_class instance initialized by grid_init
;
               map_origin_col: 0.0, map_origin_row: 0.0, $
               cols_per_map_unit: 0.0, rows_per_map_unit: 0.0, $
               cols: 0L, rows: 0L, $
               gpd_filename: '', $
;
;  public members of mapx_class instance initialized by grid_init
;
               lat0: 0.0, lon0: 0.0, lat1: 0.0, lon1: 0.0, $
               rotation: 0.0, scale: 0.0, $
               south: 0.0, north: 0.0, west: 0.0, east: 0.0, $
               center_lat: 0.0, center_lon: 0.0, $
               label_lat: 0.0, label_lon: 0.0, $
               lat_interval: 0.0, lon_interval: 0.0, $
               cil_detail: 0L, bdy_detail: 0L, riv_detail: 0L, $
               equatorial_radius: 0.0D, eccentricity: 0.0D, $
               x0: 0.0, y0: 0.0, false_easting: 0.0, false_northing: 0.0, $
               center_scale: 0.0, $
               utm_zone: 0L, $
               isin_nzone: 0L, isin_justify: 0L, $
               projection_name: '' $
             }
end


;-----------------------------------------------------------------------------
; grid_class__define -- defines grid_class object
;
pro grid_class__define

    struct = { grid_class, $
               gcs: {grid_class_struct} $
             }
end
