; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; Tool to get an RGB color mix from the user.
;
; $Log$
;

; Event handler for color definition dialog.
;
PRO NSIDC_DIST_GET_COLOR_EVENT, event

   WIDGET_CONTROL, event.top, GET_UVALUE=colo_state
   uname = WIDGET_INFO(event.id, /UNAME)

   CASE uname OF
      'r_slid': colo_state.r = event.value
      'g_slid': colo_state.g = event.value
      'b_slid': colo_state.b = event.value
      'close_bttn': BEGIN
         WIDGET_CONTROL, event.top, /DESTROY
         RETURN
      END
      ELSE:
   ENDCASE

   WSET, colo_state.colo_wind
   TVLCT, colo_state.r, colo_state.g, colo_state.b, colo_state.color
   ERASE, colo_state.color
   WIDGET_CONTROL, event.top, SET_UVALUE=colo_state

END


; Procedure to build color definition dialog.
;
PRO NSIDC_DIST_GET_COLOR, color, leader

   TVLCT, r, g, b, color, /GET
   r = r[0]
   g = g[0]
   b = b[0]

   ; Build color definition dialog.

   colo_base = WIDGET_BASE(TITLE='Define Color', /COLUMN, /MODAL, $
      XPAD=1, YPAD=1, SPACE=1, GROUP_LEADER=leader, UVALUE=color, $
      FLOATING=leader)

   r_slid = WIDGET_SLIDER(colo_base, VALUE=r, MIN=0, MAX=255, $
                  TITLE='Red', UNAME='r_slid', /DRAG)

   g_slid = WIDGET_SLIDER(colo_base, VALUE=g, MIN=0, MAX=255, $
                  TITLE='Green', UNAME='g_slid', /DRAG)

   b_slid = WIDGET_SLIDER(colo_base, VALUE=b, MIN=0, MAX=255, $
                  TITLE='Blue', UNAME='b_slid', /DRAG)

   colo_draw = WIDGET_DRAW(colo_base, XSIZE=288, YSIZE=32, UNAME='colo_draw')

   bttn_base = WIDGET_BASE(colo_base, /ROW, XPAD=1, YPAD=1, SPACE=1, /GRID)
   close_bttn = WIDGET_BUTTON(bttn_base, VALUE='Close', $
                    UNAME='close_bttn')

   WIDGET_CONTROL, colo_base, /REALIZE
   WIDGET_CONTROL, colo_draw, GET_VALUE=colo_wind
   WSET, colo_wind
   colo_state = {color:color, r:r, g:g, b:b, colo_wind:colo_wind}
   WIDGET_CONTROL, colo_base, SET_UVALUE=colo_state
   ERASE, color

   ; Process events.
   XMANAGER, 'NSIDC_DIST_GET_COLOR', colo_base, /MODAL
   ; Execution pauses here until dialog is destroyed.
END
