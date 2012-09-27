module Mormon
  module OSM
    class Router
      # attr_reader :data

      def initialize(loader)
        @loader = loader
      end

      # Calculate distance between two nodes via pitagoras c**2 = a**2 + b**2
      def distance(n1, n2)
        node1, node2 = @loader.nodes[n1.to_s], @loader.nodes[n2.to_s]

        lat1, lon1 = node1[:lat], node1[:lon]
        lat2, lon2 = node2[:lat], node2[:lon]
        
        # TODO: projection issues
        dlat  = lat2 - lat1
        dlon  = lon2 - lon1

        Math.sqrt dlat**2 + dlon**2
      end

      def find_route(node_start, node_end, transport)
        result, nodes = route(node_start, node_end, transport)
        
        return [result,[]] if result != 'success'
        
        nodes.map! do |node|
          data = @loader.nodes[node.to_s]
          [data[:lat], data[:lon]]
        end

        [result, nodes]
      end

      private

        def route(node_start, node_end, transport)
          return "no_such_transport" unless @loader.routing[transport]
          return "no_such_node"      unless @loader.routing[transport][node_start.to_s]

          @_end  = node_end
          @queue = []

          # Start by queueing all outbound links from the start node
          @loader.routing[transport][node_start.to_s].each do |neighbor, weight|
            add_to_queue(node_start, neighbor, { node_end: nil, distance: 0, nodes: [node_start] }, weight)
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

            @loader.routing[transport][x.to_s].each do |node, weight|
              add_to_queue(x, node, next_item, weight) unless closed.include?(node)
            end if @loader.routing[transport][x.to_s]
          end

          'gave_up'
        end
        
        def add_to_queue(node_start, node_end, current_queue, weight = 1)
          # Add another potential route to the queue
          
          node_start = node_start.to_i
          node_end   = node_end.to_i
          
          # if already in queue
          @queue.each { |other| return if other[:node_end] == node_end }

          distance = distance(node_start, node_end)
          
          return if weight.zero?
          distance = distance / weight
          
          # Create a hash for all the route's attributes
          current_distance = current_queue[:distance]
          nodes = current_queue[:nodes].dup
          nodes << node_end

          queue_item = {
            distance:     current_distance + distance,
            max_distance: current_distance + distance(node_end, @_end),
            nodes:        nodes,
            node_end:     node_end
          }
          
          # Try to insert, keeping the queue ordered by decreasing worst-case distance
          found = @queue.find { |other| other[:max_distance] > queue_item[:max_distance] }
          found ? @queue.insert(@queue.index(found), queue_item) : @queue << queue_item
        end

    end
  end
end