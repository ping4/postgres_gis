# # class BasicModel < ActiveRecord::Base
# # end
# # class GeoModel < ActiveRecord::Base
# # end


class PointModel < ActiveRecord::Base
  attr_accessible :more_extra
  attr_accessible :extra,:geom
end

# class LineStringModel < ActiveRecord::Base
# end

class PolygonModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

# class MultiPointModel < ActiveRecord::Base
# end

# class MultiLineStringModel < ActiveRecord::Base
# end

# class MultiPolygonModel < ActiveRecord::Base
# end

# class GeometryCollectionModel < ActiveRecord::Base
# end

class GeometryModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

class PointzModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

class PointmModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

class Point4Model < ActiveRecord::Base
  attr_accessible :extra,:geom
end

class GeographyPointModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

# class GeographyLineStringModel < ActiveRecord::Base
# end

class GeographyPolygonModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

# class GeographyMultiPointModel < ActiveRecord::Base
# end

# class GeographyMultiLineStringModel < ActiveRecord::Base
# end

# class GeographyMultiPolygonModel < ActiveRecord::Base
# end

# class GeographyGeometryCollectionModel < ActiveRecord::Base
# end

# class GeographyModel < ActiveRecord::Base
# end

class GeographyPointzModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

class GeographyPointmModel < ActiveRecord::Base
  attr_accessible :extra,:geom
end

class GeographyPoint4Model < ActiveRecord::Base
  attr_accessible :extra,:geom
end
