pro test_grid_class, help=help
    og = obj_new('grid_class', 'Gl1250.gpd', help=help)
;    og = obj_new('grid_class', 'junk.gpd', help=help)
    if obj_valid(og) then begin
        print, 'gpd_filename: ',     og->get_gpd_filename()
        print, 'grid_dimensions: ',  og->get_grid_dimensions()
        print, 'grid_origin: ',      og->get_grid_origin()
        print, 'grid_scale: ',       og->get_grid_scale()
        print, 'projection_name: ',  og->get_projection_name()
        obj_destroy, og, help=help
    endif
end
