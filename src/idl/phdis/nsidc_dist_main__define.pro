; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; Main object definition.

; Initialization.
;
; $Log: nsidc_dist_main__define.pro,v $
; Revision 1.3  2001/03/13 18:50:43  haran
; added log
;
;
;----------------------------
;revision 1.2	locked by: haran;
;date: 2001/03/12 18:32:16;  author: haran;  state: Exp;  lines: +2 -2
;added x_scroll_size=900 to call to widget_base in creation of Polar
;HDF-EOS Metadata dialog.
;----------------------------
;revision 1.1
;date: 2001/03/12 18:12:08;  author: haran;  state: Exp;
;Initial revision
;
FUNCTION NSIDC_DIST_MAIN::INIT

   ; General setup.

   self.container = OBJ_NEW('IDL_Container')
   self.link_flag = 1B

   ; Build widgets.

   self.main_base = WIDGET_BASE(TITLE='National Snow and Ice Data Center', /COLUMN, $
                           KILL_NOTIFY='NSIDC_DIST_MAIN_KILL')
   wid = WIDGET_LABEL(self.main_base, VALUE='Polar HDF-EOS Data Imaging and Subsetting Tool', $
                      FONT='times*24*bold')
   file_bttn = WIDGET_BUTTON(self.main_base, VALUE='Select File(s)', UNAME='file_bttn') ; Select file button.

   quit_bttn = WIDGET_BUTTON(self.main_base, VALUE='Quit', UNAME='quit_bttn', /ALIGN_CENTER)

   inst_base = WIDGET_BASE(self.main_base, /COLUMN, XPAD=1, YPAD=1, SPACE=1, /FRAME)
   wid = WIDGET_LABEL(inst_base, VALUE='Click "Select File(s)" to open one or more files.   ' + $
                                       'Use Shift-click or "Ctrl-click" to select multiple files.', $
                                 /ALIGN_LEFT)
   wid = WIDGET_LABEL(inst_base, VALUE='After opening, the "Load Data Field(s)" window will appear.   ' + $
                                       'Metadata will be shown for each grid', $
                                 /ALIGN_LEFT)
   wid = WIDGET_LABEL(inst_base, VALUE='object in each file.   Click on a row to load and display a ' + $
                                       'data field.', $
                                 /ALIGN_LEFT)

   self.main_base = self.main_base

   ; Register widgets for event handling.

   WIDGET_CONTROL, self.main_base, SET_UVALUE=self
   WIDGET_CONTROL, self.main_base, /REALIZE
   XMANAGER, CATCH=0
   XMANAGER, 'NSIDC_DIST_MAIN', self.main_base, /JUST_REG
   RETURN, 1
END


; Method to add a new file to the main object.
;
PRO NSIDC_DIST_MAIN::ADD_FILE, hdf_file

   ; Create the top-level holding base if it does not exist.
   ;
   IF NOT(WIDGET_INFO(self.file_base, /VALID_ID)) THEN BEGIN
      self.file_base = WIDGET_BASE(TITLE='Polar HDF-EOS Metadata', $
         XPAD=1, YPAD=1, SPACE=1, GROUP_LEADER=self.main_base, $
         KILL_NOTIFY='NSIDC_DIST_MAIN_FILE_KILL', /TLB_KILL_REQUEST_EVENTS, $
         UNAME='file_base')
      self.scroll_base = WIDGET_BASE(self.file_base, /COLUMN, $
         XPAD=1, YPAD=1, SPACE=1, x_scroll_size=900, Y_SCROLL_SIZE=512)

      WIDGET_CONTROL, self.file_base, SET_UVALUE=self
      WIDGET_CONTROL, self.file_base, /REALIZE
      XMANAGER, 'NSIDC_DIST_MAIN_FILE', self.file_base
   ENDIF
   WIDGET_CONTROL, self.file_base, /SHOW

   ; Create a new file object.
   ;
   file_obj = OBJ_NEW('NSIDC_DIST_FILE', self, hdf_file)
   self.container -> ADD, file_obj
   ; Destroying the container will cause the file object(s)
   ; to be destroyed also.

END


; Get important widget base IDs.
;
PRO NSIDC_DIST_MAIN::GET_BASES, main_base, file_base, scroll_base
   main_base = self.main_base
   file_base = self.file_base
   scroll_base = self.scroll_base
END


; Get container.
;
PRO NSIDC_DIST_MAIN::GET_CONTAINER, main_container
   main_container = self.container
END


; Get & set current file path.
;
PRO NSIDC_DIST_MAIN::GET_FP, fp
   fp = self.fp
END
PRO NSIDC_DIST_MAIN::SET_FP, fp
   self.fp = fp
END


; Get & set window linking flag.
;
FUNCTION NSIDC_DIST_MAIN::GET_LINK_FLAG
   RETURN, self.link_flag
END
PRO NSIDC_DIST_MAIN::SET_LINK_FLAG, lf
   self.link_flag = lf
END


; Event handler for file holding base..
;
PRO NSIDC_DIST_MAIN_FILE_EVENT, event
   WIDGET_CONTROL, event.top, GET_UVALUE=main_obj
   main_obj -> FILE_EVENT, event
END
PRO NSIDC_DIST_MAIN::FILE_EVENT, event
   WIDGET_CONTROL, /HOURGLASS
   uname = WIDGET_INFO(event.id, /UNAME)
   CASE uname OF
      'file_base': BEGIN
         ; User clicked on "X" to close window -
         ; destroy all file objects.
         WIDGET_CONTROL, event.top, /DESTROY
         OBJ_DESTROY, self.container
         self.container = OBJ_NEW('IDL_Container')
      END
   ELSE:
   ENDCASE
END


; Main event handler.
;
PRO NSIDC_DIST_MAIN_EVENT, event
   WIDGET_CONTROL, event.top, GET_UVALUE=main_obj
   main_obj -> EVENT, event
END
PRO NSIDC_DIST_MAIN::EVENT, event

   WIDGET_CONTROL, /HOURGLASS
   uname = WIDGET_INFO(event.id, /UNAME)

   CASE uname OF
      'file_bttn': BEGIN ; Load a file.
         hdf_files = DIALOG_PICKFILE(FILTER='*.hdf', $
            PATH=self.fp, GET_PATH=out_fp, /MUST_EXIST, /READ, $
            /MULTIPLE_FILES, DIALOG_PARENT=event.top, GROUP=event.top, $
            TITLE='Select one or more HDF-EOS files')
         WIDGET_CONTROL, /HOURGLASS
         IF (hdf_files[0] EQ '') THEN RETURN ; User cancelled.
         self.fp = out_fp
         FOR i=0L, N_ELEMENTS(hdf_files)-1L DO self -> ADD_FILE, hdf_files[i]
      END
      'quit_bttn': BEGIN ; Quit the entire application.
         stat = DIALOG_MESSAGE('Confirm Quit', /QUESTION, DIALOG_PARENT=event.top)
         IF (stat EQ 'Yes') THEN WIDGET_CONTROL, event.top, /DESTROY
      END
   ELSE:
   ENDCASE
END


; Main object cleanup.
;
PRO NSIDC_DIST_MAIN_KILL, main_base
   WIDGET_CONTROL, main_base, GET_UVALUE=main_obj
   OBJ_DESTROY, main_obj
END
PRO NSIDC_DIST_MAIN::CLEANUP
   IF (WIDGET_INFO(self.main_base, /VALID_ID)) THEN $
      WIDGET_CONTROL, self.main_base, /DESTROY
   OBJ_DESTROY, self.container
END


; File holding base cleanup.
;
PRO NSIDC_DIST_MAIN_FILE_KILL, file_base
   WIDGET_CONTROL, file_base, GET_UVALUE=main_obj
   IF (OBJ_VALID(main_obj)) THEN main_obj -> FILE_KILL, file_base
END
PRO NSIDC_DIST_MAIN::FILE_KILL, file_base
   ; Destroy all file objects.
   file_objs = self.container -> GET(/ALL, COUNT=count)
   FOR i=0L, count-1L DO BEGIN
      self.container -> REMOVE, file_objs[i]
      OBJ_DESTROY, file_objs[i]
   ENDFOR
END


; Main object definition.
;
PRO NSIDC_DIST_MAIN__DEFINE

   struct = {NSIDC_DIST_MAIN, $
             container:OBJ_NEW(), $			; Main object's container.
             fp:'', $						; Current file path.
             main_base:0L, $				; Main object top-level base.
             file_base:0L, $				; Main object's file holding base.
             scroll_base:0L, $				; Scrolling base in file holding base.
             link_flag:0B}					; Window linking flag.
END
