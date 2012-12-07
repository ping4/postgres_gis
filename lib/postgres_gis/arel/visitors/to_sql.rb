require 'arel/visitors/to_sql'
module Arel
  module Visitors
    class ToSql
      private
      def visit_Arel_Nodes_GisOverlap o
        "st_distance(#{visit o.left},#{visit o.right},0)"
      end

      def visit_Gis value
        "'#{value.as_ewkt}'"
      end
      alias :visit_GeoRuby_SimpleFeatures_Point :visit_Gis
      alias :visit_GeoRuby_SimpleFeatures_Polygon :visit_Gis
      alias :visit_GeoRuby_SimpleFeatures_MultiPolygon :visit_Gis

      # def change_string value
      #   if value.match /"|,|\{/
      #     value.gsub(/"/, "\"").gsub(/'/,'"')
      #   else
      #     value.gsub(/'/,'')
      #   end
      # end
    end
  end
end
