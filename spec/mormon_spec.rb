require 'spec_helper'
require 'mormon'
require 'benchmark'

describe Mormon::Weight do
  it "get (transport, way type) must to return a value" do
    Mormon::Weight.get(:car, :primary).should eq(2)
  end
end

describe Mormon::Tile::Data do
  before :each do
    @tiledata = Mormon::Tile::Data.new :reset_cache => true
  end

  it "download a tile should not work at the moment" do
    @tiledata.get_osm(15, 16218, 10741).should match(/Tile not found/)
  end
end

describe Mormon::Tile::Name do
  before :each do
    @tilename = Mormon::Tile::Name.new
  end

  it "should return the correct xy coordinates" do
    @tilename.xy(51.50610, -0.119888, 16).should eq([32746, 21792])
  end

  it "should return the correct edges" do
    x, y = @tilename.xy(51.50610, -0.119888, 16)
    @tilename.edges(x, y, 16).should eq([51.505323411493336, -0.120849609375, 51.50874245880333, -0.1153564453125])
  end

  it "should return the correct url for the tile" do
    @tilename.url(51.50610, -0.119888, 16, :tah).should eq("http://a.tile.openstreetmap.org/16/51/0.png")
  end
end

def spec_osm_file
  File.join File.dirname(__FILE__), "spec.osm"
end

describe Mormon::OSM::Loader do
  def common_specs(loader)
    loader.nodes.keys.size.should eq 534
    loader.ways.keys.size.should  eq 135
    
    loader.routing[:cycle].keys.size.should eq 240
    loader.routing[:car].keys.size.should   eq 240
    loader.routing[:train].keys.size.should eq 0
    loader.routing[:foot].keys.size.should  eq 281
    loader.routing[:horse].keys.size.should eq 216
  end

  describe "whitout cache" do
    before :each do
      @loader = Mormon::OSM::Loader.new spec_osm_file
    end

    it "should load the correct data" do
      common_specs @loader
    end

    it "should has the correct nodes" do
      map = { "448193026" => 1, "448193243" => 1, "448193220" => 1, "318099173" => 1 }
      @loader.routing[:foot]["448193024"].should eq(map)
    end
  end

  describe "with cache" do
    it "should exists the cached version" do
      @loader = Mormon::OSM::Loader.new spec_osm_file, :cache => true
      File.exists?(@loader.cache_filename).should eq true
      File.zero?(@loader.cache_filename).should eq false
    end

    it "should let change the cache dir" do
      cache_dir = File.join File.dirname(__FILE__), "..", "cache"
      Mormon::OSM::Loader.cache_dir = cache_dir
      @loader = Mormon::OSM::Loader.new spec_osm_file, :cache => true
      cache_filename = File.join Mormon::OSM::Loader.cache_dir, File.basename(spec_osm_file) + ".pstore"
      @loader.cache_filename.should eq cache_filename
    end

    it "should have stored the same data" do
      @without_cache = Mormon::OSM::Loader.new spec_osm_file
      @with_cache    = Mormon::OSM::Loader.new spec_osm_file, :cache => true

      common_specs @without_cache
      common_specs @with_cache

      @without_cache.nodes.should eq @with_cache.nodes
      @without_cache.ways.should  eq @with_cache.ways
      @without_cache.routing.should eq @with_cache.routing
      @without_cache.routeable_nodes.should eq @with_cache.routeable_nodes
    end

  end

end

describe Mormon::OSM::Router do

  it "should do the routing without problems" do
    @loader = Mormon::OSM::Loader.new spec_osm_file
    @router = Mormon::OSM::Router.new @loader

    response, route = @router.find_route 448193311, 453397968, :car
    response.should eq "success"
    route.should eq [
      [-37.322900199999999, -59.1277355], 
      [-37.3234584, -59.1292045], 
      [-37.324045300000002, -59.130744], 
      [-37.324662600000003, -59.132366099999999], 
      [-37.325214799999998, -59.133816899999999], 
      [-37.3263769, -59.133125100000001], 
      [-37.327769600000003, -59.132296199999999], 
      [-37.328298599999997, -59.133707200000003], 
      [-37.328858799999999, -59.135200400000002]
    ]
  end

  describe "with tandil.osm map" do

    before :each do
      @loader = Mormon::OSM::Loader.new File.join(File.dirname(__FILE__), "tandil.osm"), :cache => true
      @router = Mormon::OSM::Router.new @loader
    end

    it "should find the route in tandil map" do
      response, route = @router.find_route 1355012894, 1527759159, :car
      response.should eq "success"
      route.should eq [
        [-37.314227500000001, -59.083028499999998], [-37.315150099999997, -59.084156299999997], [-37.314264299999998, -59.085288499999997], [-37.315238600000001, -59.086456400000003], [-37.316189199999997, -59.087621499999997], [-37.317135299999997, -59.088781099999999], [-37.318047200000002, -59.0898988], [-37.3189803, -59.091042600000002], [-37.319898500000001, -59.092168000000001], [-37.320787299999999, -59.093257399999999], [-37.322678799999998, -59.0955759], [-37.324257199999998, -59.097501700000002], [-37.324342399999999, -59.0976675], [-37.323442, -59.0988349], [-37.322537599999997, -59.099982900000001], [-37.320699099999999, -59.102316899999998], [-37.322715600000002, -59.104815500000001], [-37.325489699999999, -59.1082538], [-37.324572699999997, -59.109404599999998], [-37.325524700000003, -59.1105327], [-37.326417999999997, -59.111670400000001], [-37.325528499999997, -59.112850700000003], [-37.326433199999997, -59.113965700000001], [-37.3267904, -59.114365900000003], [-37.326863699999997, -59.114550399999999], [-37.327440500000002, -59.116081100000002], [-37.327991900000001, -59.1175444], [-37.328552999999999, -59.119033799999997], [-37.329104200000003, -59.120496600000003], [-37.329658899999998, -59.121968600000002], [-37.330206199999999, -59.123420899999999], [-37.330755799999999, -59.124884399999999], [-37.331353300000004, -59.126429899999998], [-37.331652400000003, -59.127241400000003], [-37.331941100000002, -59.128025000000001], [-37.332166700000002, -59.1286238], [-37.332491400000002, -59.129485500000001], [-37.333024999999999, -59.130901999999999], [-37.333594699999999, -59.132413800000002], [-37.333622300000002, -59.132487500000003], [-37.334096700000003, -59.133752299999998], [-37.3345178, -59.134863600000003], [-37.335070399999999, -59.136329799999999], [-37.335618599999997, -59.137819700000001], [-37.3361801, -59.139275699999999], [-37.336721400000002, -59.140712100000002], [-37.337293500000001, -59.1422308], [-37.337850899999999, -59.143710200000001], [-37.338389300000003, -59.145182900000002], [-37.3386736, -59.145893600000001], [-37.338952499999998, -59.146633899999998], [-37.339135499999998, -59.147119699999998], [-37.3394239, -59.147885199999997], [-37.339503100000002, -59.148095499999997], [-37.339592099999997, -59.148331900000002], [-37.339890400000002, -59.149123400000001], [-37.340051299999999, -59.149550599999998], [-37.340075400000003, -59.149608000000001], [-37.340349500000002, -59.150260299999999], [-37.340552099999996, -59.150748700000001], [-37.3406783, -59.151004299999997], [-37.340945599999998, -59.151422500000002], [-37.343685100000002, -59.155270399999999], [-37.343783000000002, -59.155505300000002], [-37.344689199999998, -59.159352699999999], [-37.344747900000002, -59.159703200000003], [-37.344740799999997, -59.159876199999999], [-37.344758900000002, -59.159840699999997], [-37.344792099999999, -59.159806099999997], [-37.344832799999999, -59.159787899999998], [-37.344866199999998, -59.159786500000003], [-37.3449077, -59.159801299999998], [-37.344942699999997, -59.1598331], [-37.344966999999997, -59.159877999999999], [-37.344977100000001, -59.159948700000001], [-37.345046400000001, -59.159815899999998], [-37.345127400000003, -59.159665699999998], [-37.346329400000002, -59.158131699999998], [-37.347191299999999, -59.157031799999999], [-37.348837400000001, -59.154906699999998]
      ]
    end

    it "should find routes :living_street tags" do
      response, route = @router.find_route 1426632434, 1353196058, :car
      response.should eq "success"
      route.should eq [
        [-37.3345933, -59.1058391], [-37.3354931, -59.1069492], [-37.3342806, -59.1084889], [-37.33413, -59.1094705], [-37.3339058, -59.1102717], [-37.3341711, -59.1101928], [-37.3352592, -59.1095233], [-37.3354771, -59.1093932], [-37.3361037, -59.1090191], [-37.3362573, -59.1090405], [-37.3364535, -59.1092337], [-37.3366723, -59.1098382], [-37.3367507, -59.1099664], [-37.3373321, -59.1101778], [-37.33786, -59.1101467], [-37.3386116, -59.1100383], [-37.3394134, -59.1100169], [-37.3400105, -59.1102422], [-37.3401523, -59.1103108], [-37.3410888, -59.1091111]
      ]
    end
  end
end
