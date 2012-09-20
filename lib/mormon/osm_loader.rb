require 'nokogiri'
require 'debugger'

module Mormon
  module OSM
    class Loader
      attr_reader :options, :routing

      def initialize(filename, options = {})
        @options = options
        @tiles   = {}
        
        @routing = {}
        @routeable_nodes = {}
        @route_types = [:cycle, :car, :train, :foot, :horse]

        @route_types.each do |type|
          @routing[type] = {}
          @routeable_nodes[type] = {}
        end

        @nodes = {}
        @ways  = []
        
        @store_map = !!options[:store_map]
        
        @weights   = Mormon::Weight.weightings
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
        
        osm.css('node').each do |node|
          @nodes[node[:id]] = {
            lat: node[:lat].to_f,
            lon: node[:lon].to_f,
            tags: {}
          }
          
          node.css('tag').each do |t| 
            @nodes[node[:id]][:tags][t[:k]] = t[:v] unless t[:k] == :created_by
          end
        end

        osm.css('way').each do |way|
          @ways[]
        end

        osm.css('tag').each do |tag|
          @tags[tag[:k]] = tag[:v] unless tag[:k] == :created_by
        end


      end
  
      def store_way(way_id, tags, nodes)
        highway = equivalent tags[:highway]
        railway = equivalent tags[:railway]
        oneway  = tags[:oneway]
        reversible = !['yes','true','1'].include?(oneway)

        # Calculate what vehicles can use this route
        # TODO: just use getWeight != 0
        access = {}
        access[:cycle] = [:primary, :secondary, :tertiary, :unclassified, :minor, :cycleway, 
                          :residential, :track, :service].include? highway
        
        access[:car] = [:motorway, :trunk, :primary, :secondary, :tertiary, 
                        :unclassified, :minor, :residential, :service].include? highway
        
        access[:train] = [:rail, :light_rail, :subway].include? railway
        access[:foot]  = access[:cycle] || [:footway, :steps].include?(highway)
        access[:horse] = [:track, :unclassified, :bridleway].include? highway

        # i don't know what is the node 41 maybe an exception in pyroute lib
        if (way_id == 41)
          puts nodes
          exit 0
        end

        # Store routing information
        last = Array.new(3)

        nodes.each do |node|
          node_id, x, y = node
          
          if last[0]
            if access[self.transport]
              weight = self.weights.get(self.transport, highway)
              
              add_link(last[0], node_id, weight)
              make_node_routeable(last)

              if reversible or self.transport == 'foot'
                add_link(node_id, last[0], weight)
                make_node_routeable(node)
              end
            end
          end

          last = node
        end
      end

      def make_node_routeable(node)
        self.rnodes[node[0]] = [node[1], node[2]]
      end

      def add_link(fr, to, weight = 1)
        return if self.routing[fr].keys.include?(to)
        self.routing[fr] ||= { to: weight }
        self.routing[fr][to] = weight
      end          

      def equivalent(tag)
        map = {
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
        }
        map[tag] || tag
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
        # Display some info about the loaded data
        puts "Loaded %d nodes" % self.rnodes.keys().size
        puts "Loaded %d %s routes" % [self.routing.keys().size, self.transport]
      end
    end
  end
end

