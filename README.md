Mormon
======

OSM Routing in Ruby, based on pyroutelib2

Usage
=====

      osm_loader = Mormon::OSM::Loader.new "path/to/file.osm"
      osm_router = Mormon::OSM::Router.new osm_loader
      osm_router.find_route node_start, node_end, transport

- Notes:
  - trasnports: must be one in [:cycle, :car, :train, :foot, :horse]
  - node_start and node_end must be node ids

Caching
=======

You probably wants to cache the parsed osm file:
      
      osm_loader = Mormon::OSM::Loader.new "path/to/filename.osm", :cache => true   

The previous code generate a filename.pstore file and it's stored in Dir.tmpdir, "mormon", "cache" depending of your so, if you need to change the cache dir try ie:
      
      cache_dir = File.join File.dirname(__FILE__), "cache"
      Mormon::OSM::Loader.cache_dir = cache_dir
      osm_loader = Mormon::OSM::Loader.new "path/to/file.osm", :cache => true


Routing algorithm
=======

The default algorithm is A* with weights, but a Random algorithm is available, it traces a random route from start to end:

      osm_loader = Mormon::OSM::Loader.new "path/to/file.osm"
      osm_router = Mormon::OSM::Router.new osm_loader, :algorithm => :random
      osm_router.find_route node_start, node_end, transport

Breadth in Ramdom algorithm
-----

The programming technique to find a random route is Backtracking, so in order to don't loop forever we need to narrow the search in neighbors, for that reason i use a breadth value combined with distance between start and end nodes:
      
      max_amplitude = @breadth * distance(start, end)

The default breadth value is 2 but you could change it doing one of:
    
      osm_router = Mormon::OSM::Router.new osm_loader, :algorithm => :random, :breadth => 1.5
      or
      osm_router.algorithm.breath = 2.5

License
=======

- I don't like copyright stuff so do WTFYW. 