; EOSImageTool, written in IDL 5.4 by Daniel Carr, Research Systems, Inc.
; Fri Feb 16 20:24:31 2001
;
; National Snow and Ice Data Center
; Boulder, Colorado
;
; $Log$
;
; Function to get lon/lat position given distance (in meters).
;
FUNCTION NSIDC_DIST_GET_LATLON, xy, projcode, projparam

   n_pts = N_ELEMENTS(xy) / 2L

   CASE projcode OF
      11: BEGIN ; Lambert Azimuthal projection.

         ; Double precision conversions.
         eps = 1.0D-10
         raddeg = 45.0D / ATAN(1.0D)
         degrad = 1.0D / raddeg

         lon0 = degrad * projparam[4] / 1000000.0D ; Scaling the parameters.
         lat0 = degrad * projparam[5] / 1000000.0D ; Scaling the parameters.
         r = projparam[0] ; Radius used in projection.
         x = xy[0,*]
         y = xy[1,*]

         rh = SQRT((x * x) + (y * y)) ; Distance to corner.

         temp = (rh / (2.0D * r)) ; Relative distance.
         z = 2.0D * ASIN(temp < 1.0D) ; Relevant angle.

         sin_z = SIN(z)
         cos_z = COS(z)

         index = WHERE(ABS(cos_z) LT eps)
         IF (index[0] GE 0L) THEN cos_z[index] = 0.0D ; Close enough.
         cos_lat0 = COS(lat0) ; Cosine of the latitude.
         IF (ABS(cos_lat0) LT eps) THEN cos_lat0 = 0.0D ; Close enough.

         mask = 1.0D + (0.9999999D * DOUBLE(temp GT 1.0D))
         lat = lat0 + (mask * ASIN((SIN(lat0) * cos_z) + (cos_lat0 * sin_z * y / rh))) ; The formula.

         index = WHERE(lat GT ( 2.0D * ATAN(1.0D)))
         IF (index[0] GE 0L) THEN lat[index] = lat[index] - (2.0D * ATAN(1.0D)) ; Correct quadrant.

         index = WHERE(lat LT (-2.0D * ATAN(1.0D)))
         IF (index[0] GE 0L) THEN lat[index] = lat[index] + (2.0D * ATAN(1.0D)) ; Correct quadrant.

         temp = ABS(lat0) - (2.0D * ATAN(1.0D))
         IF (ABS(temp) GT eps) THEN BEGIN ; Calculate lon.
            temp = cos_z - (SIN(lat0) * SIN(lat))
            lon = lon0 + ATAN(x * sin_z * COS(lat0) / (temp * rh))
         ENDIF ELSE BEGIN
            IF (lat0 LT 0.0D) THEN lon = lon0 - ATAN(-x, y) $
            ELSE lon = lon0 + ATAN(x, -y)
         ENDELSE

         index = WHERE(lon GT ( 4.0D * ATAN(1.0D)))
         IF (index[0] GE 0L) THEN lon[index] = lon[index] - (8.0D * ATAN(1.0D)) ; Correct quadrant.

         index = WHERE(lon LT (-4.0D * ATAN(1.0D)))
         IF (index[0] GE 0L) THEN lon[index] = lon[index] + (8.0D * ATAN(1.0D)) ; Correct quadrant.

         lat = TEMPORARY(lat) * raddeg ; Convert to degrees.
         lon = TEMPORARY(lon) * raddeg ; Convert to degrees.

         xy[0,0] = REFORM(TEMPORARY(lat), 1, n_pts)
         xy[1,0] = REFORM(TEMPORARY(lon), 1, n_pts)

         RETURN, 1
      END
   ELSE: RETURN, 0 ; Unsupported projection type.
   ENDCASE

END
