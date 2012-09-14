module Mormon
  module Tile
    class Name

      # "http://cassini.toolserver.org:8080/"
      # "http://a.tile.openstreetmap.org/"
      # "http://toolserver.org/~cmarqu/hill/",
      # "http://tah.openstreetmap.org/Tiles/tile/"
      LAYERS_URL = {
        tah:    "http://a.tile.openstreetmap.org/",
        oam:    "http://oam1.hypercube.telascience.org/tiles/1.0.0/openaerialmap-900913/",
        mapnik: "http://tile.openstreetmap.org/mapnik/"
      }

      def edges(x, y, z)
        lat1, lat2 = lat_edges(y, z)
        lon1, lon2 = lon_edges(x, z)
        [lat2, lon1, lat1, lon2] # S,W,N,E
      end

      def px_size
        256
      end

      def layer_ext(layer)
        layer == 'oam' ? 'jpg' : 'png'
      end

      def layer_base(layer)
        LAYERS_URL[layer]
      end

      def url(x, y, z, layer = :mapnik)
        "%s%d/%d/%d.%s" % [layer_base(layer), z, x, y, layer_ext(layer)]
      end

      def xy(lat, lon, z)
        x, y = latlon_2_xy(lat, lon, z)
        [x.to_i, y.to_i]
      end

      def xy_2_latlon(x, y, z)
        n = num_tiles(z)
        rel_y = y / n
        lat = mercator_to_lat(Math::PI * (1 - 2 * rel_y))
        lon = -180.0 + 360.0 * x / n
        [lat, lon]
      end


      private

      def num_tiles(z)
        2 ** z.to_f
      end

      def sec(x)
        1 / Math.cos(x)
      end

      def latlon_2_relative_xy(lat,lon)
        x = (lon + 180) / 360
        y = (1 - Math.log(Math.tan(to_radians(lat)) + sec(to_radians(lat))) / Math::PI) / 2
        [x,y]
      end

      def to_radians(degrees)
        degrees * Math::PI / 180
      end

      def to_degrees(radians)
        radians * 180 / Math::PI
      end

      def latlon_2_xy(lat, lon, z)
        n = num_tiles(z)
        x, y = latlon_2_relative_xy(lat, lon)
        [n * x, n * y]
      end
        
      def mercator_to_lat(mercator_y)
        to_degrees Math.atan(Math.sinh(mercator_y))
      end
        
      def lat_edges(y, z)
        n = num_tiles(z)
        unit = 1 / n
        rel_y1 = y * unit
        rel_y2 = rel_y1 + unit
        lat1 = mercator_to_lat(Math::PI * (1 - 2 * rel_y1))
        lat2 = mercator_to_lat(Math::PI * (1 - 2 * rel_y2))
        [lat1, lat2]
      end

      def lon_edges(x, z)
        n = num_tiles(z)
        unit = 360 / n
        lon1 = -180 + x * unit
        lon2 = lon1 + unit
        [lon1, lon2]
      end
    end
  end
end

# tile = Mormon::Tile::Name.new

# (0..16).each do |z|
#   x, y = tile.xy 51.50610, -0.119888, z
#   s, w, n, e = tile.edges(x, y, z)
#   # puts tile.url(x,y,z, :tah)
# end
