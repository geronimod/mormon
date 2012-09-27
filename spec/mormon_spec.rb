require 'spec_helper'
require 'mormon'

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

describe Mormon::OSM::Loader do
  before :each do
    @loader = Mormon::OSM::Loader.new File.dirname(__FILE__) + "/spec.osm"
  end

  it "should load the correct data" do
    @loader.nodes.keys.size.should eq 534
    @loader.ways.keys.size.should  eq 135
    
    @loader.routing[:cycle].keys.size.should eq 240
    @loader.routing[:car].keys.size.should   eq 240
    @loader.routing[:train].keys.size.should eq 0
    @loader.routing[:foot].keys.size.should  eq 281
    @loader.routing[:horse].keys.size.should eq 216
  end

  it "should has the correct nodes" do
    map = { "448193026" => 1, "448193243" => 1, "448193220" => 1, "318099173" => 1 }
    @loader.routing[:foot]["448193024"].should eq(map)
  end
end

describe Mormon::OSM::Router do
  before :each do
    @loader = Mormon::OSM::Loader.new File.dirname(__FILE__) + "/spec.osm"
    @router = Mormon::OSM::Router.new @loader
  end

  it "should do the routing without problems" do
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
end
