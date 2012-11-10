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

**KNOWN ISSUE**: the actual random algorithm has problems when the different between start and end is enough far, i'm working to fix it.

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

Copyright (c) 2012 Hugo Gerónimo Díaz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.