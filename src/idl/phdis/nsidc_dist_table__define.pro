; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; Table object definition.

; Initialization.
;
; $Log$
;
FUNCTION NSIDC_DIST_TABLE::INIT, main_obj, file_obj, grid_obj, data, $
   box_pts, grid_name, field_name, img_num

   ; General setup.

   self.main_obj = main_obj
   self.file_obj = file_obj
   self.grid_obj = grid_obj

   file_obj -> GET_HDF_FILE, hdf_file
   self.hdf_file = hdf_file
   file_obj -> GET_BASES, main_base, file_base
   self.file_base = file_base
   file_obj -> GET_CONTAINER, file_container
   self.file_container = file_container

   grid_obj -> GET_BASE, grid_base
   self.grid_base = grid_base
   grid_obj -> GET_CONTAINER, grid_container
   self.grid_container = grid_container

   grid_obj -> GET_DIMS, dim_x, dim_y

   sz_data = SIZE(data)
   self.dim_x = sz_data[1]
   self.dim_y = sz_data[2]

   ; Invert the data so it looks right in table.
   self.data_ptr = PTR_NEW(REVERSE(TEMPORARY(data), 2))

   self.box_pts = box_pts

   ; Normalize the box coordinates.
   box_pts_norm = FLOAT(box_pts) / FLOAT([dim_x,dim_y,dim_x,dim_y]-1)
   ul_ll = (CONVERT_COORD(box_pts_norm[0], box_pts_norm[3], /NORMAL, /TO_DATA))[0:1]
   lr_ll = (CONVERT_COORD(box_pts_norm[2], box_pts_norm[1], /NORMAL, /TO_DATA))[0:1]

   cc_ll = (CONVERT_COORD((box_pts_norm[0]+box_pts_norm[2])/2.0, $
                          (box_pts_norm[1]+box_pts_norm[3])/2.0, $
                          /NORMAL, /TO_DATA))[0:1]

   self.ul_ll = ul_ll
   self.lr_ll = lr_ll
   self.cc_ll = cc_ll

   grid_obj -> CALC_WH, box_pts, w, h
   self.w = w
   self.h = h

   self.grid_name = grid_name
   self.field_name = field_name
   self.img_num = img_num

   ; Build widgets.

   title = 'Data Subset Table'

   self.table_base = WIDGET_BASE(TITLE=title, /COLUMN, XPAD=1, YPAD=1, SPACE=1, $
                        GROUP_LEADER=self.file_base, MBAR=bar_base, $
                        KILL_NOTIFY='NSIDC_DIST_TABLE_KILL', $
                        UNAME='table_base', /TLB_SIZE_EVENTS)

   file_menu = WIDGET_BUTTON(bar_base, VALUE='File', /MENU)
   IF (!D.Name EQ 'WIN') THEN print_bttn = WIDGET_BUTTON(file_menu, VALUE='Print', UNAME='print_bttn')
   save_ascii_bttn = WIDGET_BUTTON(file_menu, VALUE='Save ASCII', UNAME='save_ascii_bttn')
   save_binary_bttn = WIDGET_BUTTON(file_menu, VALUE='Save Binary', UNAME='save_binary_bttn')
   close_bttn = WIDGET_BUTTON(file_menu, VALUE='Close', UNAME='close_bttn', /SEPARATOR)

   l_t = 'File: ' + self.hdf_file
   wid1 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Grid: ' + self.grid_name
   wid2 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Field: ' + self.field_name
   wid3 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Image Number: ' + STRING(self.img_num)
   wid4 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Upper Left (lon,lat): ' + STRTRIM(ul_ll[0],2) + ', ' + STRTRIM(ul_ll[1],2)
   wid5 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Lower Right (lon,lat): ' + STRTRIM(lr_ll[0],2) + ', ' + STRTRIM(lr_ll[1],2)
   wid6 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Center (lon,lat): ' + STRTRIM(cc_ll[0],2) + ', ' + STRTRIM(cc_ll[1],2)
   wid7 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Approximate Size (KM) (width,height): ' + STRTRIM(w,2) + ', ' + STRTRIM(h,2)
   wid8 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   l_t = 'Box Size (pixels) (width,height): ' + $
      STRTRIM(self.dim_x,2) + ', ' + STRTRIM(self.dim_y,2)
   wid9 = WIDGET_LABEL(self.table_base, VALUE=l_t)

   self.label_widgets = [wid1,wid2,wid3,wid4,wid5,wid6,wid7,wid8,wid9]

   self.table_hold_base = WIDGET_BASE(self.table_base)

   self.col_size = 64
   self.row_size = 24

   self.data_table = WIDGET_TABLE(self.table_hold_base, VALUE=(*self.data_ptr), $
      X_SCROLL_SIZE=10, Y_SCROLL_SIZE=10, UNAME='data_table', /ALL_EVENTS, $
      ALIGNMENT=2, COLUMN_WIDTHS=self.col_size, ROW_HEIGHTS=self.row_size)

   ; Start event processing.

   WIDGET_CONTROL, self.table_base, SET_UVALUE=self
   WIDGET_CONTROL, self.table_base, /REALIZE
   XMANAGER, 'NSIDC_DIST_TABLE', self.table_base

   RETURN, 1
END


; Table object event handler.
;
PRO NSIDC_DIST_TABLE_EVENT, event
   WIDGET_CONTROL, event.handler, GET_UVALUE=table_obj
   table_obj -> EVENT, event
END
PRO NSIDC_DIST_TABLE::EVENT, event

ON_IOERROR, IO_BAD

   WIDGET_CONTROL, /HOURGLASS
   uname = WIDGET_INFO(event.id, /UNAME)

   CASE uname OF
      'table_base': BEGIN ; Resize
         WIDGET_CONTROL, self.table_base, UPDATE=0
         cols = ((((event.x) - 12) / self.col_size) - 1) > 3
         rows = ((((event.y) - 96) / self.row_size) - 1) > 3

         WIDGET_CONTROL, self.data_table, /DESTROY
         self.data_table = WIDGET_TABLE(self.table_hold_base, VALUE=(*self.data_ptr), $
            X_SCROLL_SIZE=cols, Y_SCROLL_SIZE=rows, UNAME='data_table', /ALL_EVENTS, $
            ALIGNMENT=2, COLUMN_WIDTHS=64, ROW_HEIGHTS=24)
         WIDGET_CONTROL, self.table_base, UPDATE=1
      END
      'print_bttn': BEGIN ; Print (this button only active on Windows platforms).
         temp_file = 'c:\windows\temp\nsidc_dist_temp.txt'
         GET_LUN, lun
         OPENW, lun, temp_file
         FOR i=0, 8 DO BEGIN
            WIDGET_CONTROL, self.label_widgets[i], GET_VALUE=head_str
            PRINTF, lun, head_str
         ENDFOR
         PRINTF, lun, ''
         sz_data = SIZE(*self.data_ptr)
         ty_data = SIZE(*self.data_ptr, /TYPE)
         IF ((ty_data GE 4) AND (ty_data LE 6)) THEN BEGIN ; Floating point.
            f = '(8F10.2)'
         ENDIF ELSE BEGIN ; Integer.
            f = '(8I8)'
         ENDELSE
         FOR row=0L, sz_data[2]-1L DO BEGIN
            data_row = (*self.data_ptr)[*,row]
            PRINTF, lun, data_row, FORMAT=f
         ENDFOR
         CLOSE, lun
         FREE_LUN, lun
         DEVICE, PRINT_FILE=temp_file
      END
      'save_ascii_bttn': BEGIN ; Save to ASCII file.
         self.main_obj -> GET_FP, fp
         save_file = DIALOG_PICKFILE(FILTER='*.txt', /WRITE, $
            DIALOG_PARENT=event.top, PATH=fp, $
            TITLE='Select ASCII Data File To Write')
         IF (save_file EQ '') THEN RETURN ; User cancelled.
         ind = STRPOS(save_file, '.txt')
         IF (ind LE 0L) THEN save_file = save_file + '.txt'
         ff = FINDFILE(save_file)
         IF (ff[0] NE '') THEN BEGIN
            ans = DIALOG_MESSAGE(['File exists.   Overwrite '+ff[0]], $
                     DIALOG_PARENT=event.top, /QUESTION)
            IF (ans NE 'Yes') THEN RETURN
         ENDIF
         WIDGET_CONTROL, /HOURGLASS

         GET_LUN, lun
         OPENW, lun, save_file
         FOR i=0, 8 DO BEGIN
            WIDGET_CONTROL, self.label_widgets[i], GET_VALUE=head_str
            PRINTF, lun, head_str
         ENDFOR
         PRINTF, lun, ''
         sz_data = SIZE(*self.data_ptr)
         ty_data = SIZE(*self.data_ptr, /TYPE)
         IF ((ty_data GE 4) AND (ty_data LE 6)) THEN BEGIN ; Floating point.
            f = '(8F10.2)'
         ENDIF ELSE BEGIN ; Integer.
            f = '(8I8)'
         ENDELSE
         FOR row=0L, sz_data[2]-1L DO BEGIN
            data_row = (*self.data_ptr)[*,row]
            PRINTF, lun, data_row, FORMAT=f
         ENDFOR
         CLOSE, lun
         FREE_LUN, lun
      END
      'save_binary_bttn': BEGIN ; Save to binary file.
         self.main_obj -> GET_FP, fp
         save_file = DIALOG_PICKFILE(FILTER='*.dat', /WRITE, $
            DIALOG_PARENT=event.top, PATH=fp, $
            TITLE='Select Binary Data File To Write')
         IF (save_file EQ '') THEN RETURN ; User cancelled.
         ind = STRPOS(save_file, '.dat')
         IF (ind LE 0L) THEN save_file = save_file + '.dat'
         ff = FINDFILE(save_file)
         IF (ff[0] NE '') THEN BEGIN
            ans = DIALOG_MESSAGE(['File exists.   Overwrite '+ff[0]], $
                     DIALOG_PARENT=event.top, /QUESTION)
            IF (ans NE 'Yes') THEN RETURN
         ENDIF
         WIDGET_CONTROL, /HOURGLASS

         GET_LUN, lun
         OPENW, lun, save_file
         total_bytes = 0L
         FOR i=0, 8 DO BEGIN
            WIDGET_CONTROL, self.label_widgets[i], GET_VALUE=head_str
            str_80 = STRING(REPLICATE(32B, 80))
            STRPUT, str_80, head_str
            WRITEU, lun, str_80
            total_bytes = total_bytes + 80L
         ENDFOR

         ; Pad the header to 1024 bytes.
         fill_bytes = 1024L - total_bytes
         WRITEU, lun, REPLICATE(0B, fill_bytes)

         ; Write the binary data.
         WRITEU, lun, *self.data_ptr

         CLOSE, lun
         FREE_LUN, lun
      END
      'close_bttn': BEGIN ; Close window.
         WIDGET_CONTROL, event.top, /DESTROY
      END
      'data_table': BEGIN ; Selection in data table.
         IF OBJ_VALID(self.grid_obj) THEN BEGIN
            ; Highlight the corresponding pixels in the associated grid object.
            IF (event.sel_left GE 0) THEN BEGIN
               hlt_box = [event.sel_left, event.sel_bottom, event.sel_right, event.sel_top]
               hlt_box[[0,2]] = hlt_box[[0,2]] + self.box_pts[0]
               hlt_box[[1,3]] = self.box_pts[3] - hlt_box[[1,3]]
               self.grid_obj -> DRAW_UPDATE
               self.grid_obj -> DRAW_TABLE, self.box_pts, hlt_box
            ENDIF
         ENDIF
      END
   ELSE:
   ENDCASE

   RETURN

IO_BAD:

   IF (N_ELEMENTS(lun) GT 0L) THEN FREE_LUN, lun
   ans = DIALOG_MESSAGE('Unknown I/O error', DIALOG_PARENT=event.top, /ERROR)

END


; Table object cleanup.
;
PRO NSIDC_DIST_TABLE_KILL, table_base
   WIDGET_CONTROL, table_base, GET_UVALUE=table_obj
   OBJ_DESTROY, table_obj
END
PRO NSIDC_DIST_TABLE::CLEANUP
   IF (OBJ_VALID(self.file_container)) THEN self.file_container -> REMOVE, self
   PTR_FREE, self.data_ptr
END


; Table object definition.
;
PRO NSIDC_DIST_TABLE__DEFINE

   struct = {NSIDC_DIST_TABLE, $
             main_obj:OBJ_NEW(), $			; Main object.
             file_obj:OBJ_NEW(), $			; Associated file object.
             grid_obj:OBJ_NEW(), $			; Associated grid object.
             file_container:OBJ_NEW(), $	; File object's container.
             grid_container:OBJ_NEW(), $	; Grid object's container.
             data_ptr:PTR_NEW(), $			; Pointer to table data.
             file_base:0L, $				; File object's widget base.
             grid_base:0L, $				; Top-level base of grid object.
             table_base:0L, $				; Top-level base of this object.
             table_hold_base:0L, $			; Base that holds actual table widget.
             data_table:0L, $				; Table widget.
             label_widgets:LONARR(9), $		; Header label widgets.
             dim_x:0, $						; X dimension of data (table columns).
             dim_y:0, $						; Y dimension of data (table rows).
             col_size:0, $					; Width of each cell in pixels.
             row_size:0, $					; Height of each cell in pixels.
             box_pts:LONARR(4), $			; Corners of bounding box (grid coordinates).
             hdf_file:'', $					; HDF file name.
             grid_name:'', $				; Grid name.
             field_name:'', $				; Field name.
             img_num:0, $					; Image number.
             ul_ll:[0.0,0.0], $				; Upper left lon-lat.
             lr_ll:[0.0,0.0], $				; Lower right lon-lat.
             cc_ll:[0.0,0.0], $				; Center lon-lat.
             w:0.0, $						; Width in meters.
             h:0.0}							; Height in meters.
END
