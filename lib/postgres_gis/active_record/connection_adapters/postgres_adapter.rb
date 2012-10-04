require 'geo_ruby'
require 'active_record'
require 'postgres_ext'

module ActiveRecord
  module ConnectionAdapters
    DEFAULT_SRID=0
    class PostgreSQLColumn
      attr_reader  :geometry_type, :srid, :with_z, :with_m

      def initialize_with_gis(name, default, sql_type = nil, null = true)
        initialize_without_gis(name, default, sql_type, null)
        @geometry_type = geometry_simplified_type(@sql_type)
        @geographic=false
      end
      alias_method_chain :initialize, :gis

      # was initialize
      def set_gis(srid = DEFAULT_SRID, with_z = false, with_m = false, geographic = false)
        @srid = srid || DEFAULT_SRID
        @with_z = with_z || false
        @with_m = with_m || false
        @geographic = geographic || false
        self
      end

      def spatial?
        !@geometry_type.nil?
      end

      def geographic?
        !!@geographic
      end

      def klass_with_gis
        spatial? ? GeoRuby::SimpleFeatures::Geometry : klass_without_gis
      end
      alias_method_chain :klass, :gis

      def type_cast_with_gis(*args)
        spatial? ? self.class.string_to_geometry(args.first) : type_cast_without_gis(*args)
      end
      alias_method_chain :type_cast, :gis

      def type_cast_code_with_gis(var_name)
        spatial? ? "#{self.class.name}.string_to_geometry(#{var_name})" : type_cast_code_without_gis(var_name)
      end
      alias_method_chain :type_cast_code, :gis

      #Transforms a string to a geometry. PostGIS returns a HewEWKB string.
      def self.string_to_geometry(string)
        return string unless string.is_a?(String)
        GeoRuby::SimpleFeatures::Geometry.from_hex_ewkb(string) rescue nil
      end

      private


      def simplified_type_with_gis(field_type)
        case field_type
        when /geography|geometry|linestring|multipoint|multilinestring|multipolygon|geometrycollection/i then :string
        else simplified_type_without_gis(field_type)
        end
      end
      alias_method_chain :simplified_type, :gis

      # # less simplified geometric type to be use in migrations
      def geometry_simplified_type(field_type)
        case field_type
        when /point/i then :point
        when /polygon/i then :polygon
        when /geometry/i then :geometry
        when /geography/i then :geometry
        end
      end
    end

    class PostgreSQLAdapter
      GIS_TYPES = 
      {
        :point => { :name => "POINT" },
        :polygon => { :name => "POLYGON" },
        :geometry => { :name => "GEOMETRY"}
      }
      def self.geometry_data_types
        GIS_TYPES
      end
      #already defined by postgres_ext
      class ColumnDefinition
        attr_accessor :table_name, :srid, :with_z, :with_m, :geographic
        attr_reader :spatial

        def spatial?
          spatial
        end
        #TODO: was initialize
        def set_gis(srid=DEFAULT_SRID, with_z=false, with_m=false, geographic=false)
          @table_name = nil
          @spatial = true
          @srid = srid || DEFAULT_SRID
          @with_z = with_z || false
          @with_m = with_m || false
          @geographic = geographic || false
        end

        def sql_type_with_gis
          if spatial?
            type_sql = GIS_TYPES[type.to_sym][:name]
            type_sql += "Z" if with_z
            type_sql += "M" if with_m
            # SRID is not yet supported (defaults to 4326)
            type_sql += ", #{srid}" if (srid && srid != DEFAULT_SRID)
            type_sql = "#{geographic ? 'geography' : 'geometry'}(#{type_sql})" unless ['geography', 'geometry'].include? type.to_sym
            type_sql
          else
            sql_type_without_gis
          end
        end
        alias_method_chain :sql_type, :gis
      end

      class TableDefinition
        GIS_TYPES.keys.map(&:to_s).each do |column_type|
          class_eval <<-EOV, __FILE__, __LINE__ + 1
            def #{column_type}(*args)                                   # def string(*args)
              options = args.extract_options!                           #   options = args.extract_options!
              column_names = args                                       #   column_names = args
              type = :'#{column_type}'                                  #   type = :string
              column_names.each { |name| column(name, type, options) }  #   column_names.each { |name| column(name, type, options) }
            end                                                         # end
          EOV
        end

        def column_with_gis(name, type=nil, options = {})
          column_without_gis(name, type, options)
          if GIS_TYPES[type.to_sym]
            #NOTE: spatial code had || ColumnDefinition.new(@base.name, type)
            column = self[name] #NOTE: #ColumnDefinition
            column.set_gis(options[:srid], options[:with_z], options[:with_m], options[:geographic])
            #TODO: geographic - does that change the type?
          end
          self
        end
        alias_method_chain :column, :gis
      end

      class Table
        GIS_TYPES.keys.map(&:to_s).each do |column_type|
          class_eval <<-EOV, __FILE__, __LINE__ + 1
            def #{column_type}(*args)                                          # def string(*args)
              options = args.extract_options!                                  #   options = args.extract_options!
              column_names = args                                              #   column_names = args
              type = :'#{column_type}'                                         #   type = :string
              column_names.each do |name|                                      #   column_names.each do |name|
                column = ColumnDefinition.new(@base, name.to_s, type)          #     column = ColumnDefinition.new(@base, name, type)
                if options[:limit]                                             #     if options[:limit]
                  column.limit = options[:limit]                               #       column.limit = options[:limit]
                elsif native[type].is_a?(Hash)                                 #     elsif native[type].is_a?(Hash)
                  column.limit = native[type][:limit]                          #       column.limit = native[type][:limit]
                end                                                            #     end
                column.precision = options[:precision]                         #     column.precision = options[:precision]
                column.scale = options[:scale]                                 #     column.scale = options[:scale]
                column.default = options[:default]                             #     column.default = options[:default]
                column.null = options[:null]                                   #     column.null = options[:null]
                @base.add_column(@table_name, name, column.sql_type, options)  #     @base.add_column(@table_name, name, column.sql_type, options)
              end                                                              #   end
            end                                                                # end
          EOV
        end
      end

      NATIVE_DATABASE_TYPES.merge!(GIS_TYPES)
      #def native_database_types

      #PostgreSQLAdapter
      def postgis_version
        select_value("SELECT postgis_full_version()").scan(/POSTGIS="([\d\.]*)["| ]/)[0][0]
      rescue ActiveRecord::StatementInvalid
        nil
      end

      def postgis_major_version
        version = postgis_version
        version ? version.scan(/^(\d)\.\d\.\d$/)[0][0].to_i : nil
      end

      def postgis_minor_version
        version = postgis_version
        version ? version.scan(/^\d\.(\d)\.\d$/)[0][0].to_i : nil
      end

      def spatial?
        !postgis_version.nil?
      end

      def supports_geographic?
        postgis_major_version > 1 || (postgis_major_version == 1 && postgis_minor_version >= 5)
      end

      #typically value, column
      #postgres_ext has value, column, part_array = false
      def type_cast_with_gis(*args)
        value, column, _ = args
        if value.nil?
          if column.spatial?
            value
          else
            type_cast_without_gis(*args)
          end
        elsif value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
          geometry_to_string(value)
        else
          type_cast_without_gis(*args)
        end
      end
      alias_method_chain :type_cast, :gis

      def quote_with_gis(value, column = nil)
        if value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
          "'#{type_cast(value, column)}'"
        else
          quote_without_gis(value,column)
        end
      end
      alias_method_chain :quote, :gis

      #overriding a simple active record method
      #TODO: need better way for this
      def columns(table_name, name = nil) #:nodoc:
        raw_geom_infos = column_spatial_info(table_name)

        cdef = column_definitions(table_name)
        cdef = cdef.collect(&:values) if cdef.size > 0 && cdef.first.is_a?(Hash)
        cdef.collect do |name, type, default, notnull|
          col = ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(name, default, type, notnull == "f")
          case type
          when /geography/i
            raw_geom_info = PostgresGis::RawGeomInfo.from_sql_type(type)
            col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m, raw_geom_info.geographic)
          when /geometry/i
            raw_geom_info = PostgresGis::RawGeomInfo.from_sql_type(type)
            if raw_geom_info.found?
              #new(name, default, raw_geom_info.type, notnull == "f",
                #raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m)
              col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m, raw_geom_info.geographic)
            else
              #create_simplified(name, default, notnull == "f")
              col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m, raw_geom_info.geographic)
            end
          when /^(?:point|line|lseg|box|"?path"?|polygon|circle)$/i
            raw_geom_info = PostgresGis::RawGeomInfo.from_sql_type(type) #keep the type as col.type
            col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m, raw_geom_info.geographic)
          end
          col
        end
      end

      #   #TODO: this is no longer necessary, remove and see if things are still created
      #  def type_to_sql_with_gis(type, limit = nil, precision = nil, scale = nil)
      #     if spatial && !geographic
      #       type_sql = GIS_TYPES[type.to_sym][:name]
      #       type_sql += "M" if with_m and !with_z
      #       if with_m and with_z
      #         dimension = 4
      #       elsif with_m or with_z
      #         dimension = 3
      #       else
      #         dimension = 2
      #       end
      #     else
      #       to_sql_without_gis
      #     end
      #    type_to_sql_without_gis
      #  end
      #  alias_method_chain :type_to_sql, :gis

      private

      def tables_without_postgis
        tables - %w{ geometry_columns spatial_ref_sys }
      end

      #TODO: revisit
      def column_spatial_info(table_name)
        # if this Postgres DB does not contain a geometry_columns table,
        # PostGIS shapes are not used there
        # in that case, just return the empty object
        geometry_columns = select_value("select count(*) from information_schema.tables where table_name = 'geometry_columns'").to_i
        return {} if geometry_columns == 0
        constr = select_rows("SELECT * FROM geometry_columns WHERE f_table_name = '#{table_name}'")

        raw_geom_infos = {}
        constr.each do |geo_col|
          info = raw_geom_infos[geo_col[3]] ||= PostgresGis::RawGeomInfo.new
          info.type = geo_col[6]
          info.srid = geo_col[5].to_i # default SRDI of 0
          info.dimension = geo_col[4].to_i

          if info.type[6] == ?M #last column is #6. is this looking for the letter M in there?
            info.with_m = true
            info.type.chop!
          else
            info.with_m = false
          end
        end

        raw_geom_infos.each_value do |raw_geom_info|
          #check the presence of z and m
          raw_geom_info.convert!
        end

        raw_geom_infos
      end

      def geometry_to_string(value)
        value.as_hex_ewkb
      end
    end
  end
end
#TODO: revisit
module PostgresGis
  class RawGeomInfo < Struct.new(:type, :srid, :dimension, :with_z, :with_m, :geographic, :found) #:nodoc:
    def convert!
      self.type ||= "geometry"
      self.geographic ||= false
      self.srid ||= self.srid.to_i #ActiveRecord::ConnectionAdapters::DEFAULT_SRID

      if dimension == 4
        self.with_m = true
        self.with_z = true
      elsif dimension == 3
        if with_m
          self.with_z = false
          self.with_m = true 
        else
          self.with_z = true
          self.with_m = false
        end
      else
        self.with_z = false
        self.with_m = false
      end
      self
    end
    #temporary - going away
    def found?
      found != false
    end

    def self.not_found(sql_type, geographic=false)
      new(sql_type, ActiveRecord::ConnectionAdapters::DEFAULT_SRID, nil, false, false, geographic, false)
    end

    def self.from_sql_type(sql_type)
      if sql_type =~ /(geography|geometry)?(?:\((?:\w+?)(Z)?(M)?(?:,(\d+))?\))?/i
        new(sql_type, $4.to_i, nil, !!$2, !!$3, $1 == 'geography')
      else
        not_found(sql_type, sql_type.include?('geography'))
      end
    end
  end
end
