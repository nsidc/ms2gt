; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; Plot object definition.   Stubbed-out for future use.
;
; $Log$
;----------------------------
;revision 1.2	locked by: haran;
;date: 2001/03/15 22:46:53;  author: haran;  state: Exp;  lines: +21 -24
;Dan fixed a bunch of stuff.
;----------------------------
;revision 1.1
;date: 2001/03/15 22:45:58;  author: haran;  state: Exp;
;Initial revision
;
; Initialization.
;
FUNCTION NSIDC_DIST_PLOT::INIT, main_obj, file_obj, grid_id, grid_name, field_name, dims, $
   SWATH=swath, STRIDE=stride

   ; General setup.

   self.win_x = 400
   self.win_y = 340

   self.container = OBJ_NEW('IDL_Container')

   self.main_obj = main_obj
   self.file_obj = file_obj

   self.grid_id = grid_id
   self.grid_name = grid_name
   self.field_name = field_name

   status = EOS_GD_GETFILLVALUE(self.grid_id, field_name, fill_val)
   self.fill_val = fill_val

   self.dim_x = dims[0]

   IF (N_ELEMENTS(stride) NE 1L) THEN stride = 1
   self.stride = stride

   file_obj -> GET_BASES, main_base, file_base
   self.main_base = main_base
   self.file_base = file_base
   file_obj -> GET_CONTAINER, file_container
   self.file_container = file_container

   main_obj -> GET_CONTAINER, main_container
   self.main_container = main_container

   ; Build widgets.

   title = 'Plot: ' + grid_name + ', Field: ' + field_name

   self.plot_base = WIDGET_BASE(TITLE=title, /COLUMN, XPAD=1, YPAD=1, SPACE=1, $
                    GROUP_LEADER=self.file_base, MBAR=bar_base, $
                    KILL_NOTIFY='NSIDC_DIST_PLOT_KILL')

   self.plot_draw = WIDGET_DRAW(self.plot_base, XSIZE=self.win_x, YSIZE=self.win_y)

   WIDGET_CONTROL, self.plot_base, SET_UVALUE=self
   WIDGET_CONTROL, self.plot_base, /REALIZE
   WIDGET_CONTROL, self.plot_draw, GET_VALUE=plot_wind
   self.plot_wind = plot_wind

   ; Draw plot.
   self -> DRAW, /READ_DATA

   ; Start event processing.
   XMANAGER, 'NSIDC_DIST_PLOT', self.plot_base

   RETURN, 1
END


; Plot draw method.
;
PRO NSIDC_DIST_PLOT::DRAW, READ_DATA=read_data

   WSET, self.plot_wind
   read_data = KEYWORD_SET(read_data)
   IF NOT(PTR_VALID(self.data_ptr)) THEN read_data = 1B

   IF (read_data) THEN BEGIN ; Get data from file.
      load_base = WIDGET_BASE(TITLE='Load Status', /COLUMN, $
                     GROUP_LEADER=self.plot_base, FLOATING=self.plot_base)
      wid = WIDGET_LABEL(load_base, VALUE='Loading data, please wait...')
      load_field_labl = WIDGET_LABEL(load_base, VALUE='Field: '+self.field_name)
      WIDGET_CONTROL, load_base, /REALIZE

      PTR_FREE, self.data_ptr

      status = EOS_GD_READFIELD(self.grid_id, self.field_name, $
                  plot_data, STRIDE=self.stride)

      fill_val = self.fill_val

      data_index = WHERE(plot_data NE fill_val)
      min_dat = fill_val
      max_dat = fill_val
      IF (data_index[0] GE 0L) THEN min_dat = MIN(plot_data[data_index], MAX=max_dat)
      sz_data = SIZE(plot_data)
      self.data_ptr = PTR_NEW(TEMPORARY(plot_data))
      self.min_dat = min_dat
      self.max_dat = max_dat

      WIDGET_CONTROL, load_base, /DESTROY ; Destroy status indicator.
   ENDIF

   min_dat = self.min_dat
   max_dat = self.max_dat

   ; Plot the data.
   pd = *(self.data_ptr)
   index = WHERE(pd EQ self.fill_val)
   pd = FLOAT(TEMPORARY(pd))
   IF (index[0] GE 0L) THEN pd[TEMPORARY(index)] = !VALUES.F_NAN
   PLOT, TEMPORARY(pd), YRANGE=[min_dat,max_dat], T3D=0
END


; Plot object event handler.
;
PRO NSIDC_DIST_PLOT_EVENT, event
   WIDGET_CONTROL, event.handler, GET_UVALUE=plot_obj
   plot_obj -> EVENT, event
END
PRO NSIDC_DIST_PLOT::EVENT, event

   WIDGET_CONTROL, /HOURGLASS
   uname = WIDGET_INFO(event.id, /UNAME)

   ; No widgets in this object.

   CASE uname OF
   ELSE:
   ENDCASE
END


; Plot object cleanup.
;
PRO NSIDC_DIST_PLOT_KILL, plot_base
   WIDGET_CONTROL, plot_base, GET_UVALUE=plot_obj
   OBJ_DESTROY, plot_obj
END
PRO NSIDC_DIST_PLOT::CLEANUP
   IF (OBJ_VALID(self.file_container)) THEN self.file_container -> REMOVE, self
   PTR_FREE, self.data_ptr
   OBJ_DESTROY, self.container
END


; Plot object definition.
;
PRO NSIDC_DIST_PLOT__DEFINE

   struct = {NSIDC_DIST_PLOT, $
             main_obj:OBJ_NEW(), $			; Main object.
             file_obj:OBJ_NEW(), $			; File object.
             main_container:OBJ_NEW(), $	; Main object's container.
             file_container:OBJ_NEW(), $	; File object's container.
             container:OBJ_NEW(), $			; This object's container.
             main_base:0L, $				; Top-level base of main object.
             file_base:0L, $				; File object's widget base.
             plot_base:0L, $				; Holding base for plot draw widget.
             plot_draw:0L, $				; Plot draw widget.
             plot_wind:0L, $				; Plot window ID.
             dim_x:0, $						; Data X dimension.
             stride:0, $					; Stride value when reading HDF data.
             win_x:0, $						; Plot window X dimension.
             win_y:0, $						; Plot window Y dimension.
             grid_id:0L, $					; HDF 1-D grid ID.
             grid_name:'', $				; Grid name.
             field_name:'', $				; Field name.
             fill_val:0.0, $				; Fill value.
             data_ptr:PTR_NEW(), $			; Pointer to plot data.
             min_dat:0.0, $					; Min value.
             max_dat:0.0}					; Max value.
END
