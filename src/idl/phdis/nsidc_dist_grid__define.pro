; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; Grid object definition.
; This is where the action is.

; Initialization.
;
; $Log: nsidc_dist_grid__define.pro,v $
; Revision 1.5  2001/03/13 18:52:59  haran
; added log
;
;----------------------------
;revision 1.4	locked by: haran;
;date: 2001/03/13 17:40:55;  author: haran;  state: Exp;  lines: +5 -5
;changed image_drop to be under pos_text instead of to the right of it to
;save space in the image window
;----------------------------
;revision 1.3
;date: 2001/03/13 15:02:58;  author: haran;  state: Exp;  lines: +2 -2
;added format statements to pos_text lon and lat string() calls
;----------------------------
;revision 1.2
;date: 2001/03/13 00:17:17;  author: haran;  state: Exp;  lines: +2 -2
;changed /continents to /coasts in map_continents call
;----------------------------
;revision 1.1
;date: 2001/03/12 22:15:48;  author: haran;  state: Exp;
;Initial revision
;
FUNCTION NSIDC_DIST_GRID::INIT, main_obj, file_obj, grid_id, grid_name, field_names, dims, $
   SWATH=swath, STRIDE=stride, PARENT=parent, WIN_SIZE=win_size, ZOOM_BOX=zoom_box, $
   SHOW_GRAT=show_grat, SHOW_COAST=show_coast, R=r_in, G=g_in, B=b_in

   IF NOT(KEYWORD_SET(swath)) THEN BEGIN ; Check projection type.
      status = EOS_GD_PROJINFO(grid_id, projcode, zonecode, spherecode, projparam) ; Projection info.
      IF (projcode NE 11) THEN BEGIN
         file_obj -> GET_BASES, main_base, file_base
         ans = DIALOG_MESSAGE('Unsupported projection type for this grid.', /ERROR, $
                  DIALOG_PARENT=file_base)
         RETURN, 0
      ENDIF
   ENDIF

   ; General setup.

   IF (N_ELEMENTS(win_size) NE 2L) THEN win_size = [400,400]
   self.win_x = win_size[0]
   self.win_y = win_size[1]

   IF (N_ELEMENTS(zoom_box) EQ 4L) THEN self.zoom_box = zoom_box

   self.show_grat = KEYWORD_SET(show_grat)
   self.show_coast = KEYWORD_SET(show_coast)
   self.show_handle = 1B

   self.container = OBJ_NEW('IDL_Container')

   self.main_obj = main_obj
   self.file_obj = file_obj

   self.grid_id = grid_id
   self.grid_name = grid_name
   self.field_names_ptr = PTR_NEW(field_names)
   self.n_fields = N_ELEMENTS(field_names)

   IF OBJ_VALID(parent) THEN self.parent = parent

   ; Get fill value for each field.
   fill_vals = LONARR(self.n_fields)
   FOR i=0, self.n_fields-1 DO BEGIN
      status = EOS_GD_GETFILLVALUE(self.grid_id, (*(self.field_names_ptr))[i], fill_val)
      fill_vals[i] = fill_val
   ENDFOR
   self.fill_val_ptr = PTR_NEW(TEMPORARY(fill_vals))

   ; Figure out the data dimensions and interleaving.

   self.orig_dims_ptr = PTR_NEW(dims)

   n_dims = N_ELEMENTS(dims)
   IF (n_dims EQ 2L) THEN BEGIN
      self.dim_x = dims[0]
      self.dim_y = dims[1]
      self.n_images = 1
      self.interleave = (-1)
   ENDIF
   IF (n_dims EQ 3L) THEN BEGIN
      index = WHERE(dims NE MIN(dims), count)
      IF (count NE 2L) THEN BEGIN
         PTR_FREE, self.field_names_ptr
         RETURN, 0
      ENDIF
      self.dim_x = dims[index[0]]
      self.dim_y = dims[index[1]]
      self.n_images = MIN(dims)
      self.interleave = WHERE(dims EQ MIN(dims))
   ENDIF

   ; Set up the appropriate stride variables.

   IF (N_ELEMENTS(stride) GE 1L) THEN stride = MAX(stride) ELSE stride = 1
   CASE self.interleave OF
      (-1): BEGIN
         self.stride = [0,stride,stride] < ([0,self.dim_x,self.dim_y] / 8)
      END
      ( 0): BEGIN
         self.stride = [stride,stride,1] < ([self.dim_x,self.dim_y,8] / 8)
      END
      ( 1): BEGIN
         self.stride = [stride,1,stride] < ([self.dim_x,8,self.dim_y] / 8)
      END
      ( 2): BEGIN
         self.stride = [1,stride,stride] < ([8,self.dim_x,self.dim_y] / 8)
      END
   ENDCASE
   self.dim_x = self.dim_x / stride
   self.dim_y = self.dim_y / stride

   self.curr_image = 0
   self.curr_field = 0
   IF OBJ_VALID(self.parent) THEN BEGIN ; Use same field/image as parent.
      self.parent -> GET_CURR, curr_field, curr_image
      self.curr_field = curr_field
      self.curr_image = curr_image
   ENDIF

   ; More general setup.

   self.curr_box = (-1)

   self.box_color   = 248
   self.coast_color = 249
   self.grat_color  = 250

   self.blue = 251
   self.green = 252
   self.red = 253
   self.black = 254
   self.white = 255

   file_obj -> GET_BASES, main_base, file_base
   self.main_base = main_base
   self.file_base = file_base
   file_obj -> GET_CONTAINER, file_container
   self.file_container = file_container

   main_obj -> GET_CONTAINER, main_container
   self.main_container = main_container

   T3D, /RESET
   self.t3d = !P.T

   self.swath = KEYWORD_SET(swath)

   ; Build widgets.

   IF (self.swath) THEN title = 'Gridded Swath: ' + grid_name $
   ELSE title = ' Grid: ' + grid_name
   IF (N_ELEMENTS(field_names) EQ 1L) THEN title = title + ', Field: ' + field_names[0]

   self.grid_base = WIDGET_BASE(TITLE=title, /COLUMN, XPAD=1, YPAD=1, SPACE=1, $
                    GROUP_LEADER=self.file_base, MBAR=bar_base, /TLB_SIZE_EVENTS, $
                    UNAME='grid_base', KILL_NOTIFY='NSIDC_DIST_GRID_KILL')
   file_menu = WIDGET_BUTTON(bar_base, VALUE='File', /MENU)
   image_menu = WIDGET_BUTTON(bar_base, VALUE='Image', /MENU)
   window_menu = WIDGET_BUTTON(bar_base, VALUE='Window', /MENU)
   roi_menu = WIDGET_BUTTON(bar_base, VALUE='Region', /MENU)
   help_menu = WIDGET_BUTTON(bar_base, VALUE='Help', /MENU, /HELP)

   file_meta_bttn = WIDGET_BUTTON(file_menu, VALUE='View Metadata', $
                           UNAME='file_meta_bttn')
   file_tiff_bttn = WIDGET_BUTTON(file_menu, VALUE='Save Tiff Image', $
                           UNAME='file_tiff_bttn', /SEPARATOR)
   file_close_bttn = WIDGET_BUTTON(file_menu, VALUE='Close', $
                           UNAME='file_close_bttn', /SEPARATOR)

   img_bright_bttn = WIDGET_BUTTON(image_menu, VALUE='Brightness/Contrast...', $
                           UNAME='img_bright_bttn')
   img_palette_bttn = WIDGET_BUTTON(image_menu, VALUE='Palette...', $
                           UNAME='img_palette_bttn')
   IF (self.show_coast) THEN bt = 'Hide Coastlines' ELSE bt = 'Show Coastlines'
   img_coast_bttn = WIDGET_BUTTON(image_menu, VALUE=bt, $
                           UNAME='img_coast_bttn')
   IF (self.show_grat) THEN bt = 'Hide Graticule' ELSE bt = 'Show Graticule'
   img_grat_bttn = WIDGET_BUTTON(image_menu, VALUE=bt, $
                           UNAME='img_grat_bttn')
   img_clcol_bttn = WIDGET_BUTTON(image_menu, VALUE='Coastline Color...', $
                           UNAME='img_clcol_bttn')
   img_gtcol_bttn = WIDGET_BUTTON(image_menu, VALUE='Graticule Color...', $
                           UNAME='img_gtcol_bttn')
   img_legend_bttn = WIDGET_BUTTON(image_menu, VALUE='Show Legend', $
                           UNAME='img_legend_bttn')

   self.img_coast_bttn = img_coast_bttn
   self.img_grat_bttn = img_grat_bttn
   self.img_legend_bttn = img_legend_bttn

   win_unlink_bttn = WIDGET_BUTTON(window_menu, VALUE='Unlink', $
                           UNAME='win_unlink_bttn')
   win_link_bttn = WIDGET_BUTTON(window_menu, VALUE='Link', $
                           UNAME='win_link_bttn')
   win_replicate_bttn = WIDGET_BUTTON(window_menu, VALUE='Replicate', $
                           UNAME='win_replicate_bttn', /SEPARATOR)

   roi_type_bttn = WIDGET_BUTTON(roi_menu, VALUE='Box Coordinates...', $
                          UNAME='roi_type_bttn')
   roi_new_bttn = WIDGET_BUTTON(roi_menu, VALUE='Zoom To New Window', $
                          UNAME='roi_new_bttn', /SEPARATOR)
   roi_curr_bttn = WIDGET_BUTTON(roi_menu, VALUE='Zoom In Current Window', $
                          UNAME='roi_curr_bttn')
   roi_one_bttn = WIDGET_BUTTON(roi_menu, VALUE='Zoom 1:1', $
                          UNAME='roi_one_bttn')
   roi_fit_bttn = WIDGET_BUTTON(roi_menu, VALUE='Zoom To Fit', $
                          UNAME='roi_fit_bttn')
   IF (self.show_handle) THEN bt = 'Hide Box Handles' ELSE bt = 'Show Box Handles'
   roi_hide_bttn = WIDGET_BUTTON(roi_menu, VALUE=bt, $
                          UNAME='roi_hide_bttn', /SEPARATOR)
   roi_colo_bttn = WIDGET_BUTTON(roi_menu, VALUE='Box Color', $
                          UNAME='roi_colo_bttn')
   roi_table_bttn = WIDGET_BUTTON(roi_menu, VALUE='Data Table...', $
                          UNAME='roi_table_bttn', /SEPARATOR)
   roi_delete_bttn = WIDGET_BUTTON(roi_menu, VALUE='Delete', $
                          UNAME='roi_delete_bttn', /SEPARATOR)

   self.roi_hide_bttn = roi_hide_bttn

   help_use_bttn = WIDGET_BUTTON(help_menu, VALUE='Program Usage', $
                          UNAME='help_use_bttn')
   help_version_bttn = WIDGET_BUTTON(help_menu, VALUE='Version', $
                          UNAME='help_version_bttn')

   col_base = WIDGET_BASE(self.grid_base, /COLUMN, XPAD=1, YPAD=1, SPACE=1)
   wid = WIDGET_LABEL(col_base, VALUE='Lon,Lat,Img:')
   pt = STRING(0.0,format='(f10.5)') + ', ' + STRING(0.0,format='(f9.5)') + ', ' + STRING(0L)
   self.pos_text = WIDGET_TEXT(col_base, VALUE=pt, XSIZE=32)
   IF (self.n_fields GT 1) THEN BEGIN
      self.field_drop = WIDGET_DROPLIST(col_base, VALUE=(*self.field_names_ptr), $
                      UNAME='field_drop', TITLE='Field')
      WIDGET_CONTROL, self.field_drop, SET_DROPLIST_SELECT=self.curr_field
   ENDIF
   IF (self.n_images GT 1) THEN BEGIN
      self.image_drop = WIDGET_DROPLIST(col_base, VALUE=STRING(INDGEN(self.n_images)+1), $
                      UNAME='image_drop', TITLE='Image')
      WIDGET_CONTROL, self.image_drop, SET_DROPLIST_SELECT=self.curr_image
   ENDIF

   self.draw_base = WIDGET_BASE(self.grid_base, XPAD=1, YPAD=1, SPACE=1)
   self.legend_base = WIDGET_BASE(self.grid_base, XPAD=1, YPAD=1, SPACE=1)

   ; Create main draw widget and backing-store pixmap.
   self.grid_draw = WIDGET_DRAW(self.draw_base, XSIZE=self.win_x, YSIZE=self.win_y, $
                       /BUTTON_EVENTS, /MOTION_EVENTS, UNAME='grid_draw')
   WINDOW, /FREE, /PIXMAP, XSIZE=self.win_x, YSIZE=self.win_y
   self.grid_pix = !D.WINDOW

   ; Save top-level base size.
   WIDGET_CONTROL, self.grid_base, SET_UVALUE=self
   WIDGET_CONTROL, self.grid_base, /REALIZE
   base_geom = WIDGET_INFO(self.grid_base, /GEOMETRY)
   self.base_geom = [base_geom.scr_xsize, base_geom.scr_ysize]
   WIDGET_CONTROL, self.grid_draw, GET_VALUE=grid_wind
   self.grid_wind = grid_wind

   ; Set up colors (true-color display !).

   DEVICE, DECOMPOSED=0

   LOADCT, 0, NCOLORS=248
   TVLCT,   0, 255,   0, self.box_color
   TVLCT, 255,   0,   0, self.coast_color
   TVLCT, 100, 100, 255, self.grat_color

   TVLCT,   0,   0, 255, self.blue
   TVLCT,   0, 255,   0, self.green
   TVLCT, 255,   0,   0, self.red

   TVLCT,   0,   0,   0, self.black
   TVLCT, 255, 255, 255, self.white

   TVLCT, r, g, b, /GET
   IF (N_ELEMENTS(r_in) EQ 256L) THEN r = r_in
   IF (N_ELEMENTS(g_in) EQ 256L) THEN g = g_in
   IF (N_ELEMENTS(b_in) EQ 256L) THEN b = b_in
   TVLCT, r, g, b

   self.r = r
   self.g = g
   self.b = b
   self.max_img = 247

   self -> DRAW, /READ_DATA ; Display image.

   ; Start event processing.
   XMANAGER, 'NSIDC_DIST_GRID', self.grid_base

   RETURN, 1
END


; Draw image.
;
PRO NSIDC_DIST_GRID::DRAW, READ_DATA=read_data

   WSET, self.grid_wind
   read_data = KEYWORD_SET(read_data)
   IF NOT(PTR_VALID(self.data_ptr_ptr)) THEN read_data = 1B
   IF (PTR_VALID(self.data_ptr_ptr)) THEN BEGIN
      data_ptrs = *self.data_ptr_ptr
      IF NOT(PTR_VALID(data_ptrs[0])) THEN read_data = 1B
   ENDIF

   IF OBJ_VALID(self.parent) THEN BEGIN
      ; If a parent is available, share data with it.
      self.parent -> GET_PTRS, data_ptr_ptr, min_dat_ptr, max_dat_ptr
      self.parent -> GET_PROJ, bounds, center
      self.data_ptr_ptr = data_ptr_ptr
      self.min_dat_ptr = min_dat_ptr
      self.max_dat_ptr = max_dat_ptr
      self.bounds = bounds
      self.center = center
      read_data = 0B
   ENDIF

   IF (read_data) THEN BEGIN ; Read data from file.

      ; Progress indicator.
      load_base = WIDGET_BASE(TITLE='Load Status', /COLUMN, $
                     GROUP_LEADER=self.grid_base, FLOATING=self.grid_base)
      wid = WIDGET_LABEL(load_base, VALUE='Loading data, please wait...')
      load_field_labl = WIDGET_LABEL(load_base, /DYNAMIC_RESIZE, $
         VALUE='Field: '+(*(self.field_names_ptr))[0])
      WIDGET_CONTROL, load_base, /REALIZE

      ; Prepare pointers.

      IF (PTR_VALID(self.data_ptr_ptr)) THEN BEGIN
         data_ptrs = *self.data_ptr_ptr
         PTR_FREE, data_ptrs
      ENDIF
      PTR_FREE, self.data_ptr_ptr
      PTR_FREE, self.min_dat_ptr
      PTR_FREE, self.max_dat_ptr

      data_ptrs = PTRARR(self.n_fields)
      min_dat_list = LONARR(self.n_fields)
      max_dat_list = LONARR(self.n_fields)

      ; This is a work-around for an IDL bug.
      ; The EDGE keyword values to EOS_SW_READFIELD
      ; need to be reversed (Y before X) (but not for geo-fields).
      CASE self.interleave OF
         (-1): edge_val = REVERSE([self.dim_x, self.dim_y])
         ( 0): edge_val = REVERSE([self.n_images, self.dim_x, self.dim_y])
         ( 1): edge_val = REVERSE([self.dim_x, self.n_images, self.dim_y])
         ( 2): edge_val = REVERSE([self.dim_x, self.dim_y, self.n_images])
      ENDCASE

      FOR i=0, self.n_fields-1 DO BEGIN ; Loop through the fields.
         WIDGET_CONTROL, load_field_labl, SET_VALUE='Field: '+(*(self.field_names_ptr))[i]

         IF (self.swath) THEN BEGIN ; Read swath data.
            status = EOS_SW_READFIELD(self.grid_id, (*(self.field_names_ptr))[i], $
                        grid_data, STRIDE=(self.stride[WHERE(self.stride GT 0)]), $
                        EDGE=edge_val)
         ENDIF ELSE BEGIN ; Read grid data.
            status = EOS_GD_READFIELD(self.grid_id, (*(self.field_names_ptr))[i], $
                        grid_data, STRIDE=(self.stride[WHERE(self.stride GT 0)]), $
                        EDGE=edge_val)
            ;Flip image top-to-bottom.
            CASE self.interleave OF
               (-1): grid_data = REVERSE(TEMPORARY(grid_data), 2)
               ( 0): grid_data = REVERSE(TEMPORARY(grid_data), 3)
               ( 1): grid_data = REVERSE(TEMPORARY(grid_data), 3)
               ( 2): grid_data = REVERSE(TEMPORARY(grid_data), 2)
            ENDCASE
         ENDELSE

         ; Figure out true data min & max.

         fill_val = (*self.fill_val_ptr)[i]
         data_index = WHERE((grid_data NE fill_val) AND (grid_data NE 0.0))
         min_dat = fill_val
         max_dat = fill_val
         IF (data_index[0] GE 0L) THEN min_dat = MIN(grid_data[data_index], MAX=max_dat)
         min_dat = FLOAT(min_dat)
         max_dat = FLOAT(max_dat)
         IF ((min_dat GT 0.0) AND (min_dat LE 1.0)) THEN min_dat = 0.0
         IF (max_dat LE min_dat) THEN max_dat = min_dat + 1.0
         IF (i EQ 0) THEN sz_data = SIZE(grid_data)
         data_ptrs[i] = PTR_NEW(TEMPORARY(grid_data))
         min_dat_list[i] = min_dat
         max_dat_list[i] = max_dat

         IF (self.swath) THEN BEGIN ; Grid the swath data.
            status = EOS_SW_FIELDINFO(self.grid_id, (*(self.field_names_ptr))[i], data_rank, data_dims, data_numbertype, data_dim_names)
            data_dim_names = STRTRIM(STR_SEP(data_dim_names,','), 2)
            status = EOS_SW_INQGEOFIELDS(self.grid_id, geo_field_names, geo_rank, geo_numbertype)
            geo_field_names = STRTRIM(STR_SEP(geo_field_names,','), 2)
            status = EOS_SW_FIELDINFO(self.grid_id, geo_field_names[0], geo_rank0, geo_dims0, geo_numbertype0, geo_dim_names0)
            status = EOS_SW_FIELDINFO(self.grid_id, geo_field_names[1], geo_rank1, geo_dims1, geo_numbertype1, geo_dim_names1)
            geo_dim_names0 = STRTRIM(STR_SEP(geo_dim_names0,','), 2)
            stat = EOS_SW_MAPINFO(self.grid_id, geo_dim_names0[0], data_dim_names[0], os_x, inc_x)
            stat = EOS_SW_MAPINFO(self.grid_id, geo_dim_names0[1], data_dim_names[1], os_y, inc_y)

            ; Figure out an appropritate stride value for the lon-lat location arrays.
            stride = (REPLICATE(MAX(self.stride), 2) / (inc_x > inc_y > 1)) > 1
            geo_dims0 = geo_dims0 / stride
            geo_dims1 = geo_dims1 / stride
            os_x = os_x / MAX(self.stride)
            os_y = os_y / MAX(self.stride)

            IF (i EQ 0) THEN BEGIN
               status = EOS_SW_READFIELD(self.grid_id, geo_field_names[0], lat, $
                           STRIDE=stride, EDGE=REVERSE(geo_dims0)) ; Latitude locations.
               status = EOS_SW_READFIELD(self.grid_id, geo_field_names[1], lon, $
                           STRIDE=stride, EDGE=REVERSE(geo_dims1)) ; Longitude locations.
               min_lat = MIN(lat, MAX=max_lat)
               min_lon = MIN(lon, MAX=max_lon)
               mid_lat = TOTAL(lat) / FLOAT(N_ELEMENTS(lat))
               mid_lon = TOTAL(lon) / FLOAT(N_ELEMENTS(lon))

               ; Get gridding parameters from user.

               grid_x = 512
               grid_y = 512

               ; Build widgets.

               param_base = WIDGET_BASE(TITLE='Enter swath gridding parameters', /COLUMN, $
                               GROUP_LEADER=self.grid_base, FLOATING=self.grid_base, $
                               /MODAL)

               col_base = WIDGET_BASE(param_base, /COLUMN, /FRAME)
               wid = WIDGET_LABEL(col_base, VALUE='Projection Center')
               row_base = WIDGET_BASE(col_base, /ROW)
               wid = WIDGET_LABEL(row_base, VALUE='Lon:')
               mid_lon_text = WIDGET_TEXT(row_base, VALUE=STRING(mid_lon), /EDITABLE, /FRAME, $
                             UNAME='mid_lon_text')
               wid = WIDGET_LABEL(row_base, VALUE='   Lat:')
               mid_lat_text = WIDGET_TEXT(row_base, VALUE=STRING(mid_lat), /EDITABLE, /FRAME, $
                             UNAME='mid_lat_text')

               col_base = WIDGET_BASE(param_base, /COLUMN, /FRAME)
               wid = WIDGET_LABEL(col_base, VALUE='Projection Extents')
               row_base = WIDGET_BASE(col_base, COLUMN=4)
               wid = WIDGET_LABEL(row_base, VALUE='Lon Min:')
               min_lon_text = WIDGET_TEXT(row_base, VALUE=STRING(min_lon), /EDITABLE, /FRAME, $
                                 UNAME='min_lon_text')
               wid = WIDGET_LABEL(row_base, VALUE='   Lon Max:')
               max_lon_text = WIDGET_TEXT(row_base, VALUE=STRING(max_lon), /EDITABLE, /FRAME, $
                                 UNAME='max_lon_text')
               row_base = WIDGET_BASE(col_base, /ROW)
               wid = WIDGET_LABEL(row_base, VALUE='Lat Min:')
               min_lat_text = WIDGET_TEXT(row_base, VALUE=STRING(min_lat), /EDITABLE, /FRAME, $
                                 UNAME='min_lat_text')
               wid = WIDGET_LABEL(row_base, VALUE='   Lat Max:')
               max_lat_text = WIDGET_TEXT(row_base, VALUE=STRING(max_lat), /EDITABLE, /FRAME, $
                                 UNAME='max_lat_text')

               col_base = WIDGET_BASE(param_base, /COLUMN, /FRAME)
               wid = WIDGET_LABEL(col_base, VALUE='Grid Size')
               row_base = WIDGET_BASE(col_base, /ROW)
               wid = WIDGET_LABEL(row_base, VALUE='X:')
               x_text = WIDGET_TEXT(row_base, VALUE=STRING(grid_x), /EDITABLE, /FRAME, $
                                 UNAME='x_text')
               wid = WIDGET_LABEL(row_base, VALUE='   Y:')
               y_text = WIDGET_TEXT(row_base, VALUE=STRING(grid_y), /EDITABLE, /FRAME, $
                                 UNAME='y_text')

               bttn_base = WIDGET_BASE(param_base, COLUMN=2, /GRID)
               ok_bttn = WIDGET_BUTTON(bttn_base, VALUE='Ok', UNAME='ok_bttn')

               ; Gridding parameters dialog state.
               grid_state = {mid_lon:mid_lon, mid_lat:mid_lat, $
                             min_lon:min_lon, min_lat:min_lat, $
                             max_lon:max_lon, max_lat:max_lat, $
                             grid_x:grid_x, grid_y:grid_y, $
                             mid_lon_text:mid_lon_text, $
                             mid_lat_text:mid_lat_text, $
                             min_lon_text:min_lon_text, $
                             min_lat_text:min_lat_text, $
                             max_lon_text:max_lon_text, $
                             max_lat_text:max_lat_text, $
                             x_text:x_text, y_text:y_text, $
                             status:0B}

               ; Start event processing.
               state_ptr = PTR_NEW(TEMPORARY(grid_state))
               WIDGET_CONTROL, param_base, SET_UVALUE=state_ptr
               WIDGET_CONTROL, param_base, /REALIZE
               XMANAGER, 'NSIDC_DIST_GRID_PARAM', param_base
               ; Execution pauses here until the dialog is destroyed.

               WIDGET_CONTROL, /HOURGLASS
               grid_state = TEMPORARY(*state_ptr)
               PTR_FREE, state_ptr

            ENDIF

            ; Make a gridding progress indicatior.
            progress_base = WIDGET_BASE(TITLE='Gridding Status', /COLUMN, $
                               GROUP_LEADER=self.grid_base, FLOATING=self.grid_base)
            wid = WIDGET_LABEL(progress_base, VALUE='Gridding swath data, please wait...')
            field_labl = WIDGET_LABEL(progress_base, /DYNAMIC_RESIZE, $
               VALUE='Field: '+(*(self.field_names_ptr))[i])
            image_labl = WIDGET_LABEL(progress_base, /DYNAMIC_RESIZE, $
               VALUE='Image: '+STRING(0))
            WIDGET_CONTROL, progress_base, /REALIZE

            ; Get ready for the actual gridding.

            grid_data = TEMPORARY(*(data_ptrs[i]))
            PTR_FREE, data_ptrs[i]

            IF (i EQ 0) THEN sz_lat = SIZE(lat)
            ll_xdim = (((sz_lat[1] - 1L) * inc_x * stride[0]) / MAX(self.stride))
            ll_ydim = (((sz_lat[2] - 1L) * inc_y * stride[1]) / MAX(self.stride))

            g_stride = (ROUND(FLOAT(ll_xdim) / FLOAT(grid_state.grid_x)) < $
                        ROUND(FLOAT(ll_ydim) / FLOAT(grid_state.grid_y))) > 1
            new_x_size = ll_xdim / g_stride
            new_y_size = ll_xdim / g_stride

            CASE self.interleave OF
               (-1): BEGIN
                     grid_data = grid_data[os_x:os_x+ll_xdim-1, os_y:os_y+ll_ydim-1]
                     grid_data = CONGRID(TEMPORARY(grid_data), new_x_size, new_y_size, /INTERP, /MINUS_ONE)
               END
               ( 0): BEGIN
                     grid_data = grid_data[*, os_x:os_x+ll_xdim-1, os_y:os_y+ll_ydim-1]
                     grid_data = CONGRID(TEMPORARY(grid_data), self.n_images, new_x_size, new_y_size, $
                                     /INTERP, /MINUS_ONE)
               END
               ( 1): BEGIN
                     grid_data = grid_data[os_x:os_x+ll_xdim-1, *, os_y:os_y+ll_ydim-1]
                     grid_data = CONGRID(TEMPORARY(grid_data), new_x_size, self.n_images, new_y_size, $
                                     /INTERP, /MINUS_ONE)
               END
               ( 2): BEGIN
                     grid_data = grid_data[os_x:os_x+ll_xdim-1, os_y:os_y+ll_ydim-1, *]
                     grid_data = CONGRID(TEMPORARY(grid_data), new_x_size, new_y_size, self.n_images, $
                                    /INTERP, /MINUS_ONE)
               END
            ENDCASE

            IF (i EQ 0) THEN BEGIN
               ; If this is the first field, then setup for all fields.

               ; Size the lon-lat location arrays
               data_type = SIZE(grid_data, /TYPE)
               lat = CONGRID(TEMPORARY(lat), new_x_size, new_y_size, /INTERP, /MINUS_ONE)
               lon = CONGRID(TEMPORARY(lon), new_x_size, new_y_size, /INTERP, /MINUS_ONE)

               ; Set up the map projection.

               self.bounds = [grid_state.min_lat,grid_state.min_lon,$
                              grid_state.max_lat,grid_state.max_lon]
               self.center = [grid_state.mid_lat, grid_state.mid_lon]

               IF (grid_state.mid_lat LT 0.0) THEN map_ang = 0.0 ELSE map_ang = 0.0
               MAP_SET, grid_state.mid_lat, grid_state.mid_lon, map_ang, /LAMBERT, /NOBORDER, $
                  XMARGIN=[0,0], YMARGIN=[0,0], LIMIT=self.bounds[0:3], /NOERASE

               ; Convert from lon-lat to grid coordinates.
               xy = (CONVERT_COORD(TEMPORARY(lon), TEMPORARY(lat), /DATA, /TO_NORMAL))[0:1,*]
               xy[0,0] = (ROUND(xy[0,*] * FLOAT(grid_state.grid_x-1)) > 0L) < (grid_state.grid_x - 1L)
               xy[1,0] = (ROUND(xy[1,*] * FLOAT(grid_state.grid_y-1)) > 0L) < (grid_state.grid_y - 1L)
               n_xy = N_ELEMENTS(xy) / 2L

               max_gap = (new_x_size / grid_state.grid_x) > (new_y_size / grid_state.grid_y)
               max_gap = max_gap * MAX(self.stride)
            ENDIF

            ; Make an array (of the same type as the swath data)
            ; to hold the gridded data.
            CASE self.interleave OF
               (-1): gridded_data = MAKE_ARRAY(grid_state.grid_x, grid_state.grid_y, TYPE=data_type)
               ( 0): gridded_data = MAKE_ARRAY(self.n_images, grid_state.grid_x, grid_state.grid_y, TYPE=data_type)
               ( 1): gridded_data = MAKE_ARRAY(grid_state.grid_x, self.n_images, grid_state.grid_y, TYPE=data_type)
               ( 2): gridded_data = MAKE_ARRAY(grid_state.grid_x, grid_state.grid_y, self.n_images, TYPE=data_type)
            ENDCASE
            FOR j=0, self.n_images-1 DO BEGIN ; Loop through and grid each image.
               WIDGET_CONTROL, image_labl, SET_VALUE='Image: '+STRING(j)
               CASE self.interleave OF
                  (-1): grid_img = grid_data
                  ( 0): grid_img = REFORM(grid_data[j,*,*])
                  ( 1): grid_img = REFORM(grid_data[*,j,*])
                  ( 2): grid_img = REFORM(grid_data[*,*,j])
               ENDCASE

               ; Set up gridding arrays.
               gridded_swath = FLTARR(grid_state.grid_x, grid_state.grid_y)
               gridded_count = FLTARR(grid_state.grid_x, grid_state.grid_y)

               ; Map points onto grid (average multiple hits).
               FOR np=0L, n_xy-1L DO BEGIN
                  x_pos = xy[0,np]
                  y_pos = xy[1,np]
                  gridded_swath[x_pos,y_pos] = gridded_swath[x_pos,y_pos] + FLOAT(grid_img[np])
                  gridded_count[x_pos,y_pos] = gridded_count[x_pos,y_pos] + 1.0
               ENDFOR

               ; Put zeroes around the edges.
               gridded_swath[0,*] = 0.0
               gridded_swath[grid_state.grid_x-1,*] = 0.0
               gridded_swath[*,0] = 0.0
               gridded_swath[*,grid_state.grid_y-1] = 0.0
               gridded_count[0,*] = 0.0
               gridded_count[grid_state.grid_x-1,*] = 0.0
               gridded_count[*,0] = 0.0
               gridded_count[*,grid_state.grid_y-1] = 0.0

               ; Fill in the holes (where the grid has no points mapped to it).
               in_index = WHERE(gridded_count GE 1.0, in_count)
               IF (in_count GT 0L) THEN BEGIN
                  out_index = WHERE(gridded_count EQ 0.0)
                  gridded_swath = TEMPORARY(gridded_swath) / (TEMPORARY(gridded_count) > 1.0)
                  gridded_swath[TEMPORARY(out_index)] = !VALUES.F_NAN
                  in_vals = gridded_swath[in_index]
                  FOR passes=0, (((max_gap / 2) - 1) > 0) DO BEGIN
                     gridded_swath = SMOOTH(gridded_swath, 3, /EDGE_TRUNCATE, /NAN)
                     gridded_swath[in_index] = in_vals
                  ENDFOR
                  in_vals = 0
                  in_index = 0
                  out_index = WHERE(FINITE(gridded_swath) EQ 0)
                  IF (out_index[0] GE 0L) THEN gridded_swath[TEMPORARY(out_index)] = 0.0
               ENDIF ELSE BEGIN
                  gridded_count = 0
               ENDELSE

               CASE self.interleave OF
                  (-1): gridded_data[0,0] = TEMPORARY(gridded_swath)
                  ( 0): gridded_data[j,0,0] = $
                           REFORM(TEMPORARY(gridded_swath), 1, grid_state.grid_x, grid_state.grid_y)
                  ( 1): gridded_data[0,j,0] = $
                           REFORM(TEMPORARY(gridded_swath), grid_state.grid_x, 1, grid_state.grid_y)
                  ( 2): gridded_data[0,0,j] = $
                           REFORM(TEMPORARY(gridded_swath), grid_state.grid_x, grid_state.grid_y, 1)
               ENDCASE

            ENDFOR
            ; Store the gridded data for this field.
            data_ptrs[i] = PTR_NEW(TEMPORARY(gridded_data))

            IF WIDGET_INFO(progress_base, /VALID_ID) THEN $
               WIDGET_CONTROL, progress_base, /DESTROY

            ; Finished gridding swath data !
         ENDIF ELSE BEGIN ; Regular grid.
            ; Figure out a matching IDL map projection.

            status = EOS_GD_GRIDINFO(self.grid_id, xdim, ydim, up_left, low_right) ; Position info.
            status = EOS_GD_PROJINFO(self.grid_id, projcode, zonecode, spherecode, projparam) ; Projection info.

            low_left = [up_left[0],low_right[1]]
            up_right = [low_right[0],up_left[1]]
            center_lon = projparam[4] / 1.0D6
            center_lat = projparam[5] / 1.0D6

            status = NSIDC_DIST_GET_LATLON(up_left, projcode, projparam)
            status = NSIDC_DIST_GET_LATLON(low_right, projcode, projparam)
            status = NSIDC_DIST_GET_LATLON(low_left, projcode, projparam)
            status = NSIDC_DIST_GET_LATLON(up_right, projcode, projparam)

            ; Center and Bounds are used later with "MAP_SET".
            self.center = [center_lat,center_lon]
            self.bounds = [low_left[*],up_left[*],up_right[*],low_right[*]]
         ENDELSE

      ENDFOR ; End of fields loop.

      IF (self.swath) THEN BEGIN
         self.dim_x = grid_state.grid_x
         self.dim_y = grid_state.grid_y
      ENDIF

      self.data_ptr_ptr = PTR_NEW(data_ptrs)
      self.min_dat_ptr = PTR_NEW(TEMPORARY(min_dat_list))
      self.max_dat_ptr = PTR_NEW(TEMPORARY(max_dat_list))

      WIDGET_CONTROL, load_base, /DESTROY ; Destroy progress indicator.
   ENDIF

   ; Re-arrange data for storage.

   data_ptrs = *self.data_ptr_ptr

   min_dat = (*self.min_dat_ptr)[self.curr_field]
   max_dat = (*self.max_dat_ptr)[self.curr_field]
   CASE self.interleave OF
      (-1): data = (*(data_ptrs[self.curr_field]))
      ( 0): data = (*(data_ptrs[self.curr_field]))[self.curr_image,*,*]
      ( 1): data = (*(data_ptrs[self.curr_field]))[*,self.curr_image,*]
      ( 2): data = (*(data_ptrs[self.curr_field]))[*,*,self.curr_image]
   ENDCASE
   data = REFORM(data, /OVERWRITE)

   ; Define the IDL map projection.

   IF (self.center[0] LT 0.0) THEN map_ang = 0.0 ELSE map_ang = 0.0
   IF (self.swath) THEN bounds = self.bounds[0:3] ELSE bounds = self.bounds
   MAP_SET, self.center[0], self.center[1], map_ang, /LAMBERT, /NOBORDER, $
            XMARGIN=[0,0], YMARGIN=[0,0], LIMIT=bounds, /NOERASE
   bx0 = self.zoom_box[0] > 0
   bx1 = self.zoom_box[2] < (self.dim_x - 1)
   by0 = self.zoom_box[1] > 0
   by1 = self.zoom_box[3] < (self.dim_y - 1)
   IF (((bx1 - bx0) GT 0) AND ((by1 - by0) GT 0)) THEN BEGIN ; Zoom box active.
      data = data[bx0:bx1,by0:by1]

      sx = FLOAT(self.dim_x-1) / FLOAT(bx1 - bx0)
      sy = FLOAT(self.dim_y-1) / FLOAT(by1 - by0)
      ox = FLOAT(bx0) / FLOAT(self.dim_x-1)
      oy = FLOAT(by0) / FLOAT(self.dim_y-1)
      T3D, /RESET
      T3D, TRANSLATE=[-ox, -oy, 0.0]
      T3D, SCALE=[sx, sy, 1.0]
   ENDIF ELSE BEGIN
      T3D, /RESET
   ENDELSE
   self.t3d = !P.T
   data = CONGRID(data, self.win_x, self.win_y, /INTERP, /MINUS_ONE)

   ; Finally, the image can be displayed.
   WSET, self.grid_pix
   TVLCT, self.r, self.g, self.b
   TV, BYTSCL(TEMPORARY(data), MIN=min_dat, MAX=max_dat, TOP=self.max_img)

   IF (self.show_coast) THEN $ ; Draw coastlines.
      MAP_CONTINENTS, /COASTS, /COUNTRIES, /USA, COLOR=self.coast_color, $
         /HIRES, /T3D
   IF (self.show_grat) THEN $ ; Draw graticule.
      MAP_GRID, /LABEL, COLOR=self.grat_color, /T3D

    ; Copy image from backing-store pixmap to visible draw widget.
    self -> DRAW_UPDATE
END


; Draw roi boxes on image.
;
PRO NSIDC_DIST_GRID::DRAW_BOXES
   ; Set window and transformation.
   WSET, self.grid_wind
   !P.T = self.t3d

   n_boxes = 0L
   IF PTR_VALID(self.box_pts_ptr) THEN n_boxes = N_ELEMENTS(*self.box_pts_ptr) / 4L
   TVLCT, self.r[self.box_color], self.g[self.box_color], self.b[self.box_color], $
          self.box_color
   FOR i=0, n_boxes-1L DO BEGIN
      pts = (*self.box_pts_ptr)[*,i]
      xp = FLOAT([pts[0],pts[2],pts[2],pts[0],pts[0]]) / FLOAT(self.dim_x-1)
      yp = FLOAT([pts[1],pts[1],pts[3],pts[3],pts[1]]) / FLOAT(self.dim_y-1)
      xyp = FLTARR(3,5)
      xyp[0,0] = REFORM(xp, 1, 5)
      xyp[1,0] = REFORM(yp, 1, 5)
      xyp = VERT_T3D(xyp)
      xp = xyp[0,*]
      yp = xyp[1,*]
      xc = (xp[0] + xp[2]) / 2.0
      yc = (yp[1] + yp[3]) / 2.0
      xp = ROUND(xp * FLOAT(self.win_x-1))
      yp = ROUND(yp * FLOAT(self.win_y-1))
      xc = ROUND(xc * FLOAT(self.win_x-1))
      yc = ROUND(yc * FLOAT(self.win_y-1))
      bt = 1B + (2B * (self.curr_box EQ i))
      PLOTS, xp, yp, /DEVICE, COLOR=self.box_color, THICK=bt
      IF (self.show_handle) THEN BEGIN ; Draw box handles.
         PLOTS, xp, yp, /DEVICE, COLOR=self.box_color, PSYM=6
         c_sym = 1
      ENDIF ELSE BEGIN
         c_sym = 3
      ENDELSE
      ; Draw box.
      PLOTS, [xc], [yc], /DEVICE, COLOR=self.box_color, PSYM=c_sym
   ENDFOR
END


; Quick image update from backing-store pixmap.
;
PRO NSIDC_DIST_GRID::DRAW_UPDATE
   WSET, self.grid_wind
   DEVICE, COPY=[0,0,self.win_x,self.win_y,0,0,self.grid_pix]
   self -> DRAW_BOXES
END


; Draw (highlight) selected cells from associated data table object.
;
PRO NSIDC_DIST_GRID::DRAW_TABLE, grid_box_pts, grid_hlt_pts
   WSET, self.grid_wind
   !P.T = self.t3d
   box_pts = FLOAT(grid_box_pts) / FLOAT([self.dim_x,self.dim_y,self.dim_x,self.dim_y]-1)
   hlt_pts = FLOAT(grid_hlt_pts) / FLOAT([self.dim_x,self.dim_y,self.dim_x,self.dim_y]-1)
   PLOTS, [box_pts[0],box_pts[2],box_pts[2],box_pts[0],box_pts[0]], $
          [box_pts[1],box_pts[1],box_pts[3],box_pts[3],box_pts[1]], $
          LINESTYLE=1, COLOR=self.box_color, /NORMAL, /T3D
   PLOTS, [hlt_pts[0],hlt_pts[2],hlt_pts[2],hlt_pts[0],hlt_pts[0]], $
          [hlt_pts[1],hlt_pts[1],hlt_pts[3],hlt_pts[3],hlt_pts[1]], $
          COLOR=self.box_color, /NORMAL, /T3D
   POLYFILL, [hlt_pts[0],hlt_pts[2],hlt_pts[2],hlt_pts[0],hlt_pts[0]], $
             [hlt_pts[1],hlt_pts[1],hlt_pts[3],hlt_pts[3],hlt_pts[1]], $
             COLOR=self.box_color, /NORMAL, /T3D
END


; Draw the legend.
;
PRO NSIDC_DIST_GRID::DRAW_LEGEND

   IF NOT(WIDGET_INFO(self.legend_draw, /VALID_ID)) THEN RETURN ; No legend.

   WSET, self.legend_wind
   ERASE, self.white

   min_dat = (*self.min_dat_ptr)[self.curr_field]
   max_dat = (*self.max_dat_ptr)[self.curr_field]
   mid_dat = (min_dat + max_dat) / 2

   data_ptrs = *self.data_ptr_ptr
   CASE self.interleave OF
      (-1): data = (*(data_ptrs[self.curr_field]))
      ( 0): data = (*(data_ptrs[self.curr_field]))[self.curr_image,*,*]
      ( 1): data = (*(data_ptrs[self.curr_field]))[*,self.curr_image,*]
      ( 2): data = (*(data_ptrs[self.curr_field]))[*,*,self.curr_image]
   ENDCASE
   data = REFORM(data, /OVERWRITE)
   sf = 63.0 / FLOAT(self.dim_y)
   t_xdim = ROUND(sf * FLOAT(self.dim_x))
   t_ydim = 63
   data = CONGRID(TEMPORARY(data), t_xdim, t_ydim, /MINUS_ONE, /INTERP)
   TV, BYTSCL(TEMPORARY(data), MIN=min_dat, MAX=max_dat, TOP=self.max_img), $
         (self.win_x - t_xdim), 0
   nx0 = FLOAT(self.zoom_box[0]) / FLOAT(self.dim_x - 1)
   nx1 = FLOAT(self.zoom_box[2]) / FLOAT(self.dim_x - 1)
   ny0 = FLOAT(self.zoom_box[1]) / FLOAT(self.dim_y - 1)
   ny1 = FLOAT(self.zoom_box[3]) / FLOAT(self.dim_y - 1)
   IF (((nx1 - nx0) GT 0.0) AND ((ny1 - ny0) GT 0.0)) THEN BEGIN ; Zoom box active.
      nx0 = ROUND(nx0 * FLOAT(t_xdim)) + ((self.win_x - t_xdim) - 1)
      nx1 = ROUND(nx1 * FLOAT(t_xdim)) + ((self.win_x - t_xdim) - 1)
      ny0 = ROUND(ny0 * FLOAT(t_xdim))
      ny1 = ROUND(ny1 * FLOAT(t_xdim))
      PLOTS, [nx0,nx1,nx1,nx0,nx0], [ny0,ny0,ny1,ny1,ny0], $
             /DEVICE, COLOR=self.box_color
   ENDIF

   bar_x = (self.win_x - t_xdim) - 8
   x0 = 0
   x1 = bar_x + 1
   cx = (x0 + x1) / 2

   color_bar = BINDGEN(self.max_img+1) # REPLICATE(1.0, 24)
   color_bar = CONGRID(color_bar, bar_x, 24, /INTERP, /MINUS_ONE)

   PLOTS, [x0,x0], [25,28], /DEVICE, COLOR=self.black
   PLOTS, [cx,cx], [25,28], /DEVICE, COLOR=self.black
   PLOTS, [x1,x1], [25,28], /DEVICE, COLOR=self.black
   PLOTS, [x0,x1,x1,x0,x0], [0,0,25,25,0], /DEVICE, COLOR=self.black
   TV, color_bar, 1, 1
   XYOUTS, x0, 32, STRTRIM(min_dat, 2), /DEVICE, ALIGNMENT=0.0, $
      COLOR=self.black, FONT=0
   XYOUTS, cx, 32, STRTRIM(mid_dat, 2), /DEVICE, ALIGNMENT=0.5, $
      COLOR=self.black, FONT=0
   XYOUTS, x1, 32, STRTRIM(max_dat, 2), /DEVICE, ALIGNMENT=1.0, $
      COLOR=self.black, FONT=0

   field_name = (*self.field_names_ptr)[self.curr_field] + ',  ' + $
                 STRTRIM(self.curr_image, 2)
   XYOUTS,  2, 48, field_name, /DEVICE, ALIGNMENT=0.0, $
      COLOR=self.black, FONT=0

   EMPTY
END


; Event handler for swath gridding parameter input.
;
PRO NSIDC_DIST_GRID_PARAM_EVENT, event
   WIDGET_CONTROL, event.top, GET_UVALUE=state_ptr
   uname = WIDGET_INFO(event.id, /UNAME)

   WIDGET_CONTROL, (*state_ptr).mid_lon_text, GET_VALUE=mid_lon
   mid_lon = FLOAT(mid_lon[0])
   WIDGET_CONTROL, (*state_ptr).mid_lat_text, GET_VALUE=mid_lat
   mid_lat = FLOAT(mid_lat[0])

   WIDGET_CONTROL, (*state_ptr).min_lon_text, GET_VALUE=min_lon
   min_lon = FLOAT(min_lon[0])
   WIDGET_CONTROL, (*state_ptr).min_lat_text, GET_VALUE=min_lat
   min_lat = FLOAT(min_lat[0])

   WIDGET_CONTROL, (*state_ptr).max_lon_text, GET_VALUE=max_lon
   max_lon = FLOAT(max_lon[0])
   WIDGET_CONTROL, (*state_ptr).max_lat_text, GET_VALUE=max_lat
   max_lat = FLOAT(max_lat[0])

   WIDGET_CONTROL, (*state_ptr).x_text, GET_VALUE=grid_x
   grid_x = LONG(grid_x[0]) > 32L
   WIDGET_CONTROL, (*state_ptr).x_text, SET_VALUE=STRING(grid_x)
   WIDGET_CONTROL, (*state_ptr).y_text, GET_VALUE=grid_y
   grid_y = LONG(grid_y[0]) > 32L
   WIDGET_CONTROL, (*state_ptr).y_text, SET_VALUE=STRING(grid_y)

   (*state_ptr).mid_lon = mid_lon
   (*state_ptr).mid_lat = mid_lat

   (*state_ptr).min_lon = min_lon
   (*state_ptr).min_lat = min_lat

   (*state_ptr).max_lon = max_lon
   (*state_ptr).max_lat = max_lat

   (*state_ptr).grid_x = grid_x
   (*state_ptr).grid_y = grid_y

   IF (mid_lat GE ( 89.0)) THEN BEGIN
      mid_lat = ( 90.0)
      mid_lon = 0.0
      min_lon = (-180.0)
      max_lon = ( 180.0)
   ENDIF
   IF (mid_lat LE (-89.0)) THEN BEGIN
      mid_lat = (-90.0)
      mid_lon = 0.0
      min_lon = (-180.0)
      max_lon = ( 180.0)
   ENDIF

   WIDGET_CONTROL, (*state_ptr).mid_lon_text, SET_VALUE=STRING(mid_lon)
   WIDGET_CONTROL, (*state_ptr).mid_lat_text, SET_VALUE=STRING(mid_lat)
   WIDGET_CONTROL, (*state_ptr).min_lon_text, SET_VALUE=STRING(min_lon)
   WIDGET_CONTROL, (*state_ptr).min_lat_text, SET_VALUE=STRING(min_lat)
   WIDGET_CONTROL, (*state_ptr).max_lon_text, SET_VALUE=STRING(max_lon)
   WIDGET_CONTROL, (*state_ptr).max_lat_text, SET_VALUE=STRING(max_lat)

   CASE uname OF
      'ok_bttn': BEGIN
         (*state_ptr).status = 1B
         WIDGET_CONTROL, event.top, /DESTROY
      END
      'cancel_bttn': BEGIN
         (*state_ptr).status = 0B
         WIDGET_CONTROL, event.top, /DESTROY
      END
   ELSE:
   ENDCASE
END


; Event handler for brightness/contrast input.
;
PRO NSIDC_DIST_GRID_BC_EVENT, event
   WIDGET_CONTROL, event.top, GET_UVALUE=bc_state_ptr
   uname = WIDGET_INFO(event.id, /UNAME)

   CASE UNAME OF
      'min_text': BEGIN
         WIDGET_CONTROL, (*bc_state_ptr).min_text, GET_VALUE=min_str
         min_val = FLOAT(min_str[0])
         WIDGET_CONTROL, (*bc_state_ptr).min_text, SET_VALUE=STRING(min_val)
      END
      'max_text': BEGIN
         WIDGET_CONTROL, (*bc_state_ptr).max_text, GET_VALUE=max_str
         max_val = FLOAT(max_str[0])
         WIDGET_CONTROL, (*bc_state_ptr).max_text, SET_VALUE=STRING(max_val)
      END
      'auto_bttn': BEGIN
         WIDGET_CONTROL, (*bc_state_ptr).min_text, $
            SET_VALUE=STRING((*bc_state_ptr).min_dat)
         WIDGET_CONTROL, (*bc_state_ptr).max_text, $
            SET_VALUE=STRING((*bc_state_ptr).max_dat)
      END
      'ok_bttn': BEGIN
         WIDGET_CONTROL, (*bc_state_ptr).min_text, GET_VALUE=min_str
         min_val = FLOAT(min_str[0])

         WIDGET_CONTROL, (*bc_state_ptr).max_text, GET_VALUE=max_str
         max_val = FLOAT(max_str[0])

         IF (min_val GT max_val) THEN BEGIN
            temp = min_val
            min_val = max_val
            max_val = min_val
         ENDIF
         IF (min_val GE max_val) THEN max_val = max_val + 1.0

         WIDGET_CONTROL, (*bc_state_ptr).min_text, SET_VALUE=STRING(min_val)
         WIDGET_CONTROL, (*bc_state_ptr).max_text, SET_VALUE=STRING(max_val)

         (*bc_state_ptr).curr_min_dat = min_val
         (*bc_state_ptr).curr_max_dat = max_val

         (*bc_state_ptr).status = 1B
         WIDGET_CONTROL, event.top, /DESTROY
      END
      'cancel_bttn': BEGIN
         (*bc_state_ptr).status = 0B
         WIDGET_CONTROL, event.top, /DESTROY
      END
   ELSE:
   ENDCASE
END


; Event handler for roi box position dialog.
;
PRO NSIDC_DIST_GRID_BOX_EVENT, event
   WIDGET_CONTROL, event.top, GET_UVALUE=box_type_state
   box_type_state.grid_obj -> BOX_EVENT, event, box_type_state
END
PRO NSIDC_DIST_GRID::BOX_EVENT, event, box_type_state
   WIDGET_CONTROL, /HOURGLASS
   uname = WIDGET_INFO(event.id, /UNAME)

   CASE uname OF
      'apply_bttn': BEGIN ; Apply new roi box coordinates.
         WIDGET_CONTROL, box_type_state.ul_lon_text, GET_VALUE=ul_lon
         WIDGET_CONTROL, box_type_state.ul_lat_text, GET_VALUE=ul_lat
         WIDGET_CONTROL, box_type_state.lr_lon_text, GET_VALUE=lr_lon
         WIDGET_CONTROL, box_type_state.lr_lat_text, GET_VALUE=lr_lat

         IF (STRTRIM(ul_lon[0], 2) EQ '') THEN RETURN
         IF (STRTRIM(ul_lat[0], 2) EQ '') THEN RETURN
         IF (STRTRIM(lr_lon[0], 2) EQ '') THEN RETURN
         IF (STRTRIM(lr_lat[0], 2) EQ '') THEN RETURN

         ul_lon_f = (FLOAT(ul_lon[0]) > (-180.0)) < ( 180.0)
         ul_lat_f = (FLOAT(ul_lat[0]) > ( -90.0)) < (  90.0)
         lr_lon_f = (FLOAT(lr_lon[0]) > (-180.0)) < ( 180.0)
         lr_lat_f = (FLOAT(lr_lat[0]) > ( -90.0)) < (  90.0)

         ; Set up the map projection.
         IF (self.swath) THEN bounds = self.bounds[0:3] ELSE bounds = self.bounds
         IF (self.center[0] LT 0.0) THEN map_ang = 0.0 ELSE map_ang = 0.0
         MAP_SET, self.center[0], self.center[1], map_ang, /LAMBERT, /NOBORDER, $
            XMARGIN=[0,0], YMARGIN=[0,0], LIMIT=bounds, /NOERASE

         ; Check to ensure the values entered are within the grid bounds.

         ; Convert to grid normalized coordinates,
         ; and enforce that they are within the grid bounds.
         ul_grid = ((CONVERT_COORD(ul_lon_f, ul_lat_f, /DATA, /TO_NORMAL))[0:1] > 0.0) < 1.0
         lr_grid = ((CONVERT_COORD(lr_lon_f, lr_lat_f, /DATA, /TO_NORMAL))[0:1] > 0.0) < 1.0

         ; Get all 4 corners in grid coordinates.
         l = ul_grid[0] < lr_grid[0]
         r = ul_grid[0] > lr_grid[0]
         b = ul_grid[1] < lr_grid[1]
         t = ul_grid[1] > lr_grid[1]

         ; Convert back to lon-lat.
         ul_ll = (CONVERT_COORD(l, t, /NORMAL, /TO_DATA))[0:1]
         lr_ll = (CONVERT_COORD(r, b, /NORMAL, /TO_DATA))[0:1]

         ; Upper left & lower right corners.
         ul_lon_f = ul_ll[0]
         ul_lat_f = ul_ll[1]
         lr_lon_f = lr_ll[0]
         lr_lat_f = lr_ll[1]

         ; Convert the normalized grid coordinates to actual grid coordinates (grid indices).
         ul_grid[0] = (ROUND(ul_grid[0] * FLOAT(self.dim_x-1)) > 0L) < (self.dim_x - 1L)
         ul_grid[1] = (ROUND(ul_grid[1] * FLOAT(self.dim_y-1)) > 0L) < (self.dim_y - 1L)
         lr_grid[0] = (ROUND(lr_grid[0] * FLOAT(self.dim_x-1)) > 0L) < (self.dim_x - 1L)
         lr_grid[1] = (ROUND(lr_grid[1] * FLOAT(self.dim_y-1)) > 0L) < (self.dim_y - 1L)
         box_pts = [ul_grid[0]<lr_grid[0], ul_grid[1]<lr_grid[1], $
                    ul_grid[0]>lr_grid[0], ul_grid[1]>lr_grid[1]]

         ; Get the approximate width & height in meters.
         self -> CALC_WH, box_pts, w, h

         ; Put the QA'd values back in the text widgets.
         WIDGET_CONTROL, box_type_state.ul_lon_text, SET_VALUE=STRING(ul_lon_f)
         WIDGET_CONTROL, box_type_state.ul_lat_text, SET_VALUE=STRING(ul_lat_f)
         WIDGET_CONTROL, box_type_state.lr_lon_text, SET_VALUE=STRING(lr_lon_f)
         WIDGET_CONTROL, box_type_state.lr_lat_text, SET_VALUE=STRING(lr_lat_f)

         WIDGET_CONTROL, box_type_state.w_text, SET_VALUE=STRING(w)
         WIDGET_CONTROL, box_type_state.h_text, SET_VALUE=STRING(h)

         zoomed = 0
         IF (self.curr_box LT 0) THEN BEGIN ; Make a new box.
            self -> SET_BOX_PTS, box_pts, 0
            ; Put the same new box on other linked windows.
            self -> UPDATE_LINKED, /NEW_BOX
         ENDIF ELSE BEGIN ; Modify an existing box.
            PTR_FREE, self.box_copy_ptr
            self.box_copy_ptr = PTR_NEW(*self.box_pts_ptr)
            (*self.box_pts_ptr)[*,self.curr_box] = TEMPORARY(box_pts)
            ; Modify the corresponding box on other linked windows.
            self -> UPDATE_LINKED, ZOOMED=zoomed
         ENDELSE

         ; If this box matches the grid's zoom box, then zoom image,
         ; else refresh.
         IF (zoomed) THEN self -> DRAW ELSE self -> DRAW_UPDATE
      END
      'close_bttn': BEGIN
         WIDGET_CONTROL, event.top, /DESTROY
      END
   ELSE:
   ENDCASE
END


; Grid object event handler.
;
PRO NSIDC_DIST_GRID_EVENT, event
   WIDGET_CONTROL, event.handler, GET_UVALUE=grid_obj
   grid_obj -> EVENT, event
END
PRO NSIDC_DIST_GRID::EVENT, event

   uname = WIDGET_INFO(event.id, /UNAME)
   IF (uname NE 'grid_draw') THEN WIDGET_CONTROL, /HOURGLASS

   CASE uname OF
      'file_close_bttn': BEGIN ; Quit.
         WIDGET_CONTROL, event.top, /DESTROY
      END
      'file_tiff_bttn': BEGIN ; Save tiff image.
         self.main_obj -> GET_FP, fp
         tiff_file = DIALOG_PICKFILE(FILTER='*.tif', /WRITE, $
            DIALOG_PARENT=event.top, TITLE='Select Tiff File To Write', $
            PATH=fp)
         IF (tiff_file EQ '') THEN RETURN ; User cancelled.
         ind = STRPOS(tiff_file, '.tif')
         IF (ind LE 0L) THEN tiff_file = tiff_file + '.tif'
         ff = FINDFILE(tiff_file)
         IF (ff[0] NE '') THEN BEGIN
            ans = DIALOG_MESSAGE(['File exists.   Overwrite '+ff[0]], $
                     DIALOG_PARENT=event.top, /QUESTION)
            IF (ans NE 'Yes') THEN RETURN
         ENDIF
         WIDGET_CONTROL, /HOURGLASS
         WSET, self.grid_wind
         TVLCT, self.r, self.g, self.b
         self -> DRAW
         img = TVRD(TRUE=1)
         IF WIDGET_INFO(self.legend_draw, /VALID_ID) THEN BEGIN ; Include legend.
            self -> DRAW_LEGEND
            leg_img = TVRD(TRUE=1)

            new_img = BYTARR(3, self.win_x, self.win_y+64, /NOZERO)
            new_img[0,0,0] = TEMPORARY(leg_img)
            new_img[0,0,64] = TEMPORARY(img)
            img = TEMPORARY(new_img)

            WSET, self.grid_wind
         ENDIF

         img = REVERSE(TEMPORARY(img), 3)
         WRITE_TIFF, tiff_file, TEMPORARY(img)
      END
      'file_meta_bttn': BEGIN ; Display HDF file meta data.
          temp_file = 'nsidc_dist_temp.txt'
          self.file_obj -> GET_HDF_FILE, hdf_file
          HDF_INFO, hdf_file, OUTFILE=temp_file
          XDISPLAYFILE, temp_file, FONT='courier*8', GROUP=self.file_base, $
             HEIGHT=24, WIDTH=80, TITLE=('Metadata: ' + hdf_file)
      END

      'img_bright_bttn': BEGIN ; Put up the image brightness/contrast controls.
         ; Get current min & max vales.
         curr_min_dat = FLOAT((*self.min_dat_ptr)[self.curr_field])
         curr_max_dat = FLOAT((*self.max_dat_ptr)[self.curr_field])

         ; Get true data min & max values.

         data_ptrs = *self.data_ptr_ptr
         CASE self.interleave OF
            (-1): grid_data = (*(data_ptrs[self.curr_field]))
            ( 0): grid_data = (*(data_ptrs[self.curr_field]))[self.curr_image,*,*]
            ( 1): grid_data = (*(data_ptrs[self.curr_field]))[*,self.curr_image,*]
            ( 2): grid_data = (*(data_ptrs[self.curr_field]))[*,*,self.curr_image]
         ENDCASE

         fill_val = (*self.fill_val_ptr)[self.curr_field]
         data_index = WHERE((grid_data NE fill_val) AND (grid_data NE 0.0))
         min_dat = fill_val
         max_dat = fill_val
         IF (data_index[0] GE 0L) THEN min_dat = MIN(grid_data[data_index], MAX=max_dat)
         min_dat = FLOAT(min_dat)
         max_dat = FLOAT(max_dat)
         IF ((min_dat GT 0.0) AND (min_dat LE 1.0)) THEN min_dat = 0.0
         IF (max_dat LE min_dat) THEN max_dat = min_dat + 1.0

         ; Build widgets.

         bc_base = WIDGET_BASE(TITLE='Enter Min/Max Scaling values', /COLUMN, $
                      GROUP_LEADER=event.top, FLOATING=event.top, /MODAL)
         mm_base = WIDGET_BASE(bc_base, ROW=2, /GRID)
         wid = WIDGET_LABEL(mm_base, VALUE='Data Min:')
         min_text = WIDGET_TEXT(mm_base, VALUE=STRING(curr_min_dat), /EDITABLE, $
                       /FRAME, UNAME='min_text')
         wid = WIDGET_LABEL(mm_base, VALUE='Data Max:')
         max_text = WIDGET_TEXT(mm_base, VALUE=STRING(curr_max_dat), /EDITABLE, $
                       /FRAME, UNAME='max_text')

         auto_bttn = WIDGET_BUTTON(bc_base, VALUE='Auto Adjust', UNAME='auto_bttn')

         bttn_base = WIDGET_BASE(bc_base, COLUMN=2, /GRID)
         ok_bttn = WIDGET_BUTTON(bttn_base, VALUE='Ok', UNAME='ok_bttn')
         cancel_bttn = WIDGET_BUTTON(bttn_base, VALUE='Cancel', UNAME='cancel_bttn')

         ; Brightness/contrast state.
         bc_state = {status:0, min_text:min_text, max_text:max_text, $
                     curr_min_dat:curr_min_dat, curr_max_dat:curr_max_dat, $
                     min_dat:min_dat, max_dat:max_dat}
         bc_state_ptr = PTR_NEW(TEMPORARY(bc_state))

         ; Start event processing.
         WIDGET_CONTROL, bc_base, SET_UVALUE=bc_state_ptr
         WIDGET_CONTROL, bc_base, /REALIZE
         XMANAGER, 'NSIDC_DIST_GRID_BC', bc_base
         ; Execution pauses here until brightness/contrast controls are destroyed.

         WIDGET_CONTROL, /HOURGLASS

         bc_state = TEMPORARY(*bc_state_ptr)
         PTR_FREE, bc_state_ptr

         IF (bc_state.status) THEN BEGIN ; Apply new thresholds.
            (*self.min_dat_ptr)[self.curr_field] = bc_state.curr_min_dat
            (*self.max_dat_ptr)[self.curr_field] = bc_state.curr_max_dat

            self -> DRAW
            self -> DRAW_LEGEND
         ENDIF
      END
      'img_palette_bttn': BEGIN ; Change color palette.
         TVLCT, self.r, self.g, self.b
         XLOADCT, GROUP=event.top, /MODAL, /SILENT, /USE_CURRENT, NCOLORS=248
         WIDGET_CONTROL, /HOURGLASS
         TVLCT, r, g, b, /GET
         self.r = r
         self.g = g
         self.b = b
         self -> DRAW
         self -> DRAW_LEGEND
      END
      'img_coast_bttn': BEGIN ; Hide/show coastlines.
         IF (self.show_coast EQ 0B) THEN BEGIN
            self.show_coast = 1B
            WIDGET_CONTROL, self.img_coast_bttn, SET_VALUE='Hide Coastlines'
         ENDIF ELSE BEGIN
            self.show_coast = 0B
            WIDGET_CONTROL, self.img_coast_bttn, SET_VALUE='Show Coastlines'
         ENDELSE
         self -> DRAW
      END
      'img_grat_bttn': BEGIN ; Hide/show graticule.
         IF (self.show_grat EQ 0B) THEN BEGIN
            self.show_grat = 1B
            WIDGET_CONTROL, self.img_grat_bttn, SET_VALUE='Hide Graticule'
         ENDIF ELSE BEGIN
            self.show_grat = 0B
            WIDGET_CONTROL, self.img_grat_bttn, SET_VALUE='Show Graticule'
         ENDELSE
         self -> DRAW
      END
      'img_clcol_bttn': BEGIN ; Coastline color.
         NSIDC_DIST_GET_COLOR, self.coast_color, event.top
         WIDGET_CONTROL, /HOURGLASS
         TVLCT, r, g, b, /GET
         self.r = r
         self.g = g
         self.b = b
         self -> DRAW
      END
      'img_gtcol_bttn': BEGIN ; Graticule color.
         NSIDC_DIST_GET_COLOR, self.grat_color, event.top
         WIDGET_CONTROL, /HOURGLASS
         TVLCT, r, g, b, /GET
         self.r = r
         self.g = g
         self.b = b
         self -> DRAW
      END
      'img_legend_bttn': BEGIN ; Hide/show legend.

         IF (self.show_legend EQ 0B) THEN BEGIN ; Show it.
            self.show_legend = 1B
            WIDGET_CONTROL, self.img_legend_bttn, SET_VALUE='Hide Legend'
            WIDGET_CONTROL, self.grid_base, UPDATE=0
            self.legend_draw = WIDGET_DRAW(self.legend_base, UNAME='img_legend_draw', $
                                  XSIZE=self.win_x, YSIZE=64)
            WIDGET_CONTROL, self.grid_base, UPDATE=1
            WIDGET_CONTROL, self.legend_draw, GET_VALUE=legend_wind
            self.legend_wind = legend_wind

            self -> DRAW_LEGEND
         ENDIF ELSE BEGIN ; Hide it.
            self.show_legend = 0B
            WIDGET_CONTROL, self.img_legend_bttn, SET_VALUE='Show Legend'
            WIDGET_CONTROL, self.grid_base, UPDATE=0
            WIDGET_CONTROL, self.legend_draw, /DESTROY
            WIDGET_CONTROL, self.grid_base, UPDATE=1
         ENDELSE

         ; Save new size of top-level base.
         base_geom = WIDGET_INFO(self.grid_base, /GEOMETRY)
         self.base_geom = [base_geom.scr_xsize, base_geom.scr_ysize]
      END

      'win_link_bttn': BEGIN ; Set flag for all compatible windows to link.
         self.main_obj -> SET_LINK_FLAG, 1B
      END
      'win_unlink_bttn': BEGIN ; Set flag for all compatible windows to unlink.
         self.main_obj -> SET_LINK_FLAG, 0B
      END
      'win_replicate_bttn': BEGIN
         ; Replicate window (create another identical grid object).
         ; Create new grid object with all the same parameters.
         ; Note the use of the "Parent"keyword.
         new_grid_obj = OBJ_NEW('NSIDC_DIST_GRID', self.main_obj, self.file_obj, $
            self.grid_id, self.grid_name, *(self.field_names_ptr), $
            *(self.orig_dims_ptr), SWATH=self.swath, STRIDE=self.stride, PARENT=self, $
            WIN_SIZE=[self.win_x,self.win_y], ZOOM_BOX=self.zoom_box, $
            SHOW_GRAT=self.show_grat, SHOW_COAST=self.show_coast, $
            R=self.r, G=self.g, B=self.b)
         IF (self.curr_box GE 0) THEN BEGIN
            new_grid_obj -> SET_BOX_PTS, (*self.box_pts_ptr), self.curr_box
            new_grid_obj -> DRAW_BOXES
         ENDIF

         IF OBJ_VALID(new_grid_obj) THEN BEGIN
            self.container -> ADD, new_grid_obj
            self.file_container -> ADD, new_grid_obj
            self.main_container -> ADD, new_grid_obj
            ; If any of the above containers are destroyed,
            ; then the new grid object will also be destroyed.
         ENDIF
      END

      'roi_type_bttn': BEGIN ; Bring up the roi box position dialog.

         ; Determine the initial values.
         w = 0.0
         h = 0.0
         IF (self.curr_box GE 0) THEN BEGIN
            box_pts = (*self.box_pts_ptr)[*,self.curr_box]
            self -> CALC_WH, box_pts, w, h
            box_pts = FLOAT(box_pts) / FLOAT([self.dim_x,self.dim_y,self.dim_x,self.dim_y]-1)
            lr = (CONVERT_COORD(box_pts[2], box_pts[1], /NORMAL, /TO_DATA))[0:1]
            ul = (CONVERT_COORD(box_pts[0], box_pts[3], /NORMAL, /TO_DATA))[0:1]
            ul_lon = STRING(ul[0])
            ul_lat = STRING(ul[1])
            lr_lon = STRING(lr[0])
            lr_lat = STRING(lr[1])
         ENDIF ELSE BEGIN
            ul_lon = ''
            ul_lat = ''
            lr_lon = ''
            lr_lat = ''
         ENDELSE

         ; Build widgets.

         box_base = WIDGET_BASE(TITLE='Box Coordinates', /COLUMN, $
                       GROUP_LEADER=self.grid_base, FLOATING=self.grid_base)

         ll_base = WIDGET_BASE(box_base, ROW=5, /GRID)

         ul_lon_text = WIDGET_TEXT(ll_base, VALUE=ul_lon, XSIZE=16, /FRAME, /EDITABLE, $
                           UNAME='ul_lon_text')
         wid = WIDGET_LABEL(ll_base, VALUE='Upper Left Lon')

         ul_lat_text = WIDGET_TEXT(ll_base, VALUE=ul_lat, XSIZE=16, /FRAME, /EDITABLE, $
                           UNAME='ul_lat_text')
         wid = WIDGET_LABEL(ll_base, VALUE='Upper Left Lat')

         wid = WIDGET_LABEL(ll_base, VALUE=' ')
         wid = WIDGET_LABEL(ll_base, VALUE=' ')

         lr_lon_text = WIDGET_TEXT(ll_base, VALUE=lr_lon, XSIZE=16, /FRAME, /EDITABLE, $
                           UNAME='lr_lon_text')
         wid = WIDGET_LABEL(ll_base, VALUE='Lower Right Lon')

         lr_lat_text = WIDGET_TEXT(ll_base, VALUE=lr_lat, XSIZE=16, /FRAME, /EDITABLE, $
                           UNAME='lr_lat_text')
         wid = WIDGET_LABEL(ll_base, VALUE='Lower Right Lat')

         wid = WIDGET_LABEL(box_base, VALUE=' ')

         wh_base = WIDGET_BASE(box_base, ROW=2, /GRID)
         w_text = WIDGET_TEXT(wh_base, VALUE=STRING(w), XSIZE=16)
         wid = WIDGET_LABEL(wh_base, VALUE='Approx. Width (KM)')
         h_text = WIDGET_TEXT(wh_base, VALUE=STRING(h), XSIZE=16)
         wid = WIDGET_LABEL(wh_base, VALUE='Approx. Height (KM)')

         bttn_base = WIDGET_BASE(box_base, COLUMN=2, /GRID)
         apply_bttn = WIDGET_BUTTON(bttn_base, VALUE='Apply', UNAME='apply_bttn')
         close_bttn = WIDGET_BUTTON(bttn_base, VALUE='Close', UNAME='close_bttn')

         self.box_base = box_base

         box_type_state = {ul_lon_text:ul_lon_text, ul_lat_text:ul_lat_text, $
                           lr_lon_text:lr_lon_text, lr_lat_text:lr_lat_text, $
                           w_text:w_text, h_text:h_text, grid_obj:self}
         WIDGET_CONTROL, box_base, SET_UVALUE=box_type_state
         WIDGET_CONTROL, box_base, /REALIZE

         ; Start event pocessing.
         XMANAGER, 'NSIDC_DIST_GRID_BOX', box_base
         ; Execution continues here immediately.

      END
      'roi_new_bttn': BEGIN ; Zoom roi box to a new window (grid object).
         IF (self.curr_box GE 0) THEN BEGIN
            CASE self.interleave OF
               (-1): dims = [self.dim_x, self.dim_y]
               ( 0): dims = [self.n_images, self.dim_x, self.dim_y]
               ( 1): dims = [self.dim_x, self.n_images, self.dim_y]
               ( 2): dims = [self.dim_x, self.dim_y, self.n_images]
            ENDCASE
            ; Create new grid object with all the same parameters.
            ; Note the use of the "Parent" and "Zoom_Box" keywords.
            new_grid_obj = OBJ_NEW('NSIDC_DIST_GRID', self.main_obj, self.file_obj, $
               self.grid_id, self.grid_name, *(self.field_names_ptr), $
               *(self.orig_dims_ptr), SWATH=self.swath, STRIDE=self.stride, $
               PARENT=self, WIN_SIZE=[340,340], $
               ZOOM_BOX=(*self.box_pts_ptr)[*,self.curr_box], $
               SHOW_GRAT=self.show_grat, SHOW_COAST=self.show_coast, $
               R=self.r, G=self.g, B=self.b)
            ; Put all the current roi boxes on the new grid object.
            new_grid_obj -> SET_BOX_PTS, (*self.box_pts_ptr)[*,self.curr_box], 0
            new_grid_obj -> DRAW_BOXES

            IF OBJ_VALID(new_grid_obj) THEN BEGIN
               self.container -> ADD, new_grid_obj
               self.file_container -> ADD, new_grid_obj
               self.main_container -> ADD, new_grid_obj
               ; If any of the above containers are destroyed,
               ; then the new grid object will also be destroyed.
            ENDIF
         ENDIF
      END
      'roi_curr_bttn': BEGIN ; Zoom to roi box in current window.
         IF (self.curr_box GE 0) THEN BEGIN
            self.zoom_box = (*self.box_pts_ptr)[*,self.curr_box]
            self -> DRAW
            self -> DRAW_LEGEND
         ENDIF
      END
      'roi_one_bttn': BEGIN ; Zoom 1:1.
         ; Determine center point for zoom.
         IF (self.curr_box GE 0) THEN BEGIN ; Use the center of the current box.
            box_pts = (*self.box_pts_ptr)[*,self.curr_box]
            cp_x = (box_pts[0] + box_pts[2]) / 2
            cp_y = (box_pts[1] + box_pts[3]) / 2
         ENDIF ELSE BEGIN ; Use the center of the window.
            box_pts = self.zoom_box
            cp_x = (box_pts[0] + box_pts[2]) / 2
            cp_y = (box_pts[1] + box_pts[3]) / 2
            IF ((cp_x EQ 0) OR (cp_y EQ 0)) THEN BEGIN
               ; No zoom box, so use the center of the grid.
               cp_x = self.dim_x / 2
               cp_y = self.dim_y / 2
            ENDIF
         ENDELSE
         x0 = cp_x - (self.win_x / 2)
         x1 = cp_x + (self.win_x / 2)
         y0 = cp_y - (self.win_y / 2)
         y1 = cp_y + (self.win_y / 2)
         IF (x0 LT 0) THEN BEGIN
            x1 = x1 - x0
            x0 = 0
         ENDIF
         IF (x1 GE self.dim_x) THEN BEGIN
            x0 = x0 - (x1 - (self.dim_x - 1))
            x1 = self.dim_x - 1
         ENDIF
         IF (y0 LT 0) THEN BEGIN
            y1 = y1 - y0
            y0 = 0
         ENDIF
         IF (y1 GE self.dim_y) THEN BEGIN
            y0 = y0 - (y1 - (self.dim_y - 1))
            y1 = self.dim_y - 1
         ENDIF

         self.zoom_box = [x0,y0,x1,y1]
         self -> DRAW
         self -> DRAW_LEGEND
      END
      'roi_fit_bttn': BEGIN ; Zoom to fit in window.
         self.zoom_box[*] = 0
         self -> DRAW
         self -> DRAW_LEGEND
      END
      'roi_hide_bttn': BEGIN ; Hide roi box handles.
         IF (self.show_handle EQ 0B) THEN BEGIN
            self.show_handle = 1B
            WIDGET_CONTROL, self.roi_hide_bttn, SET_VALUE='Hide Box Handles'
         ENDIF ELSE BEGIN
            self.show_handle = 0B
            WIDGET_CONTROL, self.roi_hide_bttn, SET_VALUE='Show Box Handles'
         ENDELSE
         self -> DRAW_UPDATE
      END
      'roi_colo_bttn': BEGIN ; Roi box color.
         NSIDC_DIST_GET_COLOR, self.box_color, event.top
         WIDGET_CONTROL, /HOURGLASS
         TVLCT, r, g, b, /GET
         self.r = r
         self.g = g
         self.b = b
         self -> DRAW_BOXES
         self -> DRAW_LEGEND
      END
      'roi_table_bttn': BEGIN ; Display a data table of values in box.
         IF (self.curr_box GE 0) THEN BEGIN

            ; Get image data in box.

            box_pts = (*self.box_pts_ptr)[*,self.curr_box]
            x0 = box_pts[0] > 0
            x1 = box_pts[2] < (self.dim_x - 1)
            y0 = box_pts[1] > 0
            y1 = box_pts[3] < (self.dim_y - 1)
            data_ptrs = *self.data_ptr_ptr
            CASE self.interleave OF
               (-1): data = (*(data_ptrs[self.curr_field]))[x0:x1,y0:y1]
               ( 0): data = (*(data_ptrs[self.curr_field]))[self.curr_image,x0:x1,y0:y1]
               ( 1): data = (*(data_ptrs[self.curr_field]))[x0:x1,self.curr_image,y0:y1]
               ( 2): data = (*(data_ptrs[self.curr_field]))[x0:x1,y0:y1,self.curr_image]
            ENDCASE
            data = REFORM(data, /OVERWRITE)
            field_name = (*(self.field_names_ptr))[self.curr_field]

            ; Resotre map projection for this object.
            IF (self.center[0] LT 0.0) THEN map_ang = 0.0 ELSE map_ang = 0.0
            IF (self.swath) THEN bounds = self.bounds[0:3] ELSE bounds = self.bounds
            MAP_SET, self.center[0], self.center[1], map_ang, /LAMBERT, /NOBORDER, $
                  XMARGIN=[0,0], YMARGIN=[0,0], LIMIT=bounds, /NOERASE

            ; Create new table object.
            table_obj = OBJ_NEW('NSIDC_DIST_TABLE', $
               self.main_obj, self.file_obj, self, $
               TEMPORARY(data), box_pts, self.grid_name, field_name, $
               self.curr_image)
            IF OBJ_VALID(table_obj) THEN BEGIN
               ;self.container -> ADD, new_grid_obj
               self.file_container -> ADD, table_obj
               self.main_container -> ADD, table_obj
               ; If any of the above containers are destroyed,
               ; then the table object will also be destroyed.
            ENDIF
         ENDIF
      END
      'roi_delete_bttn': BEGIN ; Delete the current roi box.
         IF (self.curr_box GE 0) THEN BEGIN
            box_pts = (*self.box_pts_ptr)
            delete_pts = box_pts[*,self.curr_box]
            n_boxes = N_ELEMENTS(box_pts) / 4L
            IF (n_boxes EQ 1L) THEN BEGIN ; Delete the only box.
               PTR_FREE, self.box_pts_ptr
               self.curr_box = (-1)
            ENDIF ELSE BEGIN ; Delete one box, leave the others.
               ramp = INDGEN(n_boxes)
               index = WHERE(ramp NE self.curr_box)
               box_pts = REFORM(box_pts[*,index])
               self -> SET_BOX_PTS, box_pts, (N_ELEMENTS(box_pts) / 4L) - 1L
            ENDELSE

            ; Delete any windows associated with this box.
            grid_objects = self.container -> GET(/ALL, ISA='NSIDC_DIST_GRID', COUNT=n_windows)
            FOR i=0, n_windows-1 DO BEGIN
               grid_objects[i] -> GET_ZOOM_BOX, zoom_box
               IF (MAX(ABS(delete_pts - zoom_box)) LE 0) THEN BEGIN
                  self.container -> REMOVE, grid_objects[i]
                  self.file_container -> REMOVE, grid_objects[i]
                  self.main_container -> REMOVE, grid_objects[i]
                  OBJ_DESTROY, grid_objects[i]
               ENDIF
            ENDFOR

            self -> DRAW_UPDATE
         ENDIF
         self -> UPDATE_BOX_TEXT ;Update text in roi box position dialog.
      END

      'help_use_bttn': BEGIN ; Help (program usage).
         ri = ROUTINE_INFO('NSIDC_DIST_GRID__DEFINE', /SOURCE)
         sp = STRPOS(STRUPCASE(ri.path), 'NSIDC_DIST_GRID_DEFINE')
         help_file = STRMID(ri.path, 0, sp) + 'nsidc_dist_use.txt'
         XDISPLAYFILE, help_file, GROUP=event.top, WIDTH=80, HEIGHT=24
      END
      'help_version_bttn': BEGIN ; Help (software version).
         ri = ROUTINE_INFO('NSIDC_DIST_GRID__DEFINE', /SOURCE)
         sp = STRPOS(STRUPCASE(ri.path), 'NSIDC_DIST_GRID_DEFINE')
         help_file = STRMID(ri.path, 0, sp) + 'nsidc_dist_ver.txt'
         XDISPLAYFILE, help_file, GROUP=event.top, WIDTH=80, HEIGHT=24
      END

      'grid_base': BEGIN ; Resize.
         WIDGET_CONTROL, self.grid_base, UPDATE=0

         ; Compute new draw widget size(s).

         event.x = (event.x + 8) > 256
         event.y = (event.y + 46) > 128
         inc_x = event.x - self.base_geom[0]
         inc_y = event.y - self.base_geom[1]
         self.win_x = self.win_x + inc_x
         self.win_y = self.win_y + inc_y
         WIDGET_CONTROL, self.grid_draw, /DESTROY
         self.grid_draw = WIDGET_DRAW(self.draw_base, XSIZE=self.win_x, YSIZE=self.win_y, $
                            /BUTTON_EVENTS, /MOTION_EVENTS, UNAME='grid_draw')

         IF WIDGET_INFO(self.legend_draw, /VALID_ID) THEN BEGIN ; Resize legend too.
            WIDGET_CONTROL, self.legend_draw, /DESTROY
            self.legend_draw = WIDGET_DRAW(self.legend_base, UNAME='img_legend_draw', $
                                  XSIZE=self.win_x, YSIZE=64)
         ENDIF

         WIDGET_CONTROL, self.grid_base, UPDATE=1
         WIDGET_CONTROL, self.grid_draw, GET_VALUE=grid_wind
         self.grid_wind = grid_wind
         IF WIDGET_INFO(self.legend_draw, /VALID_ID) THEN BEGIN ; Redraw legend too.
            WIDGET_CONTROL, self.legend_draw, GET_VALUE=legend_wind
            self.legend_wind = legend_wind
            self -> DRAW_LEGEND
         ENDIF

         ; Save new top-level base size.
         base_geom = WIDGET_INFO(self.grid_base, /GEOMETRY)
         self.base_geom = [base_geom.scr_xsize, base_geom.scr_ysize]

         ; Resize backing-store pixmap.
         WDELETE, self.grid_pix
         WINDOW, /FREE, /PIXMAP, XSIZE=self.win_x, YSIZE=self.win_y
         self.grid_pix = !D.WINDOW

         self -> DRAW ; Redraw image.
      END
      'field_drop': BEGIN ; Display a different field.
         self.curr_field = event.index
         self -> DRAW
         self -> DRAW_LEGEND
      END
      'image_drop': BEGIN ; Display a different image.
         self.curr_image = event.index
         self -> DRAW
         self -> DRAW_LEGEND
      END
      'grid_draw': BEGIN ; Event in main draw window.
         IF (event.release GT 0) THEN WIDGET_CONTROL, /HOURGLASS

         IF (event.press GT 0) THEN self.button_down = event.press

         ; Restore window and map projection of this object.
         WSET, self.grid_wind
         !P.T = self.t3d
         IF (self.center[0] LT 0.0) THEN map_ang = 0.0 ELSE map_ang = 0.0
         IF (self.swath) THEN bounds = self.bounds[0:3] ELSE bounds = self.bounds
         MAP_SET, self.center[0], self.center[1], map_ang, /LAMBERT, /NOBORDER, $
                  XMARGIN=[0,0], YMARGIN=[0,0], LIMIT=bounds, /NOERASE

         ; Update position readout.

         xy_norm = FLOAT([event.x,event.y]) / FLOAT([self.win_x,self.win_y]-1)
         xy_norm = ([xy_norm[0],xy_norm[1],0.0,1.0] # INVERT(!P.T))[0:1]
         xy_imag = (ROUND(xy_norm * FLOAT([self.dim_x,self.dim_y])-1) < $
                      (([self.dim_x,self.dim_y]) - 1L)) > 0L
         x = xy_imag[0]
         y = xy_imag[1]

         data_ptrs = *self.data_ptr_ptr
         CASE self.interleave OF
            (-1): data_pt = (*(data_ptrs[self.curr_field]))[x,y]
            ( 0): data_pt = (*(data_ptrs[self.curr_field]))[self.curr_image,x,y]
            ( 1): data_pt = (*(data_ptrs[self.curr_field]))[x,self.curr_image,y]
            ( 2): data_pt = (*(data_ptrs[self.curr_field]))[x,y,self.curr_image]
         ENDCASE

         ll = (CONVERT_COORD(xy_norm[0], xy_norm[1], /NORMAL, /TO_DATA))[0:1]
         IF (SIZE(data_pt, /TYPE) EQ 1L) THEN data_pt = FIX(data_pt) ; Convert byte to int.
         pt = STRING(ll[0],format='(f10.5)') + ', ' + STRING(ll[1],format='(f9.5)') + ', ' + STRING(data_pt)
         WIDGET_CONTROL, self.pos_text, SET_VALUE=pt

         IF (self.button_down EQ 0B) THEN RETURN ; No button down, so done.

         ; Manipulate zoom box.

         IF (event.press GT 0) THEN BEGIN
            self.first_point = xy_imag
            PTR_FREE, self.box_copy_ptr
         ENDIF

         x = [self.first_point[0],xy_imag[0],xy_imag[0],$
              self.first_point[0],self.first_point[0]]
         y = [self.first_point[1],self.first_point[1],$
              xy_imag[1],xy_imag[1],self.first_point[1]]

         IF (self.button_down EQ 1B) THEN BEGIN ; New box rubber-banding.
            DEVICE, COPY=[0,0,self.win_x,self.win_y,0,0,self.grid_pix]
            self -> DRAW_BOXES

            IF ((x[0] NE x[2]) AND (y[0] NE y[2])) THEN $
               PLOTS, x/FLOAT(self.dim_x-1), y/FLOAT(self.dim_y-1), $
                  /NORMAL, /T3D, COLOR=self.box_color

            EMPTY
         ENDIF ELSE BEGIN ; Manipulate existing box.
            IF (self.curr_box GE 0) THEN BEGIN
               box_pts = TEMPORARY(*self.box_pts_ptr)
               n_boxes = N_ELEMENTS(box_pts) / 4L
               IF (event.press GT 1) THEN BEGIN ; Find closest box corner or center.
                  mx = (box_pts[0,*] + box_pts[2,*]) / 2
                  my = (box_pts[1,*] + box_pts[3,*]) / 2
                  cx = [REFORM(box_pts[0,*]), REFORM(box_pts[2,*]), $
                        REFORM(box_pts[2,*]), REFORM(box_pts[0,*])]
                  cy = [REFORM(box_pts[1,*]), REFORM(box_pts[1,*]), $
                        REFORM(box_pts[3,*]), REFORM(box_pts[3,*])]
                  min_mxy = MIN(SQRT((mx - xy_imag[0])^2 + (my - xy_imag[1])^2), min_mxy_index)
                  min_cxy = MIN(SQRT((cx - xy_imag[0])^2 + (cy - xy_imag[1])^2), min_cxy_index)
                  close_box_pts = box_pts[*, min_mxy_index]
                  IF (((xy_imag[0] GE close_box_pts[0]) AND (xy_imag[0] LE close_box_pts[2])) AND $
                      ((xy_imag[1] GE close_box_pts[1]) AND (xy_imag[1] LE close_box_pts[3]))) THEN BEGIN
                     ; Select box.
                     self.curr_box = min_mxy_index
                     self.box_mod = (-1)
                  ENDIF
                  IF (min_mxy LE min_cxy) THEN BEGIN ; Move box.
                     IF (min_mxy LE 6) THEN BEGIN
                        self.box_corner_mod = (-1)
                        self.box_mod = min_mxy_index
                        self.curr_box = self.box_mod
                        self.box_copy_ptr = PTR_NEW(box_pts)
                     ENDIF
                  ENDIF ELSE BEGIN ; Move corner.
                     IF (min_cxy LE 6) THEN BEGIN
                        self.box_corner_mod = min_cxy_index / n_boxes
                        self.box_mod = min_cxy_index MOD n_boxes
                        self.curr_box = self.box_mod
                        self.box_copy_ptr = PTR_NEW(box_pts)
                     ENDIF
                  ENDELSE
               ENDIF ELSE BEGIN ; Keep moving it.
                  IF (self.box_mod GE 0) THEN BEGIN
                     curr_pts = box_pts[*,self.box_mod]
                     CASE (self.box_corner_mod) OF
                        (-1): BEGIN
                           cx = (curr_pts[0] + curr_pts[2]) / 2
                           cy = (curr_pts[1] + curr_pts[3]) / 2
                           curr_pts = curr_pts - [cx,cy,cx,cy]
                           curr_pts = curr_pts + [xy_imag[*], xy_imag[*]]
                        END
                        ( 0): BEGIN
                           curr_pts[0] = xy_imag[0]
                           curr_pts[1] = xy_imag[1]
                        END
                        ( 1): BEGIN
                           curr_pts[2] = xy_imag[0]
                           curr_pts[1] = xy_imag[1]
                        END
                        ( 2): BEGIN
                           curr_pts[2] = xy_imag[0]
                           curr_pts[3] = xy_imag[1]
                        END
                        ( 3): BEGIN
                           curr_pts[0] = xy_imag[0]
                           curr_pts[3] = xy_imag[1]
                        END
                     ENDCASE

                     box_pts[*,self.box_mod] = curr_pts
                  ENDIF
               ENDELSE

               ; Cleanup & re-arrange points.

               IF (self.curr_box GE 0) THEN BEGIN
                  curr_pts = box_pts[*,self.curr_box]
                  copy_curr_pts = curr_pts
                  IF (curr_pts[0] GT curr_pts[2]) THEN BEGIN
                     curr_pts[0] = copy_curr_pts[2]
                     curr_pts[2] = copy_curr_pts[0]
                  ENDIF
                  IF (curr_pts[1] GT curr_pts[3]) THEN BEGIN
                     curr_pts[1] = copy_curr_pts[3]
                     curr_pts[3] = copy_curr_pts[1]
                  ENDIF
                  cx = (curr_pts[0] + curr_pts[2]) / 2
                  cy = (curr_pts[1] + curr_pts[3]) / 2
                  IF (curr_pts[2]-curr_pts[0] LE 2) THEN BEGIN
                     curr_pts[0] = cx - 1
                     curr_pts[2] = cx + 1
                  ENDIF
                  IF (curr_pts[3]-curr_pts[1] LE 2) THEN BEGIN
                     curr_pts[1] = cy - 1
                     curr_pts[3] = cy + 1
                  ENDIF
                  IF (curr_pts[0] LT 0) THEN curr_pts[[0,2]] = curr_pts[[0,2]] - curr_pts[0]
                  IF (curr_pts[1] LT 0) THEN curr_pts[[1,3]] = curr_pts[[1,3]] - curr_pts[1]
                  IF (curr_pts[2] GE self.dim_x) THEN $
                     curr_pts[[0,2]] = curr_pts[[0,2]] - (1 + curr_pts[2] - self.dim_x)
                  IF (curr_pts[3] GE self.dim_y) THEN $
                     curr_pts[[1,3]] = curr_pts[[1,3]] - (1 + curr_pts[3] - self.dim_y)

                  box_pts[*,self.curr_box] = curr_pts
               ENDIF

               *self.box_pts_ptr = TEMPORARY(box_pts) ; Store new box points.

               ; Draw boxes.
               DEVICE, COPY=[0,0,self.win_x,self.win_y,0,0,self.grid_pix]
               self -> DRAW_BOXES
            ENDIF
         ENDELSE

         ; Sort (lower left first, then upper right).
         xpos = [x[0]<x[2],x[0]>x[2]]
         ypos = [y[0]<y[2],y[0]>y[2]]
         xpos = (xpos > 0L) < (self.dim_x-1L)
         ypos = (ypos > 0L) < (self.dim_y-1L)

         IF (event.release EQ 1) THEN BEGIN ; Make a new box.
            IF ((xpos[0] LT (xpos[1]-1)) AND (ypos[0] LT (ypos[1]-1))) THEN BEGIN
               IF (self.curr_box LT 0) THEN BEGIN ; No existing boxes.
                  self -> SET_BOX_PTS, [xpos[0],ypos[0],xpos[1],ypos[1]], 0
               ENDIF ELSE BEGIN ; Add to list of existing boxes.
                  box_pts = TEMPORARY(*self.box_pts_ptr)
                  n_boxes = N_ELEMENTS(box_pts) / 4L
                  new_box_pts = FLTARR(4L, n_boxes+1L)
                  new_box_pts[0,0] = TEMPORARY(box_pts)
                  new_box_pts[0,n_boxes] = [xpos[0],ypos[0],xpos[1],ypos[1]]
                  self -> SET_BOX_PTS, new_box_pts, n_boxes
               ENDELSE
               ; Draw new box.
               DEVICE, COPY=[0,0,self.win_x,self.win_y,0,0,self.grid_pix]
               self -> DRAW_BOXES
            ENDIF
         ENDIF

         IF (event.release GT 0) THEN BEGIN ; Finished - clean up.
            self.button_down = 0B
            self.box_mod = (-1)

            ; Update box coordinates in coordinate window.
            self -> UPDATE_BOX_TEXT
            ; Update corresponding box in other linked windows.
            self -> UPDATE_LINKED, NEW_BOX=(event.release EQ 1), ZOOMED=zoomed
            IF (zoomed) THEN BEGIN ; Zoom box moved - redraw.
               self -> DRAW
               self -> DRAW_LEGEND
            ENDIF
         ENDIF
      END

   ELSE:
   ENDCASE
END


; Method to calculate approximate width & height (in meters),
; given an roi box in grid coordinates.
;
PRO NSIDC_DIST_GRID::CALC_WH, box_pts, w, h
   ; Restore object's map projection.
   IF (self.center[0] LT 0.0) THEN map_ang = 0.0 ELSE map_ang = 0.0
   IF (self.swath) THEN bounds = self.bounds[0:3] ELSE bounds = self.bounds
   MAP_SET, self.center[0], self.center[1], map_ang, /LAMBERT, /NOBORDER, $
            XMARGIN=[0,0], YMARGIN=[0,0], LIMIT=bounds, /NOERASE

   n_box_pts = FLOAT(box_pts) / FLOAT([self.dim_x,self.dim_y,self.dim_x,self.dim_y]-1)
   lr = (CONVERT_COORD(n_box_pts[2], n_box_pts[1], /NORMAL, /TO_DATA))[0:1]
   ul = (CONVERT_COORD(n_box_pts[0], n_box_pts[3], /NORMAL, /TO_DATA))[0:1]
   ll = (CONVERT_COORD(n_box_pts[0], n_box_pts[1], /NORMAL, /TO_DATA))[0:1]
   ur = (CONVERT_COORD(n_box_pts[2], n_box_pts[3], /NORMAL, /TO_DATA))[0:1]
   top_d = (MAP_2POINTS(ul[0], ul[1], ur[0], ur[1], /METERS))[0] / 1000.0
   bot_d = (MAP_2POINTS(ll[0], ll[1], lr[0], lr[1], /METERS))[0] / 1000.0
   lft_d = (MAP_2POINTS(ul[0], ul[1], ll[0], ll[1], /METERS))[0] / 1000.0
   rht_d = (MAP_2POINTS(ur[0], ur[1], lr[0], lr[1], /METERS))[0] / 1000.0

   w = (top_d + bot_d) / 2.0
   h = (lft_d + rht_d) / 2.0
END


; Get grid object's top-level base.
;
PRO NSIDC_DIST_GRID::GET_BASE, grid_base
   grid_base = self.grid_base
END


; Get container.
;
PRO NSIDC_DIST_GRID::GET_CONTAINER, grid_container
   grid_container = self.container
END


; Get data pointers.
;
PRO NSIDC_DIST_GRID::GET_PTRS, data_ptr_ptr, min_dat_ptr, max_dat_ptr
   data_ptr_ptr = self.data_ptr_ptr
   min_dat_ptr = self.min_dat_ptr
   max_dat_ptr = self.max_dat_ptr
END

; Get map projection parameters.
;
PRO NSIDC_DIST_GRID::GET_PROJ, bounds, center, swath
   bounds = self.bounds
   IF (self.swath) THEN bounds = bounds[0:3]
   center = self.center
   swath = self.swath
END

; Get current field index and image index.
;
PRO NSIDC_DIST_GRID::GET_CURR, curr_field, curr_image
   curr_field = self.curr_field
   curr_image = self.curr_image
END

; Get grid dimensions.
;
PRO NSIDC_DIST_GRID::GET_DIMS, dim_x, dim_y
   dim_x = self.dim_x
   dim_y = self.dim_y
END

; Get & set zoom box position.
;
PRO NSIDC_DIST_GRID::GET_ZOOM_BOX, zoom_box
   zoom_box = self.zoom_box
END
PRO NSIDC_DIST_GRID::SET_ZOOM_BOX, zoom_box
   self.zoom_box = zoom_box
END

; Get & set roi box points.
;
FUNCTION NSIDC_DIST_GRID::GET_BOX_PTS, box_pts, curr_box
   IF (self.curr_box LT 0) THEN RETURN, 0
   box_pts = *self.box_pts_ptr
   curr_box = self.curr_box
   RETURN, 1
END
PRO NSIDC_DIST_GRID::SET_BOX_PTS, box_pts, curr_box
   box_pts[0] = box_pts[0] > 0
   box_pts[1] = box_pts[1] > 0
   box_pts[2] = box_pts[2] < (self.dim_x - 1)
   box_pts[3] = box_pts[3] < (self.dim_y - 1)

   PTR_FREE, self.box_pts_ptr
   self.box_pts_ptr = PTR_NEW(box_pts)

   ; Store an extra copy, used for detecting when
   ; any of the roi box points have changed.
   PTR_FREE, self.box_copy_ptr
   self.box_copy_ptr = PTR_NEW(box_pts)

   self.curr_box = curr_box
END

PRO NSIDC_DIST_GRID::UPDATE_BOX_TEXT ; Update the text in the roi box position dialog.
   IF WIDGET_INFO(self.box_base, /VALID_ID) THEN BEGIN
      IF (self.curr_box GE 0) THEN BEGIN
         box_pts = (*self.box_pts_ptr)[*,self.curr_box]
         self -> CALC_WH, box_pts, w, h
         box_pts = FLOAT(box_pts) / FLOAT([self.dim_x,self.dim_y,self.dim_x,self.dim_y]-1)
         lr = (CONVERT_COORD(box_pts[2], box_pts[1], /NORMAL, /TO_DATA))[0:1]
         ul = (CONVERT_COORD(box_pts[0], box_pts[3], /NORMAL, /TO_DATA))[0:1]
         ul_lon = STRING(ul[0])
         ul_lat = STRING(ul[1])
         lr_lon = STRING(lr[0])
         lr_lat = STRING(lr[1])
      ENDIF ELSE BEGIN
         ul_lon = ''
         ul_lat = ''
         lr_lon = ''
         lr_lat = ''
         w = 0.0
         h = 0.0
      ENDELSE
      WIDGET_CONTROL, self.box_base, GET_UVALUE=box_type_state
      WIDGET_CONTROL, box_type_state.ul_lon_text, SET_VALUE=ul_lon
      WIDGET_CONTROL, box_type_state.ul_lat_text, SET_VALUE=ul_lat
      WIDGET_CONTROL, box_type_state.lr_lon_text, SET_VALUE=lr_lon
      WIDGET_CONTROL, box_type_state.lr_lat_text, SET_VALUE=lr_lat
      WIDGET_CONTROL, box_type_state.w_text, SET_VALUE=STRING(w)
      WIDGET_CONTROL, box_type_state.h_text, SET_VALUE=STRING(h)
   ENDIF
END


; Update all compatible linked windows.
;
PRO NSIDC_DIST_GRID::UPDATE_LINKED, NEW_BOX=new_box, ZOOMED=zoomed
   ; Zoom this box ?
   zoomed = 0
   IF (NOT(KEYWORD_SET(new_box)) AND (self.curr_box GE 0)) THEN BEGIN
      IF PTR_VALID(self.box_copy_ptr) THEN BEGIN
         box_copy_pts = (*self.box_copy_ptr)[*,self.curr_box]
         IF (MAX(ABS(box_copy_pts - self.zoom_box)) LE 0) THEN BEGIN
            self.zoom_box = (*self.box_pts_ptr)[*,self.curr_box]
            zoomed = 1 ; Yes, zoom this box (later).
            ; Note that "zoomed" is returned to the caller via a keyword.
         ENDIF
      ENDIF
   ENDIF

   ; Get other grid objects.
   grid_objects = self.main_container -> GET(/ALL, ISA='NSIDC_DIST_GRID', COUNT=n_windows)

   IF (((self.main_obj -> GET_LINK_FLAG()) AND (n_windows GT 1L)) AND $
      (PTR_VALID(self.box_pts_ptr))) THEN BEGIN
      ; Linking is "on", there are other grid objects, and there is an active
      ; roi box in this object.   So check other grid objets for matching roi boxes.
      ; If any matching roi boxes are found, update them to match this object's
      ; current roi box.
      box_pts = (*self.box_pts_ptr)[*,self.curr_box]
      IF PTR_VALID(self.box_copy_ptr) THEN $
         box_copy_pts = (*self.box_copy_ptr)[*,self.curr_box] $
      ELSE $
         box_copy_pts = (*self.box_pts_ptr)[*,self.curr_box]

      ; Convert to lon-lat.

      box_pts = FLOAT(box_pts) / FLOAT([self.dim_x,self.dim_y,self.dim_x,self.dim_y]-1)
      ul = (CONVERT_COORD(box_pts[0], box_pts[3], /NORMAL, /TO_DATA))[0:1]
      lr = (CONVERT_COORD(box_pts[2], box_pts[1], /NORMAL, /TO_DATA))[0:1]

      box_copy_pts = FLOAT(box_copy_pts) / FLOAT([self.dim_x,self.dim_y,self.dim_x,self.dim_y]-1)
      ul_copy = (CONVERT_COORD(box_copy_pts[0], box_copy_pts[3], /NORMAL, /TO_DATA))[0:1]
      lr_copy = (CONVERT_COORD(box_copy_pts[2], box_copy_pts[1], /NORMAL, /TO_DATA))[0:1]

      FOR i=0, n_windows-1 DO BEGIN ; Loop through the other grid objects.
         IF (OBJ_VALID(grid_objects[i]) AND (grid_objects[i] NE self)) THEN BEGIN
            ; Valid grid object found, and it is not the same as self.

            ; Check for matching projection in the other grid object.
            grid_objects[i] -> GET_PROJ, bounds, center, swath
            IF ((self.center[0] EQ center[0]) AND $
                (self.center[1] EQ center[1])) THEN BEGIN ; Matching projection center.

               grid_objects[i] -> GET_DIMS, other_dim_x, other_dim_y

               ; Active map projection of the other grid object.
               IF (center[0] LT 0.0) THEN map_ang = 0.0 ELSE map_ang = 0.0
               MAP_SET, center[0], center[1], map_ang, /LAMBERT, /NOBORDER, $
                  XMARGIN=[0,0], YMARGIN=[0,0], LIMIT=bounds, /NOERASE

               ; Convert coordinates.

               new_ul = (CONVERT_COORD(ul[0], ul[1], /DATA, /TO_NORMAL) * $
                           FLOAT([other_dim_x,other_dim_y]-1))[0:1]
               new_lr = (CONVERT_COORD(lr[0], lr[1], /DATA, /TO_NORMAL) * $
                           FLOAT([other_dim_x,other_dim_y]-1))[0:1]
               new_box_pts = FIX([new_ul[0]<new_lr[0], new_ul[1]<new_lr[1], $
                                  new_ul[0]>new_lr[0], new_ul[1]>new_lr[1]])

               new_ul_copy = (CONVERT_COORD(ul_copy[0], ul_copy[1], /DATA, /TO_NORMAL) * $
                                FLOAT([other_dim_x,other_dim_y]-1))[0:1]
               new_lr_copy = (CONVERT_COORD(lr_copy[0], lr_copy[1], /DATA, /TO_NORMAL) * $
                                FLOAT([other_dim_x,other_dim_y]-1))[0:1]
               new_box_pts_copy = FIX([new_ul_copy[0]<new_lr_copy[0], $
                                       new_ul_copy[1]<new_lr_copy[1], $
                                       new_ul_copy[0]>new_lr_copy[0], $
                                       new_ul_copy[1]>new_lr_copy[1]])

               IF KEYWORD_SET(new_box) THEN BEGIN ; New zoom box.
                  IF (((new_ul[0] GE 0) AND (new_lr[0] LT other_dim_x)) AND $
                      ((new_ul[1] LT other_dim_y) AND (new_lr[1] GE 0))) THEN BEGIN

                     ; Ok to add new box to other window.

                     status = grid_objects[i] -> GET_BOX_PTS(other_box_pts, curr_box)
                     IF (status) THEN BEGIN ; Existing points.
                        other_box_pts = [other_box_pts[*], new_box_pts[*]]
                        other_box_pts = REFORM(other_box_pts, 4, N_ELEMENTS(other_box_pts)/4L)
                        grid_objects[i] -> SET_BOX_PTS, other_box_pts, curr_box+1
                        grid_objects[i] -> UPDATE_BOX_TEXT
                     ENDIF ELSE BEGIN ; No existing points.
                        grid_objects[i] -> SET_BOX_PTS, new_box_pts, 0
                        grid_objects[i] -> UPDATE_BOX_TEXT
                     ENDELSE

                     grid_objects[i] -> DRAW_UPDATE
                  ENDIF
               ENDIF ELSE BEGIN ; Modified zoom box.
                  status = grid_objects[i] -> GET_BOX_PTS(other_box_pts, curr_box)
                  IF (status) THEN BEGIN ; Existing points.
                     win_zoom = 0
                     FOR j=0, (N_ELEMENTS(other_box_pts)/4L)-1L DO BEGIN
                        check_pts = other_box_pts[*,j]
                        IF (MAX(ABS(new_box_pts_copy - check_pts)) LE 2) THEN BEGIN
                           ; Matching box
                           other_box_pts[*,j] = new_box_pts
                           grid_objects[i] -> GET_ZOOM_BOX, zoom_box
                           IF (MAX(ABS(zoom_box - check_pts)) LE 0) THEN BEGIN
                              ; Zoom other window
                              grid_objects[i] -> SET_ZOOM_BOX, new_box_pts
                              win_zoom = 1
                           ENDIF
                           ; Update the other gird object's roi box position dialog.
                           grid_objects[i] -> SET_BOX_PTS, other_box_pts, j
                           grid_objects[i] -> UPDATE_BOX_TEXT
                        ENDIF
                     ENDFOR

                     IF (win_zoom) THEN BEGIN ; Redraw the other grid object.
                        grid_objects[i] -> DRAW
                        grid_objects[i] -> DRAW_LEGEND
                     ENDIF ELSE BEGIN ; Refresh the other grid object.
                        grid_objects[i] -> DRAW_UPDATE
                     ENDELSE

                  ENDIF
               ENDELSE
            ENDIF
         ENDIF
      ENDFOR
   ENDIF
END


; Grid object cleanup.
;
PRO NSIDC_DIST_GRID_KILL, grid_base
   WIDGET_CONTROL, grid_base, GET_UVALUE=grid_obj
   OBJ_DESTROY, grid_obj
END
PRO NSIDC_DIST_GRID::CLEANUP
   IF (WIDGET_INFO(self.grid_base, /VALID_ID)) THEN $
      WIDGET_CONTROL, self.grid_base, /DESTROY

   WDELETE, self.grid_pix
   IF (OBJ_VALID(self.main_container)) THEN self.main_container -> REMOVE, self
   IF (OBJ_VALID(self.file_container)) THEN self.file_container -> REMOVE, self
   PTR_FREE, self.field_names_ptr
   PTR_FREE, self.fill_val_ptr
   PTR_FREE, self.box_pts_ptr
   PTR_FREE, self.box_copy_ptr
   PTR_FREE, self.orig_dims_ptr
   IF NOT(OBJ_VALID(self.parent)) THEN BEGIN
      data_ptrs = *self.data_ptr_ptr
      PTR_FREE, data_ptrs
      PTR_FREE, self.data_ptr_ptr
      PTR_FREE, self.min_dat_ptr
      PTR_FREE, self.max_dat_ptr
   ENDIF ELSE BEGIN
      self.parent -> GET_CONTAINER, grid_container
      grid_container -> REMOVE, self
   ENDELSE
   OBJ_DESTROY, self.container
END


; Grid object definition.
;
PRO NSIDC_DIST_GRID__DEFINE

   struct = {NSIDC_DIST_GRID, $
             main_obj:OBJ_NEW(), $			; Main object.
             file_obj:OBJ_NEW(), $			; File object.
             main_container:OBJ_NEW(), $	; Main object's container.
             file_container:OBJ_NEW(), $	; File object's container.
             container:OBJ_NEW(), $			; This object's container.
             parent:OBJ_NEW(), $			; Parent grid object (for sharing data with).
             main_base:0L, $				; Top-level base of main object.
             file_base:0L, $				; Main base of file object.
             grid_base:0L, $				; Top-level base of this grid object.
             draw_base:0L, $				; Base for holding image draw widget.
             grid_draw:0L, $				; Main image draw widget.
             grid_wind:0L, $				; Main image window ID.
             grid_pix:0L, $					; Backing store pixmap ID.
             legend_base:0L, $				; Base for holding legend draw widget.
             legend_draw:0L, $				; Legend draw widget.
             legend_wind:0L, $				; Legend window ID.
             pos_text:0L, $					; Dynamic position readout text widget.
             box_base:0L, $					; Top-level widget base ID of roi box position dialog.
             dim_x:0, $						; Grid X dimension.
             dim_y:0, $						; Grid Y dimension.
             orig_dims_ptr:PTR_NEW(), $		; Pointer to original INIT method dims parameter.
             interleave:0, $				; Image interleaving flag.
             stride:[0,0,0], $				; HDF field read, stride value.
             curr_field:0, $				; Currently displayed field.
             curr_image:0, $				; Currently displayed image index.
             n_images:0, $					; Total number of images in this field.
             win_x:0, $						; Main draw widget X dimension.
             win_y:0, $						; Main draw widget Y dimension.
             swath:0B, $					; Swath flag.
             grid_id:0L, $					; HDF grid ID.
             grid_name:'', $				; HDF grid name.
             field_names_ptr:PTR_NEW(), $	; Pointer to a list of HDF field names.
             n_fields:0L, $					; Total number of fields.
             fill_val_ptr:PTR_NEW(), $		; Pointer to a list of fill values (for each field).
             data_ptr_ptr:PTR_NEW(), $		; Pointer to a list of data pointers (for each field).
             min_dat_ptr:PTR_NEW(), $		; Pointer to a list of min data values (for each field).
             max_dat_ptr:PTR_NEW(), $       ; Pointer to a list of max data values (for each field).
             bounds:FLTARR(8), $			; Map projection bounds.
             center:FLTARR(2), $			; Map projection center.
             t3d:FLTARR(4,4), $				; Scaling matrix for zooming.
             r:BYTARR(256), $				; Red color band.
             g:BYTARR(256), $				; Green color band.
             b:BYTARR(256), $				; Blue color band.
             max_img:0B, $					; Maximum color index for images.
             zoom_box:INTARR(4), $			; Zoom box position.
             box_pts_ptr:PTR_NEW(), $		; Pointer to list of roi box coordinates.
             box_copy_ptr:PTR_NEW(), $		; Pointer to copy of roi box coordinates.
             first_point:[0,0], $			; First point entered while dragging an roi box.
             curr_box:0, $					; The current roi box ID.
             box_mod:0, $					; Flag indicating which roi box was moved.
             box_corner_mod:0, $			; Flag indicating which roi box corner (or center) was moved.
             show_grat:0B, $				; Show graticule flag.
             show_coast:0B, $				; Show coastlines flag.
             show_handle:0B, $				; Show roi box handles flag.
             show_legend:0B, $				; Show legend flag.
             grat_color:0L, $				; Graticule color index.
             coast_color:0L, $				; Coastline color index.
             box_color:0L, $				; Roi box color.
             red:0, $						; Red annotation color index.
             green:0, $						; Green annotation color index.
             blue:0, $						; Blue annotation color index.
             black:0, $						; Black annotation color index.
             white:0, $						; White annotation color index.
             base_geom:[0,0], $				; Top-level base size (x,y).
             img_grat_bttn:0L, $			; Hide/show graticule button ID.
             img_coast_bttn:0L, $			; Hide/show coastline button ID.
             roi_hide_bttn:0L, $			; Hide/show roi box handles button ID.
             img_legend_bttn:0L, $			; Hide/show legend button ID.
             field_drop:0L, $				; Field selection droplist widget ID.
             image_drop:0L, $				; Image index selection droplist widget ID.
             button_down:0B}				; Mouse button down flag.
END
