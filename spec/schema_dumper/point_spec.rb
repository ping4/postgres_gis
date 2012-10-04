require 'spec_helper'

describe 'point schema dump' do
  it 'correctly generates point geometry schema dumps' do
    output = schema_for :testing do |t|
      t.point :point_1, :geographic => false, :srid => 4326
    end
    line = output.split("\n").detect {|l| l =~ /t\.point "point_1"/}

    line.should match /:srid => 4326/
    line.should_not match /geographic/
  end

  it 'correctly generates point geography schema dumps' do
    output = schema_for :testing do |t|
      t.point :point_1, :geographic => true
    end
    line = output.split("\n").detect {|l| l =~ /t\.point "point_1"/}

    line.should match /:srid => 4326/
    line.should match /geographic => true/
  end
end
