require 'spec_helper'
require 'mormon'

describe Mormon::Weight do
  it "get (transport, way type) must to return a value" do
    Mormon::Weight.get(:car, :primary).should eq(2)
  end
end