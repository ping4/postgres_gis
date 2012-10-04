require 'spec_helper'

describe 'polygon schema dump' do
  it 'correctly generates geometry polygon schema dumps' do
    output = schema_for :testing do |t|
      t.polygon :poly_1, :srid => 4326
    end
    line = output.split("\n").detect {|l| l =~ /t\.polygon "poly_1"/}

    line.should match /:srid => 4326/
    line.should_not match /geographic/
  end

  it 'correctly generates point geography polygon schema dumps' do
    output = schema_for :testing do |t|
      t.polygon :poly_1, :srid => 4326, :geographic => true
    end
    line = output.split("\n").detect {|l| l =~ /t\.polygon "poly_1"/}

    line.should match /:srid => 4326/
    line.should match /geographic => true/
  end
end
