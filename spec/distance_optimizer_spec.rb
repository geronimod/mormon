require 'spec_helper'
require 'mormon'

def _spec_osm_file
  File.join File.dirname(__FILE__), "map.osm"
end

describe Mormon::OSM::DistanceOptimizer do
   def stops_for_test()
      nodes = []
      node1 = Mormon::OSM::StopNode.new()
      node1.road = "Albanigade"
      node1.house_number = "5"
      node1.zip_code = "5000"
      node1.node_id = 320168440
      node1.distance = ""
      nodes.push node1

      node2 = Mormon::OSM::StopNode.new()
      node2.road = "Nonnebakken"
      node2.house_number = "8"
      node2.zip_code = "5000"
      node2.node_id = 1665865875
      node2.distance = ""
      nodes.push node2

      node3 = Mormon::OSM::StopNode.new()
      node3.road = "Kronprinsensgade"
      node3.house_number = "12"
      node3.zip_code = "5000"
      node3.node_id = 87280124
      node3.distance = ""
      nodes.push node3

      node4 = Mormon::OSM::StopNode.new()
      node4.road = "Allegade"
      node4.house_number = "58"
      node4.zip_code = "5000"
      node4.node_id = 275977555
      node4.distance = ""
      nodes.push node4

      node5 = Mormon::OSM::StopNode.new()
      node5.road = "Alexandragade"
      node5.house_number = "13"
      node5.zip_code = "5000"
      node5.node_id = 266138285
      node5.distance = ""
      nodes.push node5

      node6 = Mormon::OSM::StopNode.new()
      node6.road = "Allegade"
      node6.house_number = "34"
      node6.zip_code = "5000"
      node6.node_id = 275977558
      node6.distance = ""
      nodes.push node6

      node7 = Mormon::OSM::StopNode.new()
      node7.road = "Albanigade"
      node7.house_number = "23"
      node7.zip_code = "5000"
      node7.node_id = 205071329
      node7.distance = ""
      nodes.push node7

      node8 = Mormon::OSM::StopNode.new()
      node8.road = "Benediktsgade"
      node8.house_number = "44"
      node8.zip_code = "5000"
      node8.node_id = 112240951
      node8.distance = ""
      nodes.push node8

      return nodes
   end

  describe "Initializing test" do

    it "Array correct length" do
      stops = stops_for_test
      stops.length.should eq 8
    end

    it "Should be sorted the initialized in correct order for sorting" do
      stops = stops_for_test
      stops[0].node_id.should eq 320168440
      stops[1].node_id.should eq 1665865875
      stops[2].node_id.should eq 87280124
      stops[3].node_id.should eq 275977555
      stops[4].node_id.should eq 266138285
      stops[5].node_id.should eq 275977558
      stops[6].node_id.should eq 205071329
      stops[7].node_id.should eq 112240951
    end

  end

  describe "Final result" do
    it "should have sorted the array and calculated the correct distances" do
      loader = Mormon::OSM::Loader.new _spec_osm_file
      stops = stops_for_test
      route = Mormon::OSM::DistanceOptimizer.route_planer(stops, loader)

      route[0].node_id.should eq 320168440
      route[1].node_id.should eq 205071329
      route[2].node_id.should eq 87280124
      route[3].node_id.should eq 1665865875
      route[4].node_id.should eq 266138285
      route[5].node_id.should eq 112240951
      route[6].node_id.should eq 275977558
      route[7].node_id.should eq 275977555

      route[0].distance.should eq 0.0
      route[1].distance.should eq 322.04
      route[2].distance.should eq 364.36
      route[3].distance.should eq 690.44
      route[4].distance.should eq 699.35
      route[5].distance.should eq 785.7
      route[6].distance.should eq 996.89
      route[7].distance.should eq 1274.89
    end
  end
end
