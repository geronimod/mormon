module Mormon
  module OSM
    module Algorithm
      class Base
        def initialize(router, options = {})
          @router = router
          @queue = []
        end

        def route(node_start, node_end, transport)
          raise "subclass responsability"
        end

        def enqueue(*args)
          raise "subclass responsability"
        end

        private

          # Calculate distance between two nodes via pitagoras c**2 = a**2 + b**2
          def distance(n1, n2)
            node1, node2 = @router.loader.nodes[n1.to_s], @router.loader.nodes[n2.to_s]

            lat1, lon1 = node1[:lat], node1[:lon]
            lat2, lon2 = node2[:lat], node2[:lon]
            
            dlat  = lat2 - lat1
            dlon  = lon2 - lon1

            Math.sqrt dlat**2 + dlon**2
          end
      end

      # A* Algorithm
      class Astar < Base

        def route(node_start, node_end, transport)
          return "no_such_transport" unless @router.loader.routing[transport]
          return "no_such_node"      unless @router.loader.routing[transport][node_start.to_s]

          # Start by queueing all outbound links from the start node
          @router.loader.routing[transport][node_start.to_s].each do |neighbor, weight|
            enqueue(node_start, neighbor.to_i, node_end, { node_end: nil, distance: 0, nodes: [node_start] }, weight)
          end

          closed = [node_start]
          
          # Limit for how long it will search
          (0..10000).each do
            next_item = @queue.shift
            return "no_route" unless next_item

            x = next_item[:node_end]
            next if closed.include?(x)
              
            # Found the end node - success
            return ['success', next_item[:nodes]] if x == node_end

            closed << x

            @router.loader.routing[transport][x.to_s].each do |node, weight|
              enqueue(x, node.to_i, node_end, next_item, weight) unless closed.include?(node.to_i)
            end if @router.loader.routing[transport][x.to_s]
          end

          'gave_up'
        end
        
        def enqueue(node_start, node_end, node_finish, current_queue, weight = 1)
          # Add another potential route to the queue
          
          # if already in queue
          return if @queue.any? { |other| other[:node_end] == node_end }

          distance = distance(node_start, node_end)
          
          return if weight.zero?
          distance = distance / weight
          
          # Create a hash for all the route's attributes
          current_distance = current_queue[:distance]
          nodes = current_queue[:nodes].dup
          nodes << node_end

          queue_item = {
            distance:     current_distance + distance,
            max_distance: current_distance + distance(node_end, node_finish),
            nodes:        nodes,
            node_end:     node_end
          }
          
          # Try to insert, keeping the queue ordered by decreasing worst-case distance
          ix = @queue.find_index { |other| other[:max_distance] > queue_item[:max_distance] } || -1
          @queue.insert(ix, queue_item)
        end
      end

      class Random < Base

        attr_accessor :breadth

        def initialize(router, options = {})
          super
          @breadth = options[:breadth] || 2
        end

        def route(node_start, node_end, transport)
          max_amplitude = @breadth * distance(node_start, node_end)
          enqueue node_start, node_end, transport, [node_start], [], max_amplitude
          @queue.any? ? ["success", @queue[rand(@queue.size-1)]] : ["no_route", []]
        end

        def enqueue(node_start, node_end, transport, current_route, visited, max_amplitude)
          current_route ||= []
          visited       ||= []

          if node_start == node_end
            @queue << current_route.dup
          else
            visited << node_start
            neighbors = @router.loader.routing[transport][node_start.to_s]

            if neighbors
              neighbors   = neighbors.keys.map(&:to_i)
              not_visited = neighbors - (neighbors & visited)
              
              # random sort in order to not take the same order for neighbors every time.
              not_visited.sort_by { rand }.each do |neighbor|
                # limit the width of the route go further more than max_distance the distance between start and end
                next if distance(neighbor, node_end) > max_amplitude 
                current_route << neighbor
                enqueue neighbor, node_end, transport, current_route, visited, max_amplitude
                current_route.delete neighbor
              end
            end
            
            visited.delete node_start
          end
        end

      end
    end


    class Router
      attr_reader :loader, :queue, :algorithm

      def initialize(loader, options = {})
        algorithm = options.delete(:algorithm) || :astar
        algorithm_class = "Mormon::OSM::Algorithm::#{algorithm.to_s.capitalize}".constantize
        
        @loader = loader
        @algorithm = algorithm_class.new self, options
      end

      def find_route(node_start, node_end, transport)
        result, nodes = @algorithm.route(node_start.to_i, node_end.to_i, transport.to_sym)
        
        return [result,[]] if result != 'success'
        
        nodes.map! do |node|
          data = @loader.nodes[node.to_s]
          [data[:lat], data[:lon]]
        end

        [result, nodes]
      end

    end
  end
end