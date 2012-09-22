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
    puts @loader.report
  end

  it "should load tiles of osm file" do
    # @loader.ways.size.should eq(100)
    # @loader.load_area(-37.335867, -59.1230239)
    # @loader.report
    # @loader.find_node(-37.335867, -59.1230239)

  end
end


