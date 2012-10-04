require 'spec_helper'

describe PostgresGis::RawGeomInfo do

  it 'not found is not found' do
    PostgresGis::RawGeomInfo.not_found(nil).should_not be_found
  end

  it 'with unknown sql type should not be found' do
    PostgresGis::RawGeomInfo.not_found(nil).should_not be_found
  end

  {
    'point' => {
      geographic: false,
      with_m: false,
      with_z: false,
      srid: 0
    },
    'geometry(point)' => {
      geographic: false,
      with_m: false,
      with_z: false,
      srid: 0
    },
    'geography(point)' => {
      geographic: true,
      with_m: false,
      with_z: false,
      srid: 0
    },
    'geography(point,4326)' => {
      geographic: true,
      with_m: false,
      with_z: false,
      srid: 4326
    },
    'geometry(lineZM,4326)' => {
      geographic: false,
      with_m: true,
      with_z: true,
      srid: 4326
    }
  }.each do |sql_type,pairs|
    context "with type #{sql_type}" do
      subject {
        PostgresGis::RawGeomInfo.from_sql_type(sql_type)
      }
      pairs.each do |name, value|
        it "should have #{name} = #{value}" do
          subject.send(name).should == value
        end
      end
    end
  end
end