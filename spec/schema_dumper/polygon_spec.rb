require 'spec_helper'

describe 'polygon schema dump' do
  it 'correctly generates geometry polygon schema dumps' do
    output = schema_for :testing do |t|
      t.polygon :poly_1, :srid => 4326
    end

    output.should match /t\.polygon "poly_1"/
    output.should_not match /t\.polygon "poly_1".*geographic/
  end

  it 'correctly generates point geography polygon schema dumps' do
    output = schema_for :testing do |t|
      t.polygon :poly_1, :srid => 4326, :geographic => true
    end

    output.should match /t\.polygon "poly_1".*geographic => true/
  end
end
