module Mormon
  module OSM
    class StopNode
      attr_accessor :node_id, :distance, :road, :house_number, :zip_code
    end

    class DistanceOptimizer
      # encoding: UTF-8

        # Takes an array of stops and computes an optimal route, so the stops are succeeded by the closest of the remaining.
        def self.route_planer(stops, osm_loader)
          @osm_loader = osm_loader

          route = [stops]
          route[0] = stops[0]
          i = 0

          # Iterates through the stops, adds the closest to the route and sets the stops with the start and the remaining stops
          length = stops.length
          while (i < length - 1)
            stop, remaining_stops = find_next_stop(stops)
            route.push stop
            stops = remaining_stops
            i = i + 1
          end

          return route
        end

        # Take an array of stops and return the closest stop with its distance in meters from the first way node in the array
        def self.find_next_stop(stops)
          sorted_stops = []
          i = 0

          # Sets the distance attribute of the stop_objects in the array
          while (i < stops.length)
            if (i == 0)
              stops[i].distance = 0.0
            else
              stops[i].distance = route(stops[0].node_id,stops[i].node_id)
            end
            sorted_stops[i] = stops[i]
            i = i + 1
          end

          sorted_stops.sort! { |a,b| a.distance <=> b.distance }

          next_stop = sorted_stops[1]
          sorted_stops.delete_at(1)

          return next_stop, sorted_stops
        end

        # Calculates the distance of one part between two stops by using roads with a car
        def self.route(from, to)
          osm_router = Mormon::OSM::Router.new(@osm_loader)
          route = osm_router.find_route(from, to, :car)
          osm_loader =""       # Clears memory for osm data

          # Puts error from finding way nodes
          if  (route[0] != "success")
            puts route[0]
          end

          return total_distance_calc(route[1]).round(2)
        end

        # Calculates the distance for this part by adding the distances between the way nodes in it
        def self.total_distance_calc(distance_Array)
          total_distance = 0.0
          i = 0
          latitude_1 = longitude_1 = latitude_2 = longitude_2  = 0.0

          distance_Array.each {| point |
            if (i == 0)
              longitude_1 = point[0]
              latitude_1 = point[1]
              i = i + 1
            elsif (i == 1)
              longitude_2 = point[0]
              latitude_2 = point[1]
              total_distance = total_distance + distance_calc(latitude_1, longitude_1, latitude_2, longitude_2)
              i = i + 1
            elsif (i > 1)
              longitude_1 = longitude_2
              latitude_1 = latitude_2
              longitude_2 = point[0]
              latitude_2 = point[1]
              total_distance = total_distance + distance_calc(latitude_1, longitude_1, latitude_2, longitude_2)
              i = i + 1
            end
          }
          return total_distance
        end

        # Calculates the distance between the coordinates of two way nodes in meters
        def self.distance_calc(latitude_1, longitude_1, latitude_2, longitude_2)

          difference_latitude  = latitude_2 - latitude_1
          difference_longitude  = longitude_2 - longitude_1

          result = Math.sqrt(difference_latitude**2 + difference_longitude**2)
          latitude_longitude_length = latitude_longitude_length(difference_latitude, difference_longitude)
          return result * latitude_longitude_length[2]
        end

        # Calculates the length in meters of one degree and returns an array of the results [0] = latitude degree, [1] = longitude degree, [2] average of these two
        # The argument should represent the latitude the result shall reflect
        # Inspired ny: http://en.wikipedia.org/wiki/Latitude :)
        def self.latitude_longitude_length(latitude, longitude)
          lat = latitude * ((2.0 * Math::PI)/360.0)
          lon = longitude * ((2.0 * Math::PI)/360.0)

          constant_1 = 111132.954
          constant_2 = -559.822
          constant_3 = 1.175
          a = 6378137.0 # Earth radius
          b = 6356752.3142 # Earth radius

          #Calculate the length of a degree of latitude and longitude in meters
          latitude_length = constant_1 + (constant_2 * Math.cos(2 * lat)) + (constant_3 * Math.cos(4 * lat))
          longitude_length =  Math::PI * a * Math.cos(lon) / 180 * (1 - ((a - b) / a) ** 2 * Math.sin(lon) ** 2)**0.5

          return latitude_length, longitude_length, (latitude_length + longitude_length)/2
        end
    end
  end
end
