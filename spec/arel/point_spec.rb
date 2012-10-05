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

  describe 'quoting IPAddr in sql statement' do
    it 'properly converts IPAddr to quoted strings when passed as an argument to a where clause' do
      Place.where(:address => GeometryFactory.point).to_sql.should include("SRID=4326;POINT(1 2)")
    end
  end

  # describe 'cotained with (<<) operator' do
  #   it 'converts Arel contained_within statemnts to <<' do
  #     arel_table = IpAddress.arel_table

  #     arel_table.where(arel_table[:address].contained_within(IPAddr.new('127.0.0.1/24'))).to_sql.should match /<< '127.0.0.0\/24'/
  #   end
  # end
end
