require 'nokogiri'
require 'debugger'

module Mormon
  module OSM
    class Loader
      attr_reader :options, :routing

      def initialize(filename, options = {})
        @options = options

        @tiles = {}
        @nodes = {}
        @ways  = {}
        
        @store_map   = options[:store_map] if options[:store_map]
        @store_map ||= true 
        
        @routing = {}
        @routeable_nodes = {}
        @route_types = [:cycle, :car, :train, :foot, :horse]

        @route_types.each do |type|
          @routing[type] = {}
          @routeable_nodes[type] = {}
        end

        @tilename  = Mormon::Tile::Name.new
        @tiledata  = Mormon::Tile::Data.new

        parse filename
      end

      # @unused: load the specific area instead an osm file
      def load_area(lat, lon)
        if options[:file]
          puts "The %s file was already loaded" % options[:file]
          return
        end
        
        # Download data in the vicinity of a lat/long
        z = Mormon::Tile::Data.download_level
        (x,y) = @tilename.xy(lat, lon, z)

        tile_id = '%d,%d' % [x, y]
        
        return if @tiles[tile_id]
        
        @tiles[tile_id] = true
        
        filename = @tiledata.get_osm(z, x, y)
        # print "Loading %d,%d at z%d from %s" % (x,y,z,filename)
        
        parse filename
      end

      def parse(filename)
        puts "Loading %s.." % filename
        
        if !File.exists?(filename)
          print "No such data file %s" % filename
          return false
        end
        
        osm = Nokogiri::XML(File.open(filename))

        load_nodes osm
        load_ways osm
      end

      def load_nodes(nokosm)
        nokosm.css('node').each do |node|
          node_id = node[:id]
          
          @nodes[node_id] = {
            lat: node[:lat].to_f,
            lon: node[:lon].to_f,
            tags: {}
          }
          
          node.css('tag').each do |t|
            k,v = t[:k].to_sym, t[:v]
            @nodes[node_id][:tags][k] = v unless useless_tags.include?(k)
          end
        end
      end
      private :load_nodes

      def load_ways(nokosm)
        nokosm.css('way').each do |way|
          way_id = way[:id]
          
          @ways[way_id] = {
            nodes: way.css('nd').map { |nd| nd[:ref] },
            tags: {}
          }
          
          way.css('tag').each do |t|
            k,v = t[:k].to_sym, t[:v]
            @ways[way_id][:tags][k] = v unless useless_tags.include?(k)
          end

          store_way @ways[way_id]
        end
      end
      private :load_ways

      def useless_tags
        [:created_by]
      end
      private :useless_tags
  
      def way_access(highway, railway)
        access = {}
        access[:cycle] = [:primary, :secondary, :tertiary, :unclassified, :minor, :cycleway, 
                          :residential, :track, :service].include? highway.to_sym
        
        access[:car]   = [:motorway, :trunk, :primary, :secondary, :tertiary, 
                          :unclassified, :minor, :residential, :service].include? highway.to_sym
        
        access[:train] = [:rail, :light_rail, :subway].include? railway.to_sym
        access[:foot]  = access[:cycle] || [:footway, :steps].include?(highway.to_sym)
        access[:horse] = [:track, :unclassified, :bridleway].include? highway.to_sym
        access
      end
      private :way_access

      def store_way(way)
        tags = way[:tags]

        highway    = equivalent tags.fetch(:highway, "")
        railway    = equivalent tags.fetch(:railway, "")
        oneway     = tags.fetch(:oneway, "")
        reversible = !['yes','true','1'].include?(oneway)
        
        access = way_access highway, railway

        # Store routing information
        last = -1
        way[:nodes].each do |node|
          if last != -1
            @route_types.each do |route_type|
              if access[route_type]
                weight = Mormon::Weight.get route_type, highway.to_sym
                add_link(last, node, route_type, weight)
                add_link(node, last, route_type, weight) if reversible || route_type == :foot
              end  
            end
          end
          last = node
        end
      end

      def routeable_from(node, route_type)
        @routeable_nodes[route_type][node] = 1
      end

      def add_link(fr, to, route_type, weight = 1)
        routeable_from fr, route_type
        return if @routing[route_type][fr].keys.include?(to)
        @routing[route_type][fr][to] = weight
      rescue
        @routing[route_type][fr] = { to => weight }
      end

      def way_type(tags)
        # Look for a variety of tags (priority order - first one found is used)
        [:highway, :railway, :waterway, :natural].each do |type|
          value = tags.fetch(type, '')
          return equivalent(value) if value
        end
        nil
      end

      def equivalent(tag)
        { 
          primary_link:   "primary",
          trunk:          "primary",
          trunk_link:     "primary",
          secondary_link: "secondary",
          tertiary:       "secondary",
          tertiary_link:  "secondary",
          residential:    "unclassified",
          minor:          "unclassified",
          steps:          "footway",
          driveway:       "service",
          pedestrian:     "footway",
          bridleway:      "cycleway",
          track:          "cycleway",
          arcade:         "footway",
          canal:          "river",
          riverbank:      "river",
          lake:           "river",
          light_rail:     "railway"
        }[tag] || tag
      end
    
      def find_node(lat, lon)
        # find the nearest node that can be the start of a route
        load_area(lat, lon)
        max_dist   = 1E+20
        node_found = nil
        pos_found  = nil
        
        rnodes.values.each do |node_id, pos|
          dy = pos[0] - lat
          dx = pos[1] - lon
          dist = dx * dx + dy * dy
          
          if dist < maxDist
            max_dist = dist
            node_found = node_id
            pos_found = pos
          end
          
          node_found
        end
      end
      
      def report
        report = "Loaded %d nodes,\n" % @nodes.keys.size
        report += "%d ways, and...\n" % @ways.keys.size
        
        @route_types.each do |type|
          report += " %d %s routes\n" % [@routing[type].keys.size, type]
        end

        report
      end
    end
  end
end

