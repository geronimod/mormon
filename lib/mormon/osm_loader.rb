require 'nokogiri'
require 'tmpdir'

module Mormon
  module OSM
    class Loader
      
      @route_types = [:cycle, :car, :train, :foot, :horse]
      @cache_dir   = File.join Dir.tmpdir, "mormon", "cache"
      
      class << self
        attr_reader   :route_types
        attr_accessor :cache_dir
      end
      
      attr_reader :options, :routing, :nodes, :ways, :tiles, :routeable_nodes, :route_types,
                  :osm_filename

      def initialize(filename, options = {})
        @options = options

        @tiles = {}
        @nodes = {}
        @ways  = {}
        
        @routing = {}
        @routeable_nodes = {}

        Loader.route_types.each do |type|
          @routing[type] = {}
          @routeable_nodes[type] = {}
        end

        # @tilename  = Mormon::Tile::Name.new
        # @tiledata  = Mormon::Tile::Data.new

        @osm_filename = filename
        @options[:cache] ? load_cached : parse
      end

      def report
        report = "Loaded %d nodes,\n" % @nodes.keys.size
        report += "%d ways, and...\n" % @ways.keys.size
        
        Loader.route_types.each do |type|
          report += " %d %s routes\n" % [@routing[type].keys.size, type]
        end

        report
      end

      def cache_filename
        File.join Loader.cache_dir, File.basename(@osm_filename) + ".pstore"
      end
      
      private
        def load_cached
          require "pstore"
            
          store_path = cache_filename

          FileUtils.mkdir_p Loader.cache_dir
          FileUtils.touch store_path
          
          store = PStore.new store_path
          
          if !File.zero? store_path
            puts "Loading from cache %s..." % store.path

            store.transaction(true) do
              @tiles = store[:tiles]
              @nodes = store[:nodes]
              @ways  = store[:ways]
              @tiles = store[:tiles]

              Loader.route_types.each do |type|
                @routing[type]         = store[:routing][type]
                @routeable_nodes[type] = store[:routeable_nodes][type]
              end
            end
          
          else
            puts "Parsing %s..." % @osm_filename
            parse

            puts "Creating cache %s..." % store.path
            store.transaction do
              store[:tiles] = @tiles
              store[:nodes] = @nodes
              store[:ways]  = @ways  
              store[:tiles] = @tiles

              store[:routing]         = {}
              store[:routeable_nodes] = {}

              Loader.route_types.each do |type|
                store[:routing][type]         = @routing[type]
                store[:routeable_nodes][type] = @routeable_nodes[type]
              end
            end
          end

        end

        def parse
          puts "Loading %s.." % @osm_filename
          
          if !File.exists?(@osm_filename)
            print "No such data file %s" % @osm_filename
            return false
          end
          
          osm = Nokogiri::XML File.open(@osm_filename)

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

        def useless_tags
          [:created_by]
        end
    
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
              Loader.route_types.each do |route_type|
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
            light_rail:     "railway",
            living_street:  "unclassified"
          }[tag.to_sym] || tag
        end
      
    end
  end
end

