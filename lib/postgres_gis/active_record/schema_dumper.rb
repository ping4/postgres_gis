require 'active_record'
require 'postgres_ext'

ActiveRecord::SchemaDumper.ignore_tables << "spatial_ref_sys" << "geometry_columns"
ActiveRecord::SchemaDumper.valid_column_spec_keys << :srid << :with_z << :with_m << :geographic

module ActiveRecord
  class SchemaDumper
    private

    # Build specification for a table column
    def column_spec_with_gis(column)
      spec = column_spec_without_gis(column)
      spec[:type]    = column.geometry_type.to_s if column.geometry_type
      spec[:srid]    = column.srid.inspect if column.srid && column.srid != -1 && column.srid != 0
      spec[:with_z]  = 'true' if column.with_z
      spec[:with_m]  = 'true' if column.with_m
      spec[:geographic] = 'true' if column.geographic?
      spec.delete(:limit) if column.spatial?
      spec
    end
    alias_method_chain :column_spec, :gis
  end
end