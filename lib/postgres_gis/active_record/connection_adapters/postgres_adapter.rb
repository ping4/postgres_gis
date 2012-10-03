require 'geo_ruby'
require 'active_record'
require 'postgres_ext'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLColumn
      attr_reader  :geometry_type, :srid, :with_z, :with_m

      def initialize_with_gis(name, default, sql_type = nil, null = true)
        initialize_without_gis(name, default, sql_type, null)
        @geometry_type = geometry_simplified_type(@sql_type)
        @geographic=false
      end
      alias_method_chain :initialize, :gis

      # was initialize
      def set_gis(srid = -1, with_z = false, with_m = false, geographic = false)
        @srid = srid || -1
        @with_z = with_z || false
        @with_m = with_m || false
        @geographic = geographic || false
      end

      def spatial?
        !@geometry_type.nil?
      end

      def geographic?
        !!@geographic
      end

      def type_cast_with_gis(*args)
        spatial? ? self.class.string_to_geometry(args.first) : type_cast_without_gis(*args)
      end
      alias_method_chain :type_cast, :gis

      def type_cast_code_with_gis(var_name)
        spatial? ? "#{self.class.name}.string_to_geometry(#{var_name})" : type_cast_code_without_gis(var_name)
      end
      alias_method_chain :type_cast_code, :gis

      def klass_with_gis
        spatial? ? GeoRuby::SimpleFeatures::Geometry : klass_without_gis
      end
      alias_method_chain :klass, :gis

      #Transforms a string to a geometry. PostGIS returns a HewEWKB string.
      def self.string_to_geometry(string)
        return string if string.nil? || ! string.is_a?(String)
        GeoRuby::SimpleFeatures::Geometry.from_hex_ewkb(string) rescue nil
      end

      private

      # Maps additional data types to base Rails/Arel types
      #
      # For Rails 3, only the types defined by Arel can be used.  We'll
      # use :string since the database returns the columns as hex strings.
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
        when /^point$/i then :point
        when /^linestring$/i then :line_string
        when /^polygon$/i then :polygon
        when /^geometry$/i then :geometry
        when /multipoint/i then :multi_point
        when /multilinestring/i then :multi_line_string
        when /multipolygon/i then :multi_polygon
        when /geometrycollection/i then :geometry_collection
        #postgis geography
        when /geography\(point/i then :point
        when /geography\(linestring/i then :line_string
        when /geography\(polygon/i then :polygon
        when /geography\(multipoint/i then :multi_point
        when /geography\(multilinestring/i then :multi_line_string
        when /geography\(multipolygon/i then :multi_polygon
        when /geography\(geometrycollection/i then :geometry_collection
        when /geography/i then :geometry
        end
      end
    end

    class PostgreSQLAdapter
      GIS_TYPES = 
      {
        :point => { :name => "POINT" },
        :line_string => { :name => "LINESTRING" },
        :polygon => { :name => "POLYGON" },
        :geometry_collection => { :name => "GEOMETRYCOLLECTION" },
        :multi_point => { :name => "MULTIPOINT" },
        :multi_line_string => { :name => "MULTILINESTRING" },
        :multi_polygon => { :name => "MULTIPOLYGON" },
        :geometry => { :name => "GEOMETRY"}
      }
      #already defined by postgres_ext
      class ColumnDefinition
        attr_accessor :table_name, :srid, :with_z, :with_m, :geographic
        attr_reader :spatial

        #TODO: was initialize
        def set_gis(srid=-1, with_z=false, with_m=false, geographic=false)
          @table_name = nil
          @spatial = true
          @srid = srid || -1
          @with_z = with_z || false
          @with_m = with_m || false
          @geographic = geographic || false
        end

        def sql_type_with_gis
          if geographic
            type_sql = GIS_TYPES[type.to_sym][:name]
            type_sql += "Z" if with_z
            type_sql += "M" if with_m
            # SRID is not yet supported (defaults to 4326)
            #type_sql += ", #{srid}" if (srid && srid != -1)
            type_sql = "geography(#{type_sql})"
            type_sql
          else
            sql_type_without_gis
          end
        end
        alias_method_chain :sql_type, :gis
      end

      class TableDefinition
        #TODO: remove
        def geom_columns
          raise "remote geom_columns (KB)"
        end

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
            @columns << column unless @columns.include? column
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

      def type_cast_with_gis(*args)
        if args.first.kind_of?(GeoRuby::SimpleFeatures::Geometry)
          args.first.as_hex_ewkb
        else
          type_cast_without_gis(*args)
        end
      end
      alias_method_chain :type_cast, :gis

      def quote_with_gis(value, column = nil)
        if value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
          "'#{value.as_hex_ewkb}'"
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
        #column_definitions(table_name).collect do |name, type, default, notnull|
          col = ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(name, default, type, notnull == "f")
          case type
          when /geography/i
            raw_geom_info = PostgresGis::RawGeomInfo.from_sql_type(type)
            col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m, raw_geom_info.geographic)
          when /geometry/i
            raw_geom_info = raw_geom_infos[name] || PostgresGis::RawGeomInfo.not_found("geometry", false)
            if raw_geom_info.found?
              #new(name, default, raw_geom_info.type, notnull == "f",
                #raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m)
              col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m)
            else
              #create_simplified(name, default, notnull == "f")
              col.sql_type = raw_geom_info.type
              col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m)
            end
            @sql_type = raw_geom_info.type
            #col.set_gis(raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m, true)
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
        puts "column_spatial_info short circuit" and return {} if geometry_columns == 0
        constr = select_rows("SELECT * FROM geometry_columns WHERE f_table_name = '#{table_name}'")

        raw_geom_infos = {}
        constr.each do |constr_def_a|
          info = raw_geom_infos[constr_def_a[3]] ||= PostgresGis::RawGeomInfo.new
          info.type = constr_def_a[6]
          info.dimension = constr_def_a[4].to_i
          info.srid = constr_def_a[5].to_i

          if info.type[-1] == ?M
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
    end
  end
end
#TODO: revisit
module PostgresGis
  class RawGeomInfo < Struct.new(:type, :srid, :dimension, :with_z, :with_m, :geographic, :found) #:nodoc:
    def convert!
      self.type ||= "geometry"
      self.geographic ||= false
      self.srid = -1 if self.srid.to_i == 0

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
      new(sql_type, -1, nil, false, false, geographic, false)
    end

    def self.from_sql_type(sql_type)
      if sql_type =~ /geography(?:\((?:\w+?)(Z)?(M)?(?:,(\d+))?\))?/i
        new(sql_type, $3.to_i, nil, $1 == 'Z', $2 == 'M', true).tap { |info|
          info.dimension = (2 + (info.with_z ? 1 : 0) + (info.with_m ? 1 : 0))
        }
      else
        not_found(sql_type, true)
      end
    end
  end
end
