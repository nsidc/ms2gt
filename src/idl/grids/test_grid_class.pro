pro print_grid_class_object_instance, og
    print, '*******************************************'
    print, 'grid_origin: ',       og->get_grid_origin()
    print, 'grid_scales: ',       og->get_grid_scales()
    print, 'grid_dimensions: ',   og->get_grid_dimensions()
    print, 'gpd_filename: ',      og->get_gpd_filename()
    print, 'grid_coordinates: '
    help, /struct,                og->get_grid_coordinates()
    print, 'grid_rotation: ',     og->get_grid_rotation()
    print, 'grid_bounds: '
    help, /struct,                og->get_grid_bounds()
    print, 'grid_center: '
    help, /struct,                og->get_grid_center()
    print, 'grid_labels: '
    help, /struct,                og->get_grid_labels()
    print, 'grid_intervals: '
    help, /struct,                og->get_grid_intervals()
    print, 'grid_details: '
    help, /struct,                og->get_grid_details()
    print, 'equatorial_radius: ', og->get_equatorial_radius()
    print, 'eccentricity: ',      og->get_eccentricity()
    print, 'map_origin: ',        og->get_map_origin()
    print, 'map_offset: ',        og->get_map_offset()
    print, 'center_scale: ',      og->get_center_scale()
    print, 'utm_zone: ',          og->get_utm_zone()
    help, /struct,                og->get_isin_params()
    print, 'projection_name: ',   og->get_projection_name()
    print, '*******************************************'
end
        
pro test_grid_class, help=help
    og = obj_new('grid_class', 'junk.gpd', help=help)

    og = obj_new('grid_class', 'Gl1250.gpd', help=help)
    if obj_valid(og) then begin
        print_grid_class_object_instance, og
        lat = [ 70.0,   70.0]
        lon = [-40.0, -100.0]
        col = lat
        row = lon
        status = og->forward(lat, lon, col, row)
        print, 'forward:'
        print, '  lat:', lat
        print, '  lon:', lon
        print, '  col:', col
        print, '  row:', row
        print, '  status:', status
        status = og->inverse(col, row, lat, lon)
        print, 'inverse:'
        print, '  col:', col
        print, '  row:', row
        print, '  lat:', lat
        print, '  lon:', lon
        print, '  status:', status
        obj_destroy, og, help=help
    endif

    og = obj_new('grid_class', 'wilkins250.gpd', help=help)
    if obj_valid(og) then begin
        print_grid_class_object_instance, og
        obj_destroy, og, help=help
    endif

    og = obj_new('grid_class', 'lrsa_utm01000.gpd', help=help)
    if obj_valid(og) then begin
        print_grid_class_object_instance, og
        obj_destroy, og, help=help
    endif
end
