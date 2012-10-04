# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121003202315) do

  create_table "geography_point4_models", :force => true do |t|
    t.string "extra"
    t.point  "geom",  :srid => 4326, :with_z => true, :with_m => true, :geographic => true
  end

  create_table "geography_point_models", :force => true do |t|
    t.string "extra"
    t.point  "geom",  :srid => 4326, :geographic => true
  end

  add_index "geography_point_models", ["extra"], :name => "index_geography_point_models_on_extra"
  add_index "geography_point_models", ["geom"], :name => "index_geography_point_models_on_geom", :index_type => :gist

  create_table "geography_pointm_models", :force => true do |t|
    t.string "extra"
    t.point  "geom",  :srid => 4326, :with_m => true, :geographic => true
  end

  create_table "geography_pointz_models", :force => true do |t|
    t.string "extra"
    t.point  "geom",  :srid => 4326, :with_z => true, :geographic => true
  end

  create_table "geography_polygon_models", :force => true do |t|
    t.string  "extra"
    t.polygon "geom",  :srid => 4326, :geographic => true
  end

  create_table "geometry_models", :force => true do |t|
    t.string   "extra"
    t.geometry "geom",  :srid => 4326
  end

  create_table "point4_models", :force => true do |t|
    t.string "extra"
    t.point  "geom",  :srid => 4326, :with_z => true, :with_m => true
  end

  create_table "point_models", :force => true do |t|
    t.string "extra"
    t.string "more_extra"
    t.point  "geom",        :srid => 4326
    t.point  "point_model", :srid => 4326
  end

  add_index "point_models", ["extra", "more_extra"], :name => "index_point_models_on_extra_and_more_extra"
  add_index "point_models", ["geom"], :name => "index_point_models_on_geom", :index_type => :gist

  create_table "pointm_models", :force => true do |t|
    t.string "extra"
    t.point  "geom",  :srid => 4326, :with_m => true
  end

  create_table "pointz_models", :force => true do |t|
    t.string "extra"
    t.point  "geom",  :srid => 4326, :with_z => true
  end

  create_table "polygon_models", :force => true do |t|
    t.string  "extra"
    t.polygon "geom",  :srid => 4326
  end

end
