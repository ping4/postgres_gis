require 'spec_helper'

describe 'point migrations' do
  let!(:connection) { ActiveRecord::Base.connection }
  it 'creates a point column' do
    lambda do
      connection.create_table :data_types do |t|
        #t.polygon :poly_1, :null => false, :srid => 4326
        t.point :point_1, :null => false, :geographic => false
        t.column :point_4, :point, :geographic => true
      end
      connection.add_column :data_types, :point_5, :point, :geographic => false
      connection.change_table :data_types do |t|
        t.point :point_7, :geographic => true
      end
    end.should_not raise_exception

    columns = connection.columns(:data_types)

    point_1 = columns.detect { |c| c.name == 'point_1'}
    point_4 = columns.detect { |c| c.name == 'point_4'}
    point_5 = columns.detect { |c| c.name == 'point_5'}
    point_7 = columns.detect { |c| c.name == 'point_7'}

    #pp point_1.to_json
    ##TODO: add add_column support (point_5)
    [point_1].each do |geom_column|
      geom_column.sql_type.should match /point/i
#      geom_column.sql_type.should match /geometry/i
      geom_column.geometry_type.should == :point
      geom_column.type.should == :string
      #geom_column.with_z.should == true
      #geom_column.with_m.should == true
      #geom_column.srid.should == 4326
      geom_column.should_not be_geographic
    end

    #pp point_4.to_json
    ##TODO: add change_table support (point_7)
    [point_4].each do |geographic_column|
      geographic_column.sql_type.should match /point/i
#      geographic_column.sql_type.should match /geography/i
      geographic_column.geometry_type.should == :point
      geographic_column.type.should == :string
      # geographic_column.with_z.should == true
      # geographic_column.with_m.should == true
      geographic_column.should be_geographic
    end
  end
end
