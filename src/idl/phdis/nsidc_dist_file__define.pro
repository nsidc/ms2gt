; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; File object definition.

; Initialization.
;
FUNCTION NSIDC_DIST_FILE::INIT, main_obj, hdf_file

   ; General setup.

   main_obj -> GET_BASES, main_base, file_base, scroll_base
   main_obj -> GET_CONTAINER, main_container
   self.hdf_file = hdf_file
   self.file_base = file_base
   self.main_base = main_base
   self.main_container = main_container

   ; Get HDF file metadata.

   self.fid = EOS_GD_OPEN(self.hdf_file, /READ) ; Open the file.
   IF (self.fid LT 0L) THEN BEGIN
      ans = DIALOG_MESSAGE(['Invalid HDF-EOS file: ', hdf_file], $
               DIALOG_PARENT=main_base, /ERROR)
      RETURN, 0 ; Unable to Open.
   ENDIF
   status = EOS_EH_GETVERSION(self.fid, version) ; Get HDF-EOS version.

   self.n_grids = EOS_GD_INQGRID(self.hdf_file, grid_names)  ; Grids in file.
   self.n_swath = EOS_SW_INQSWATH(self.hdf_file, swath_names)  ; Swaths in file.

   IF ((self.n_grids LE 0L) AND (self.n_swath LE 0L)) THEN BEGIN
      ans = DIALOG_MESSAGE(['No grids or swaths found in file: ', hdf_file], $
               DIALOG_PARENT=main_base, /ERROR)
      status = EOS_GD_CLOSE(self.fid)
      RETURN, 0
   ENDIF

   grid_names = STRTRIM(STR_SEP(grid_names, ','), 2)
   swath_names = STRTRIM(STR_SEP(swath_names, ','), 2)

   ; Add a new sub-base to the main object's file holding base.

   WIDGET_CONTROL, self.file_base, UPDATE=1

   self.scroll_sub_base = WIDGET_BASE(scroll_base, /COLUMN, XPAD=1, YPAD=1, SPACE=1, $
      /FRAME, EVENT_PRO='NSIDC_DIST_FILE_EVENT', UVALUE=self, KILL_NOTIFY='NSIDC_DIST_FILE_KILL')
   wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=self.hdf_file, FONT='arial*16*bold')
   delete_bttn = WIDGET_BUTTON(self.scroll_sub_base, VALUE='Close the Above File', UNAME='delete_bttn')

   ; File base widgets.

   ;Grids.
   bad_grid_count = 0L
   FOR i=0L, self.n_grids-1L DO BEGIN
      grid_name = grid_names[i]
      grid_id = EOS_GD_ATTACH(self.fid, grid_name)
      status = EOS_GD_GRIDINFO(grid_id, xdim, ydim, up_left, low_right) ; Position info.
      status = EOS_GD_PROJINFO(grid_id, projcode, zonecode, spherecode, projparam) ; Projection info.
      center_lon = projparam[4] / 1.0D6
      center_lat = projparam[5] / 1.0D6
      status = EOS_GD_ORIGININFO(grid_id, origincode) ; Origin info.
      n_fields = EOS_GD_INQFIELDS(grid_id, field_names, frank, fnumbertype) ; Field info.
      field_names = STRTRIM(STR_SEP(field_names,','), 2)
      ul_ll = up_left
      lr_ll = low_right
      status_ul = NSIDC_DIST_GET_LATLON(ul_ll, projcode, projparam)
      status_lr = NSIDC_DIST_GET_LATLON(lr_ll, projcode, projparam)
      IF NOT(status_ul < status_lr) THEN BEGIN
         IF (bad_grid_count EQ 0L) THEN BEGIN
            ans = DIALOG_MESSAGE(['Unsupported grid projection found in file: ', hdf_file], $
                     DIALOG_PARENT=file_base, /ERROR)
         ENDIF
         bad_grid_count = bad_grid_count + 1L
      ENDIF ELSE BEGIN
         meta_text = 'Grid name: ' + grid_name
         wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)

         meta_text = 'Center position (lon,lat): ' + STRTRIM(center_lon, 2) + ', ' + STRTRIM(center_lat, 2)
         wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)

         meta_text = 'Upper left (lon,lat): ' + STRTRIM(ul_ll[0], 2) + ', ' + STRTRIM(ul_ll[1], 2)
         wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)
         meta_text = 'Lower right (lon,lat): ' + STRTRIM(lr_ll[0], 2) + ', ' + STRTRIM(lr_ll[1], 2)
         wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)

         meta_text = 'Upper left (false_east,false_north): ' + STRTRIM(up_left[0], 2) + ', ' + STRTRIM(up_left[1], 2)
         wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)
         meta_text = 'Lower right (false_east,false_north): ' + STRTRIM(low_right[0], 2) + ', ' + STRTRIM(low_right[1], 2)
         wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)

         table_values = STRARR(4, n_fields)
         FOR  j=0L, n_fields-1L DO BEGIN
            field_name = field_names[j]

            status = EOS_GD_COMPINFO(grid_id, field_name, compcode, compparam) ; Compression info
            status = EOS_GD_FIELDINFO(grid_id, field_name, rank, dims, numbertype, dimlist) ; Field info.
            status = EOS_GD_GETFILLVALUE(grid_id, field_name, fillvalue) ; Fill value.
            IF (status LT 0) THEN fillvalue='none'

            table_values[0,j] = STRTRIM(dims[0], 2)
            FOR k=1L, N_ELEMENTS(dims)-1L DO table_values[0,j] = table_values[0,j] + 'x' + STRTRIM(dims[k], 2)
            table_values[1,j] = STRTRIM(fillvalue, 2)
            table_values[2,j] = STRTRIM(rank, 2)
            table_values[3,j] = STRTRIM(compcode, 2)
         ENDFOR

         col_val_n = ['Field Name(s)', field_names]
         col_val_0 = ['Dim ', REFORM(table_values[0,*])]
         col_val_1 = ['Fill', REFORM(table_values[1,*])]
         col_val_2 = ['Rank', REFORM(table_values[2,*])]
         col_val_3 = ['Comp', REFORM(table_values[3,*])]

         col_n = STRING(REPLICATE(32B, MAX(STRLEN(col_val_n))))
         col_0 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_0))))
         col_1 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_1))))
         col_2 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_2))))
         col_3 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_3))))

         list_text = STRARR(n_fields+1)
         FOR j=0, n_fields DO BEGIN
            STRPUT, col_n, col_val_n[j], 0
            STRPUT, col_0, col_val_0[j], 0
            STRPUT, col_1, col_val_1[j], 0
            STRPUT, col_2, col_val_2[j], 0
            STRPUT, col_3, col_val_3[j], 0

            list_text[j] = col_n + ',  ' + col_0 + ',  ' + col_1 + ',  ' + $
                           col_2 + ',  ' + col_3

            STRPUT, col_n, STRING(REPLICATE(32B, STRLEN(col_n))), 0
            STRPUT, col_0, STRING(REPLICATE(32B, STRLEN(col_0))), 0
            STRPUT, col_1, STRING(REPLICATE(32B, STRLEN(col_1))), 0
            STRPUT, col_2, STRING(REPLICATE(32B, STRLEN(col_2))), 0
            STRPUT, col_3, STRING(REPLICATE(32B, STRLEN(col_3))), 0
         ENDFOR
         head_text = list_text[0]
         list_text = list_text[1:*]

         hold_base = WIDGET_BASE(self.scroll_sub_base, XPAD=1, YPAD=1, SPACE=1, /FRAME)
         wid = WIDGET_LABEL(hold_base, VALUE=head_text, $
                   FONT='courier*8', /ALIGN_LEFT, XOFFSET=2)
         uv = {grid_id:grid_id, grid_name:grid_name, field_names:field_names}
         grid_list = WIDGET_LIST(self.scroll_sub_base, YSIZE=n_fields, UNAME='grid_list', $
                        VALUE=list_text, UVALUE=TEMPORARY(uv), FONT='courier*8', /MULTIPLE)
         view_bttn = WIDGET_BUTTON(self.scroll_sub_base, $
            VALUE='Select field(s) from list above.   Then click here to view.', $
                        UNAME='view_grid_bttn', UVALUE=grid_list)
      ENDELSE
   ENDFOR

   ; Swaths.
   bad_swath_count = 0L
   FOR i=0L, self.n_swath-1L DO BEGIN
      swath_name = swath_names[i]
      swath_id = EOS_SW_ATTACH(self.fid, swath_name)

      n_fields = EOS_SW_INQDATAFIELDS(swath_id, field_names, rank, numbertype) ; Field info.
      field_names = STRTRIM(STR_SEP(field_names,','), 2)
      status = EOS_SW_INQGEOFIELDS(swath_id, geo_field_names, geo_rank, geo_numbertype)
      geo_field_names = STRTRIM(STR_SEP(geo_field_names,','), 2)
      status = EOS_SW_READFIELD(swath_id, geo_field_names[0], lat)
      status = EOS_SW_READFIELD(swath_id, geo_field_names[1], lon)

      sz_lat = SIZE(lat)
      min_lat0 = MIN(lat[*,0], MAX=max_lat0)
      min_lat1 = MIN(lat[*,sz_lat[2]-1], MAX=max_lat1)
      sz_lon = SIZE(lon)
      min_lon0 = MIN(lon[*,0], MAX=max_lon0)
      min_lon1 = MIN(lon[*,sz_lon[2]-1], MAX=max_lon1)
      lat = 0
      lon = 0

      meta_text = 'Swath name: ' + swath_name
      wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)

      meta_text = 'Swath start (min lat, max lat): ' + STRTRIM(min_lat0, 2) + ', ' + STRTRIM(max_lat0, 2)
      wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)
      meta_text = 'Swath start (min lon, max lon): ' + STRTRIM(min_lon0, 2) + ', ' + STRTRIM(max_lon0, 2)
      wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)

      meta_text = 'Swath end (min lat, max lat): ' + STRTRIM(min_lat1, 2) + ', ' + STRTRIM(max_lat1, 2)
      wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)
      meta_text = 'Swath end (min lon, max lon): ' + STRTRIM(min_lon1, 2) + ', ' + STRTRIM(max_lon1, 2)
      wid = WIDGET_LABEL(self.scroll_sub_base, VALUE=meta_text, /ALIGN_LEFT)

      table_values = STRARR(4, n_fields)
      FOR  j=0L, n_fields-1L DO BEGIN
         field_name = field_names[j]

         status = EOS_SW_COMPINFO(swath_id, field_name, compcode, compparam) ; Compression info
         status = EOS_SW_FIELDINFO(swath_id, field_name, rank, dims, numbertype, dimlist) ; Field info.
         status = EOS_SW_GETFILLVALUE(swath_id, field_name, fillvalue) ; Fill value.
         IF (status LT 0) THEN fillvalue='none'

         table_values[0,j] = STRTRIM(dims[0], 2)
         FOR k=1L, N_ELEMENTS(dims)-1L DO table_values[0,j] = table_values[0,j] + 'x' + STRTRIM(dims[k], 2)
         table_values[1,j] = STRTRIM(fillvalue, 2)
         table_values[2,j] = STRTRIM(rank, 2)
         table_values[3,j] = STRTRIM(compcode, 2)
      ENDFOR

      col_val_n = ['Field Name(s)', field_names]
      col_val_0 = ['Dim ', REFORM(table_values[0,*])]
      col_val_1 = ['Fill', REFORM(table_values[1,*])]
      col_val_2 = ['Rank', REFORM(table_values[2,*])]
      col_val_3 = ['Comp', REFORM(table_values[3,*])]

      col_n = STRING(REPLICATE(32B, MAX(STRLEN(col_val_n))))
      col_0 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_0))))
      col_1 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_1))))
      col_2 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_2))))
      col_3 = STRING(REPLICATE(32B, MAX(STRLEN(col_val_3))))

      list_text = STRARR(n_fields+1)
      FOR j=0, n_fields DO BEGIN
         STRPUT, col_n, col_val_n[j], 0
         STRPUT, col_0, col_val_0[j], 0
         STRPUT, col_1, col_val_1[j], 0
         STRPUT, col_2, col_val_2[j], 0
         STRPUT, col_3, col_val_3[j], 0

         list_text[j] = col_n + ',  ' + col_0 + ',  ' + col_1 + ',  ' + $
                        col_2 + ',  ' + col_3

         STRPUT, col_n, STRING(REPLICATE(32B, STRLEN(col_n))), 0
         STRPUT, col_0, STRING(REPLICATE(32B, STRLEN(col_0))), 0
         STRPUT, col_1, STRING(REPLICATE(32B, STRLEN(col_1))), 0
         STRPUT, col_2, STRING(REPLICATE(32B, STRLEN(col_2))), 0
         STRPUT, col_3, STRING(REPLICATE(32B, STRLEN(col_3))), 0
      ENDFOR
      head_text = list_text[0]
      list_text = list_text[1:*]

      hold_base = WIDGET_BASE(self.scroll_sub_base, XPAD=1, YPAD=1, SPACE=1, /FRAME)
      wid = WIDGET_LABEL(hold_base, VALUE=head_text, $
                FONT='courier*8', /ALIGN_LEFT, XOFFSET=2)
      uv = {swath_id:swath_id, swath_name:swath_name, field_names:field_names}
      swath_list = WIDGET_LIST(self.scroll_sub_base, YSIZE=n_fields, UNAME='swath_list', $
                     VALUE=list_text, UVALUE=TEMPORARY(uv), FONT='courier*8', /MULTIPLE)
      view_bttn = WIDGET_BUTTON(self.scroll_sub_base, $
         VALUE='Select field(s) from list above.   Then click here to view.', $
                     UNAME='view_swath_bttn', UVALUE=swath_list)
   ENDFOR

   IF ((bad_grid_count EQ self.n_grids) AND (bad_swath_count EQ self.n_swath)) THEN BEGIN
      ; No valid grids or swaths in file.
      WIDGET_CONTROL, self.scroll_sub_base, /DESTROY
      WIDGET_CONTROL, self.file_base, /UPDATE
      RETURN, 0
   ENDIF

   WIDGET_CONTROL, self.file_base, /UPDATE

   ; More general setup.

   self.container = OBJ_NEW('IDL_Container')

   self.main_obj = main_obj
   self.hdf_file = hdf_file

   self.main_base = main_base
   self.file_base = file_base
   self.scroll_base = scroll_base
   main_obj -> GET_CONTAINER, main_container
   self.main_container = main_container

   RETURN, 1
END


; Get important widget base IDs.
;
PRO NSIDC_DIST_FILE::GET_BASES, main_base, file_base
   main_base = self.main_base
   file_base = self.file_base
END


; Get container.
;
PRO NSIDC_DIST_FILE::GET_CONTAINER, file_container
   file_container = self.container
END


; Get HDF filename.
;
PRO NSIDC_DIST_FILE::GET_HDF_FILE, hdf_file
   hdf_file = self.hdf_file
END


; Event handler for file loading.
;
PRO NSIDC_DIST_FILE_LOAD_EVENT, event
   WIDGET_CONTROL, event.top, GET_UVALUE=load_state_ptr
   uname = WIDGET_INFO(event.id, /UNAME)

   ; Check stride value.
   WIDGET_CONTROL, (*load_state_ptr).stride_text, GET_VALUE=stride_str
   stride = FIX(stride_str) > 1
   WIDGET_CONTROL, (*load_state_ptr).stride_text, SET_VALUE=STRING(stride)
   (*load_state_ptr).stride = stride

   CASE uname OF
      'cancel_bttn': BEGIN
         (*load_state_ptr).status = 0
         WIDGET_CONTROL, event.top, /DESTROY
      END
      'ok_bttn': BEGIN
         (*load_state_ptr).status = 1
         WIDGET_CONTROL, event.top, /DESTROY
      END
   ELSE:
   ENDCASE
END


; Event handler for file base.
;
PRO NSIDC_DIST_FILE_EVENT, event
   WIDGET_CONTROL, event.handler, GET_UVALUE=file_obj
   file_obj -> EVENT, event
END
PRO NSIDC_DIST_FILE::EVENT, event

   WIDGET_CONTROL, /HOURGLASS
   uname = WIDGET_INFO(event.id, /UNAME)

   CASE uname OF
      'view_grid_bttn': BEGIN ; Display the selected grid field(s).
         WIDGET_CONTROL, event.id, GET_UVALUE=grid_list
         WIDGET_CONTROL, grid_list, GET_UVALUE=uv
         sel_fields = WIDGET_INFO(grid_list, /LIST_SELECT)
         IF (sel_fields[0] LT 0L) THEN RETURN ; No fields selected.

         ; Grid file load dialog widgets.

         dialog_base = WIDGET_BASE(TITLE='Load Data Field ?', /COLUMN, $
                          GROUP_LEADER=event.top, FLOATING=event.top, /MODAL)
         wid = WIDGET_LABEL(dialog_base, VALUE='Grid: '+uv.grid_name)
         wid = WIDGET_LABEL(dialog_base, VALUE='Field(s):')
         FOR i=0L, N_ELEMENTS(sel_fields)-1L DO $
            wid = WIDGET_LABEL(dialog_base, VALUE=uv.field_names[sel_fields[i]])
         stride_base = WIDGET_BASE(dialog_base, /ROW, /FRAME)
         wid = WIDGET_LABEL(stride_base, VALUE='Stride:')
         stride_text = WIDGET_TEXT(stride_base, VALUE=STRING(1), /EDITABLE, /FRAME, $
                          UNAME='stride_text')
         bttn_base = WIDGET_BASE(dialog_base, COLUMN=2, /GRID)
         ok_bttn = WIDGET_BUTTON(bttn_base, VALUE='Ok', UNAME='ok_bttn')
         cancel_bttn = WIDGET_BUTTON(bttn_base, VALUE='Cancel', UNAME='cancel_bttn')
         load_state = {status:0, stride_text:stride_text, stride:1}
         load_state_ptr = PTR_NEW(load_state)

         ; Start event processing for file load dialog.

         WIDGET_CONTROL, dialog_base, SET_UVALUE=load_state_ptr
         WIDGET_CONTROL, dialog_base, /REALIZE
         XMANAGER, 'NSIDC_DIST_FILE_LOAD', dialog_base
         ; Execution pauses here until dialog is closed.

         WIDGET_CONTROL, /HOURGLASS
         load_state = *load_state_ptr
         PTR_FREE, load_state_ptr

         IF (load_state.status NE 1) THEN RETURN ; User cancelled.
         stride = load_state.stride

         ; Create new grid or plot objects, depending upon data dimensions.

         FOR i=0L, N_ELEMENTS(sel_fields)-1L DO BEGIN
            field_name = uv.field_names[sel_fields[i]]
            status = EOS_GD_FIELDINFO(uv.grid_id, field_name, rank, dims, numbertype, dimlist)
            IF (N_ELEMENTS(dims) EQ 1L) THEN BEGIN ; 1D data, make a plot.
               plot_obj = OBJ_NEW('nsidc_dist_plot', self.main_obj, self, $
                             uv.grid_id, uv.grid_name, uv.field_names[sel_fields[i]], $
                             dims)
               IF OBJ_VALID(plot_obj) THEN BEGIN
                  self.container -> ADD, plot_obj
                  self.main_container -> ADD, plot_obj
                  ; If either of the above containers is destroyed,
                  ; then the plot object is also destroyed.
               ENDIF
            ENDIF
            IF (N_ELEMENTS(dims) EQ 3L) THEN BEGIN ; Multiple images in field, make a separate display.
               grid_obj = OBJ_NEW('nsidc_dist_grid', self.main_obj, self, $
                             uv.grid_id, uv.grid_name, field_name, dims, $
                             STRIDE=stride)
               IF OBJ_VALID(grid_obj) THEN BEGIN
                  self.container -> ADD, grid_obj
                  self.main_container -> ADD, grid_obj
                  ; If either of the above containers is destroyed,
                  ; then the grid object is also destroyed.
               ENDIF
            ENDIF
            IF (N_ELEMENTS(dims) EQ 2L) THEN BEGIN ; One or more 2D image fields, make a list.
               IF (N_ELEMENTS(field_names) LE 0L) THEN BEGIN
                  field_names = field_name
                  first_dims = dims
               ENDIF ELSE BEGIN
                  IF ((dims[0] EQ first_dims[0]) AND (dims[1] EQ first_dims[1])) THEN BEGIN
                     field_names = [TEMPORARY(field_names), field_name]
                  ENDIF ELSE BEGIN ; Image dimensions are different, make a new display.
                     grid_obj = OBJ_NEW('nsidc_dist_grid', self.main_obj, self, $
                                   uv.grid_id, uv.grid_name, TEMPORARY(field_names), $
                                   first_dims, STRIDE=stride)
                     IF OBJ_VALID(grid_obj) THEN BEGIN
                        self.container -> ADD, grid_obj
                        self.main_container -> ADD, grid_obj
                        ; If either of the above containers is destroyed,
                        ; then the grid object is also destroyed.
                     ENDIF

                     field_names = field_name
                     first_dims = dims
                  ENDELSE
               ENDELSE
            ENDIF
         ENDFOR
         IF (N_ELEMENTS(field_names) GT 0L) THEN BEGIN ; Make one display for all the 2D images.
            grid_obj = OBJ_NEW('nsidc_dist_grid', self.main_obj, self, $
                          uv.grid_id, uv.grid_name, TEMPORARY(field_names), $
                          first_dims, STRIDE=stride)
            IF OBJ_VALID(grid_obj) THEN BEGIN
               self.container -> ADD, grid_obj
               self.main_container -> ADD, grid_obj
               ; If either of the above containers is destroyed,
               ; then the grid object is also destroyed.
            ENDIF
         ENDIF
      END
      'view_swath_bttn': BEGIN ; Display the selected swath field(s).
         WIDGET_CONTROL, event.id, GET_UVALUE=swath_list
         WIDGET_CONTROL, swath_list, GET_UVALUE=uv
         sel_fields = WIDGET_INFO(swath_list, /LIST_SELECT)
         IF (sel_fields[0] LT 0L) THEN RETURN ; No fields selected.

         ; Swath file load dialog widgets.

         dialog_base = WIDGET_BASE(TITLE='Load Data Field ?', /COLUMN, $
                          GROUP_LEADER=event.top, FLOATING=event.top, /MODAL)
         wid = WIDGET_LABEL(dialog_base, VALUE='Swath: '+uv.swath_name)
         wid = WIDGET_LABEL(dialog_base, VALUE='Field(s):')
         FOR i=0L, N_ELEMENTS(sel_fields)-1L DO $
            wid = WIDGET_LABEL(dialog_base, VALUE=uv.field_names[sel_fields[i]])
         stride_base = WIDGET_BASE(dialog_base, /ROW, /FRAME)
         wid = WIDGET_LABEL(stride_base, VALUE='Stride:')
         stride_text = WIDGET_TEXT(stride_base, VALUE=STRING(1), /EDITABLE, /FRAME, $
                          UNAME='stride_text')
         bttn_base = WIDGET_BASE(dialog_base, COLUMN=2, /GRID)
         ok_bttn = WIDGET_BUTTON(bttn_base, VALUE='Ok', UNAME='ok_bttn')
         cancel_bttn = WIDGET_BUTTON(bttn_base, VALUE='Cancel', UNAME='cancel_bttn')
         load_state = {status:0, stride_text:stride_text, stride:1}
         load_state_ptr = PTR_NEW(load_state)

         ; Start event processing for file load dialog.

         WIDGET_CONTROL, dialog_base, SET_UVALUE=load_state_ptr
         WIDGET_CONTROL, dialog_base, /REALIZE
         XMANAGER, 'NSIDC_DIST_FILE_LOAD', dialog_base
         ; Execution pauses here until dialog is destroyed.

         WIDGET_CONTROL, /HOURGLASS
         load_state = *load_state_ptr
         PTR_FREE, load_state_ptr

         IF (load_state.status NE 1) THEN RETURN ; User cancelled.
         stride = load_state.stride

         FOR i=0L, N_ELEMENTS(sel_fields)-1L DO BEGIN
            field_name = uv.field_names[sel_fields[i]]
            status = EOS_SW_FIELDINFO(uv.swath_id, field_name, rank, dims, numbertype, dimlist)

            IF (N_ELEMENTS(dims) EQ 3L) THEN BEGIN ; Multiple images in field, make a separate display.
               swath_obj = OBJ_NEW('nsidc_dist_grid', self.main_obj, self, $
                              uv.swath_id, uv.swath_name, field_name, dims, $
                              /SWATH, STRIDE=stride)
               IF OBJ_VALID(swath_obj) THEN BEGIN
                  self.container -> ADD, swath_obj
                  self.main_container -> ADD, swath_obj
                  ; If either of the above containers is destroyed,
                  ; then the grid object is also destroyed.
               ENDIF
            ENDIF
            IF (N_ELEMENTS(dims) EQ 2L) THEN BEGIN ; One or more 2D image fields, make a list.
               IF (N_ELEMENTS(field_names) LE 0L) THEN BEGIN
                  field_names = field_name
                  first_dims = dims
               ENDIF ELSE BEGIN
                  IF ((dims[0] EQ first_dims[0]) AND (dims[1] EQ first_dims[1])) THEN BEGIN
                     field_names = [TEMPORARY(field_names), field_name]
                  ENDIF ELSE BEGIN ; Image dimensions are different, make a new display.
                     swath_obj = OBJ_NEW('nsidc_dist_grid', self.main_obj, self, $
                                    uv.swath_id, uv.swath_name, TEMPORARY(field_names), $
                                    first_dims, /SWATH, STRIDE=stride)
                     IF OBJ_VALID(swath_obj) THEN BEGIN
                        self.container -> ADD, swath_obj
                        self.main_container -> ADD, swath_obj
                        ; If either of the above containers is destroyed,
                        ; then the grid object is also destroyed.
                     ENDIF
                     field_names = field_name
                     first_dims = dims
                  ENDELSE
               ENDELSE
            ENDIF
         ENDFOR
         IF (N_ELEMENTS(field_names) GT 0L) THEN BEGIN ; Make one display for all the 2D images.
            swath_obj = OBJ_NEW('nsidc_dist_grid', self.main_obj, self, $
                           uv.swath_id, uv.swath_name, TEMPORARY(field_names), $
                           first_dims, /SWATH, STRIDE=stride)
            IF OBJ_VALID(swath_obj) THEN BEGIN
               self.container -> ADD, swath_obj
               self.main_container -> ADD, swath_obj
               ; If either of the above containers is destroyed,
               ; then the grid object is also destroyed.
            ENDIF
         ENDIF
      END

      'delete_bttn': BEGIN ; Destroy file base.
         scroll_base = self.scroll_base
         WIDGET_CONTROL, event.handler, /DESTROY
         scroll_sub_base = WIDGET_INFO(scroll_base, /CHILD)
         IF NOT(WIDGET_INFO(scroll_sub_base, /VALID_ID)) THEN $ ; All files closed.
            WIDGET_CONTROL, event.top, /DESTROY
      END
   ELSE:
   ENDCASE
END


; File object cleanup.
;
PRO NSIDC_DIST_FILE_KILL, scroll_sub_base
   WIDGET_CONTROL, scroll_sub_base, GET_UVALUE=file_obj
   OBJ_DESTROY, file_obj
END
PRO NSIDC_DIST_FILE::CLEANUP
   status = EOS_GD_CLOSE(self.fid)
   IF (WIDGET_INFO(self.scroll_sub_base, /VALID_ID)) THEN $
      WIDGET_CONTROL, self.scroll_sub_base, /DESTROY
   IF (OBJ_VALID(self.main_container)) THEN self.main_container -> REMOVE, self
   OBJ_DESTROY, self.container
END


; File object definition.
;
PRO NSIDC_DIST_FILE__DEFINE

   struct = {NSIDC_DIST_FILE, $
             main_obj:OBJ_NEW(), $			; Main (parent) object.
             main_container:OBJ_NEW(), $	; Main object container.
             hdf_file:'', $					; HDF filename.
             container:OBJ_NEW(), $			; This object's container.
             main_base:0L, $				; Top-level base of main object.
             file_base:0L, $				; Main object's file holding base.
             scroll_base:0L, $				; Scroll base in file holding base.
             scroll_sub_base:0L, $			; Sub base for this object's widgets.
             fid:0L, $						; HDF file ID.
             n_grids:0L, $					; The number of grids in file.
             n_swath:0L}					; The number of swaths in file.
END