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
  
License
=======

- I don't like copyright stuff so do WTFYW. 