module Mormon
  class Weight
    # Represents an hipotetical velocity of the transport in the way type
    @weightings = {
      motorway:     { car: 10 },
      trunk:        { car: 10, cycle: 0.05 },
      primary:      { cycle: 0.3, car: 2, foot: 1, horse: 0.1 },
      secondary:    { cycle: 1, car: 1.5, foot: 1, horse: 0.2 },
      tertiary:     { cycle: 1, car: 1, foot: 1, horse: 0.3 },
      unclassified: { cycle: 1, car: 1, foot: 1, horse: 1 },
      minor:        { cycle: 1, car: 1, foot: 1, horse: 1 },
      cycleway:     { cycle: 3, foot: 0.2 },
      residential:  { cycle: 3, car: 0.7, foot: 1, horse: 1 },
      track:        { cycle: 1, car: 1, foot: 1, horse: 1, mtb: 3 },
      service:      { cycle: 1, car: 1, foot: 1, horse: 1 },
      bridleway:    { cycle: 0.8, foot: 1, horse: 10, mtb: 3 },
      footway:      { cycle: 0.2, foot: 1 },
      steps:        { foot: 1, cycle: 0.3 },
      rail:         { train: 1 },
      light_rail:   { train: 1 },
      subway:       { train: 1 }
    }

    def self.weightings
      @weightings
    end

    def self.get(transport, way_type)
      @weightings[way_type] && @weightings[way_type][transport]
    end
  end
end
