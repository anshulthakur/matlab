classdef Topology < handle
    %CREATE_RANDOM_MESH creates a randomly connected mesh network of nodes
    %placed randomly on a grid.
    %   Input: num_nodes - Number of nodes to be placed in the mesh
    %
    %   Given a number 'n' of nodes, the method creates a grid of size
    %   given by user
    %   and randomly places the nodes in a few of these grids.
    properties
       num_nodes = 0;        % Number of nodes to draw
       connect_policy = 1;   % Proobability to connect with adjacent nodes
       connect_edges = 1;
       grid_size = [0,0];
       grid;
       positions;
       nodes;
       node_handles;
       edge_nodes;
    end
    
    properties (Access = private)       
       edge_coords;
    end
    
    events
       newSystem; 
    end
    
    methods(Static)
      % This method serves as the global point of access in creating a
      % single instance *or* acquiring a reference to the singleton.
      % If the object doesn't exist, create it otherwise return the
      % existing one in persistent memory.
      % Input:
      %    <none>
      % Output:
      %    obj = reference to a persistent instance of the class
      function obj = getTopology(num_nodes, grid_size, connect_policy, connect_edges)
          if(nargin==1)
              clear topology;
              return;          
          end
          persistent topology
          if isempty(topology)
              if(~nargin==4) %Must have adequate number of arguments
                  return;
              end
              obj = Topology(num_nodes, grid_size, connect_policy, connect_edges);
              topology = obj;
          else
              obj = topology;
          end
      end
    end
    
    methods (Access=private)
        function map = Topology(num_nodes, grid_size, connect_policy, connect_edges)
            %TOPOLOGY Create a topology with given parameters
            error_msg = 'Error creating class';
            msg_id = 'topology:badInputs';
            exception = MException(msg_id,error_msg);
            
            if(isa(num_nodes, 'double') && num_nodes <= 0)
                throw(exception)
            else
                map.num_nodes = num_nodes;
            end
            
            if( isa(grid_size, 'struct') && (grid_size.rows <= 0 || grid_size.columns <=0))
                throw(exception);
            elseif((grid_size.rows * grid_size.columns) < num_nodes)
                throw(exception);
            else
                map.grid_size(1) = grid_size.rows;
                map.grid_size(2) = grid_size.columns;
            end
            
            if( isa(connect_policy, 'double') && (connect_policy <= 0 || connect_policy > 1))
                throw(exception);
            else
                map.connect_policy = connect_policy;
            end
            
            if( isa(connect_edges, 'double') && (connect_edges ~= 0 && connect_edges ~= 1))
                throw(exception);
            else
                map.connect_edges = connect_edges;
            end
            
            % now construct a grid
            map.grid = zeros(map.grid_size(1), map.grid_size(2));
            map.nodes = cell(map.grid_size(1), map.grid_size(2));
            
            % Find the positions of edge coordinates
            for i=1:map.grid_size(1)
                map.edge_coords = [map.edge_coords, sub2ind(map.grid_size,i,1)];
                if(map.grid_size(2) ~=1)
                    map.edge_coords = [map.edge_coords, sub2ind(map.grid_size, i, map.grid_size(2))];
                end
            end
            for i=1:map.grid_size(2)
                map.edge_coords = [map.edge_coords, sub2ind(map.grid_size, 1, i)];
                if(map.grid_size(1)~=1)
                    map.edge_coords = [map.edge_coords, sub2ind(map.grid_size, map.grid_size(1), i)];
                end
            end
            
            % generate a sequence of grid points where nodes would be placed
            % (Counting is columnar)
            fprintf('\nEdges coordinates at\n');
            map.edge_coords
            
            map.edge_nodes = [];
            while(isempty(map.edge_nodes))
                map.positions = randperm(numel(map.grid), map.num_nodes);
                for i=1:numel(map.edge_coords)
                    pos = find(map.positions==map.edge_coords(i),1);
                    if(~isempty(pos))
                        map.edge_nodes = [map.edge_nodes, map.positions(pos)]; 
                    end
                end
            end
                        
            %fprintf('\nEdges at\n');
            %disp(map.edge_nodes);
            
            %fprintf('\nNodes at positions: \n');
            %disp(positions);
            
            for element=1:numel(map.positions)
                map.grid(map.positions(element)) = 1;
                % Also, initialize a node at this point
                nodes{element} = Node(map.positions(element), map.grid_size, map.positions, ...
                                        map.connect_policy, map.edge_nodes, ...
                                        map.connect_edges);
            end
            map.nodes = nodes;
            fprintf('\nNodes placed as: \n');
            disp(map.grid);
        end
    end
    
    methods
        function destroy(obj)        
            obj.getTopology(true);
        end
        
        function installSystems(obj, capacity, num_servers, policy, rates)
            for i=1:length(obj.nodes)
                obj.nodes{i}.install_system(capacity, num_servers, policy, rates);
                notify(obj, 'newSystem', ...
                    AddSystemEventData(obj.nodes{i}.getSystemHandle()));
            end
        end
        
        function installAdjacencies(obj)
            for i=1:length(obj.nodes)
                obj.nodes{i}.putNeighbours(obj);
            end
        end
        
        function fig = visualize(obj)
            fig = figure('Name','Topology');
            indices = zeros(0,2);
            for i=1:numel(obj.grid)
                if(obj.grid(i) == 1)
                    [pos_y,pos_x] = ind2sub(obj.grid_size, i);
                    indices = [indices; [pos_x, pos_y]];
                end
            end
            plot(indices(:,1), indices(:, 2), 'bx');
            hold on;
            %Connect adjacents
            for i=1:numel(obj.nodes)
                pos = [obj.nodes{i}.position.y, obj.nodes{i}.position.x];
                
                fprintf('\nConnect for node at:');
                disp([obj.nodes{i}.position.y,obj.nodes{i}.position.x]);
                fprintf('\nNeighbours at:');
                
                for j=1:numel(obj.nodes{i}.connected_neighbours)    
                    [pos_y,pos_x] = ind2sub(obj.grid_size, obj.nodes{i}.connected_neighbours(j));
                    
                    obj.nodes{i}.connected_neighbours(j);
                    disp([pos_x,pos_y]);
                    
                    plot([pos(1),pos_x], [pos(2),pos_y]);                    
                end
            end
        end
    end

end
