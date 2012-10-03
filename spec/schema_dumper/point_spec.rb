require 'spec_helper'

describe 'point schema dump' do
  it 'correctly generates point geometry schema dumps' do
    output = schema_for :testing do |t|
      t.point :point_1, :geographic => false
    end

    output.should match /t\.point "point_1".*/
    output.should_not match /t\.point "point_1".*geographic/
  end

  it 'correctly generates point geography schema dumps' do
    output = schema_for :testing do |t|
      t.point :point_1, :geographic => true
    end

    output.should match /t\.point "point_1".*geographic => true/
  end
end
