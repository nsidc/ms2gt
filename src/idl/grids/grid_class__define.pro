;*========================================================================
;* grid_class__define.pro - idl grid_class object
;*
;* 28-Feb-2001  Terry Haran  tharan@kryos.colorado.edu  303-492-1847
;* National Snow & Ice Data Center, University of Colorado, Boulder
;$Header: /export/data/modis/src/idl/grids/grid_class__define.pro,v 1.2 2001/03/20 23:55:13 haran Exp haran $
;*========================================================================*/

;+
; NAME:
;	grid_class object
;
; PURPOSE:
;       Creates an idl object that can be used to set-up a grid
;       defined by a gpd file.
;
; CATEGORY:
;	nsidc modis tools package.
;
; CALLING SEQUENCE:
;       grid_class_object = obj_new('grid_class', gpd_filename)
;       obj_destroy, grid_class_object
;
; ARGUMENTS:
;       gpd_filename - name of a gpd file that defines a particular grid.
;
; KEYWORDS:
;       help: if set, then the newly created object's full help
;       information is displayed after the object is initialized.
;
; RESULT:
;       When calling obj_new, a newly created grid_class object associated
;       with the given gpd file. If an error occurs, then the null object
;       is returned. 
;
; EXAMPLE:
;       oGrid = obj_new('grid_class', 'Gl1250.gpd')
;       obj_destroy, oGrid
;-
;-----------------------------------------------------------------------------
; grid_class::init
;
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


;-----------------------------------------------------------------------------
; grid_class::get_gpd_filename
;
function grid_class::get_gpd_filename
    return, self.gcs.gpd_filename
end


;-----------------------------------------------------------------------------
; grid_class::get_grid_dimensions
;
function grid_class::get_grid_dimensions
    return, [self.gcs.cols, self.gcs.rows]
end


;-----------------------------------------------------------------------------
; grid_class::get_grid_origin
;
function grid_class::get_grid_origin
    return, [self.gcs.map_origin_col, self.gcs.map_origin_row]
end


;-----------------------------------------------------------------------------
; grid_class::get_grid_scale
;
function grid_class::get_grid_scale
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


;-----------------------------------------------------------------------------
; grid_class::get_projection_name
;
function grid_class::get_projection_name
    return, self.gcs.projection_name
end


;-----------------------------------------------------------------------------
; grid_class::cleanup
;
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
