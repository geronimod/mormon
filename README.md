Mormon
======

OSM Routing in Ruby, based on pyroutelib2

Usage of OSM route
==================

      osm_loader = Mormon::OSM::Loader.new "path/to/file.osm"
      osm_router = Mormon::OSM::Router.new osm_loader
      osm_router.find_route node_start, node_end, transport

- Notes:
  - transports: must be one in [:cycle, :car, :train, :foot, :horse]
  - node_start and node_end must be node ids associated with ways in osm (``<way ...> <nd ref="node_id"/</way>``)

Usage of OSM distance optimizer
================================

      osm_loader = Mormon::OSM::Loader.new "path/to/file.osm"
      osm_router = Mormon::OSM::Router.new osm_loader
      route = osm_distance_optimizer.route_planer(*Array of Mormon::OSM::StopNode where at least node_id has value*, osm_loader)

      - The route is a sorted array where each node is succeeded by the closest (not already visited). The stop nodes all have updated the distance value to represent the distance to the predecessor.
      - The total distance of the route can be calculated by summing up all the distances

- Notes
  - All distances are measures in meters
  - The calculation is not accurate:
    - The calculation of latitude and longitude degrees are done by the algorithms from [http://en.wikipedia.org/wiki/Latitude](http://en.wikipedia.org/wiki/Latitude)
    - The length of one degree is calculated as the average between latitude and longitude for simplicity as heading is not included. Which can be misleading in areas where the differences between these are high (close to the poles)
    - In Denmark (11.000000,56.000000) this results in a margin of < 10 meters and together with gps-fixes this would be a estimated total of +/- 10%
  - A route is considered an array of stops. The distance between stops (paths) is summed up by the distance between the OSM nodes.

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

**KNOWN ISSUE**: the actual random algorithm has problems when the different between start and end is enough far, i'm working to fix it.

Breadth in random algorithm
-----

The programming technique to find a random route is Backtracking, so in order to don't loop forever we need to narrow the search in neighbors, for that reason i use a breadth value combined with distance between start and end nodes:

      max_amplitude = @breadth * distance(start, end)

The default breadth value is 2 but you could change it doing one of:

      osm_router = Mormon::OSM::Router.new osm_loader, :algorithm => :random, :breadth => 1.5
      or
      osm_router.algorithm.breath = 2.5

License
=======

LICENSE.txt