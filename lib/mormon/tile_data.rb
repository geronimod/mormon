require 'open-uri'
require 'fileutils'

module Mormon
  module Tile
    class Data
      TILE_DIR = 'cache/%d/%d/%d'
      TILE_URL = 'http://dev.openstreetmap.org/~ojw/api/?/map/%d/%d/%d'

      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def self.download_level
        # All primary downloads are done at a particular zoom level
        15
      end

      def get_osm(z, x, y)
        # Download OSM data for the region covering a slippy-map tile
        if x < 0 or y < 0 or z < 0 or z > 25
          puts "Disallowed %d,%d at %d" % [x, y, z]
          return
        end
        
        directory = TILE_DIR % [z,x,y]
        FileUtils.mkdir_p(directory) unless Dir.exists?(directory)
        
        if z == Data.download_level
          url = TILE_URL % [z,x,y]
          filename = '%s/data.osm' % directory

          # puts "URL: %s" % url
          # puts "filename: %s" % filename

          # download the data
          if options[:reset_cache] || !File.exists?(filename)
            begin
              open(url) do |content|
                File.new(filename) { |f| f.write content }
              end
              filename
            rescue OpenURI::HTTPError
              "Tile not found in #{url}"
            end
          end
          
        elsif z > Data.download_level
          # use larger tile
          while z > Data.download_level
            z = z - 1
            x = (x / 2).to_i
            y = (y / 2).to_i
          end
          get_osm z, x, y
        end

      end

    end
  end
end

# tile = Mormon::Tile::Data.new :reset_cache => true
# puts tile.get_osm(15, 16218, 10741)
