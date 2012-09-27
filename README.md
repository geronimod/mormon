Mormon
======

OSM Routing in Ruby, based on pyroutelib2

Ussage
------

      osm_loader = Mormon::OSM::Loader.new "path/to/file.osm"
      osm_router = Mormon::OSM::Router.new osm_loader
      osm_router.find_route node_start, node_end, transport

- Notes:
  - trasnports: must be one in [:cycle, :car, :train, :foot, :horse]
  - node_start and node_end must be node ids
  
License
=======

- WTFYW License