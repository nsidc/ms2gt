pro test_grid_class, help=help
    og = obj_new('grid_class', 'junk.gpd', help=help)
    og = obj_new('grid_class', 'Gl1250.gpd', help=help)
    if obj_valid(og) then begin
        print, 'grid_origin: ',       og->get_grid_origin()
        print, 'grid_scale: ',        og->get_grid_scale()
        print, 'grid_dimensions: ',   og->get_grid_dimensions()
        print, 'gpd_filename: ',      og->get_gpd_filename()
        print, 'grid_coordinates: '
        help, /struct,                og->get_grid_coordinates()
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
        print, 'projection_name: ',   og->get_projection_name()
        obj_destroy, og, help=help
    endif
end
