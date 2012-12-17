require 'spec_helper'

describe 'Point related AREL functions' do
  let!(:adapter) { ActiveRecord::Base.connection }
  before do
    adapter.create_table :places, :force => true do |t|
      t.point :address, :srid => 4326
    end

    class Place < ActiveRecord::Base
      attr_accessible :address
    end
  end

  after do
    adapter.drop_table :places
    Object.send(:remove_const, :Place)
  end

  describe 'converting polygons in sql statement' do
    it 'properly converts Point to sql format when passed as an argument to a where clause' do
      Place.where(:address => GeometryFactory.point).to_sql.should include("SRID=4326;POINT(1 2)")
    end
  end

  it 'works with count (and other predicates)' do
    Place.create(address: GeometryFactory.point)
    arel_table = Place.arel_table
    Place.where(arel_table[:address].eq(GeometryFactory.point)).count.should eq 1
  end
end
