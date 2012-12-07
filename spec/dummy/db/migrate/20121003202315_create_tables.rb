class CreateTables < ActiveRecord::Migration
  def up
    install_extensions
    create_geometry_model
    create_geography_model if ActiveRecord::Base.connection.supports_geographic?
  end

  def down
  end

  def install_extensions
    execute %{
      CREATE EXTENSION postgis;
      CREATE EXTENSION postgis_topology;
      GRANT ALL ON geometry_columns TO PUBLIC;
      GRANT ALL ON spatial_ref_sys TO PUBLIC;
      GRANT ALL ON geography_columns TO PUBLIC;
    }
  end

  def create_geometry_model
    create_table :point_models do |t|
      t.string :extra
      t.string :more_extra
      t.point :geom, :point_model, :srid => 4326
    end

    add_index :point_models, :geom, :index_type => 'gist'
    add_index :point_models, [:extra, :more_extra]

   # create_table :line_string_models do |t|
   #   t.string :extra
   #   t.line_string 'line_string_models', :srid => 4326
   # end

    create_table :polygon_models do |t|
      t.string :extra
      t.polygon :geom, :srid =>4326
    end

    # create_table :multi_point_models do |t|
    #   t.string :extra
    #   t.multi_point :multi_point_models, :srid => 4326
    # end

    # create_table :multi_line_string_models do |t|
    #   t.string :extra
    #   t.multi_line_string :multi_line_string_models, :srid => 4326
    # end

    # create_table :multi_polygon_models do |t|
    #   t.string :extra
    #   t.multi_polygon :multi_polygon_models, :srid => 4326
    # end

    # create_table :geometry_collection_models do |t|
    #   t.string :extra
    #   t.geometry_collection :geometry_collection_models, :srid => 4326
    # end

    create_table :geometry_models do |t|
      t.string :extra
      t.geometry :geom, :srid => 4326
    end
    
    create_table :pointz_models do |t|
      t.string :extra
      t.point :geom, :srid => 4326, :with_z => true
    end
    
    create_table :pointm_models do |t|
      t.string :extra
      t.point :geom, :srid => 4326, :with_m => true
    end

    create_table :point4_models do |t|
      t.string :extra
      t.point :geom, :srid => 4326, :with_m => true, :with_z => true
    end
  end

  def create_geography_model
    create_table :geography_point_models do |t|
      t.string :extra
      t.point :geom, :geographic => true
    end
    add_index :geography_point_models, :geom, :index_type => :gist
    add_index :geography_point_models, :extra

    # create_table :geography_line_string_models do |t|
    #   t.string :extra
    #   t.line_string :geom, :geographic => true
    # end

    create_table :geography_polygon_models do |t|
      t.string :extra
      t.polygon :geom, :geographic => true
    end

    # create_table :geography_multi_point_models do |t|
    #   t.string :extra
    #   t.multi_point :geom, :geographic => true
    # end

    # create_table :geography_multi_line_string_models do |t|
    #   t.string :extra
    #   t.multi_line_string :geom, :geographic => true
    # end

    # create_table :geography_multi_polygon_models do |t|
    #   t.string :extra
    #   t.multi_polygon :geom, :geographic => true
    # end

    # create_table :geography_geometry_collection_models do |t|
    #   t.string :extra
    #   t.geometry_collection :geom, :geographic => true
    # end

    #will want to produce geography / geometry
    # create_table :geography_models do |t|
    #   t.string :extra
    #   t.geography :geom, :geographic => true
    # end

    create_table :geography_pointz_models do |t|
      t.string :extra
      t.point :geom, :with_z => true, :geographic => true
    end

    create_table :geography_pointm_models do |t|
      t.string :extra
      t.point :geom, :with_m => true, :geographic => true
    end

    create_table :geography_point4_models do |t|
      t.string :extra
      t.point :geom, :with_m => true, :with_z => true, :geographic => true
    end
  end
end
