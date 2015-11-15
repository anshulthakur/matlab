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
       connect_policy = struct('connect_v_edge',1, ...
                               'connect_h_edge',1, ...
                               'connect_adjacents',1,...
                               'peer_connect_probability',1,...
                               'flow', 'random');
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
       newStream;
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
      function obj = getTopology(topo)
          if(nargin==1 && ~isa(topo, 'struct'))
              clear topology;
              return;          
          end
          persistent topology
          if isempty(topology)
              if(~nargin==1) %Must have adequate number of arguments
                  return;
              end
              obj = Topology(topo);
              topology = obj;
          else
              obj = topology;
          end
      end
    end
    
    methods (Access=private)
        function map = Topology(topo)
            %TOPOLOGY Create a topology with given parameters
            error_msg = 'Error creating class';
            msg_id = 'topology:badInputs';
            exception = MException(msg_id,error_msg);
            
            if(strcmp(topo.mode, 'auto'))
                if(isa(topo.num_nodes, 'double') && topo.num_nodes <= 0)
                    throw(exception)
                else
                    map.num_nodes = topo.num_nodes;
                end

                if( isa(topo.grid_size, 'struct') && (topo.grid_size.rows <= 0 || topo.grid_size.columns <=0))
                    throw(exception);
                elseif((topo.grid_size.rows * topo.grid_size.columns) < topo.num_nodes)
                    throw(exception);
                else
                    map.grid_size(1) = topo.grid_size.rows;
                    map.grid_size(2) = topo.grid_size.columns;
                end

                %topo_policy = struct('connect_vertical_edge_nodes',0,...
                %         'connect_horizontal_edge_nodes', 1,...
                %         'connect_same_level_peers', 0,...
                %         'adjacent_peer_probability', 0.5);
                if( isa(topo.topologyPolicy, 'struct') && ...
                        (topo.topologyPolicy.connect_vertical_edge_nodes ~= 0 ...
                                && topo.topologyPolicy.connect_vertical_edge_nodes ~=1)...
                        &&(topo.topologyPolicy.connect_horizontal_edge_nodes ~= 0 ...
                                && topo.topologyPolicy.connect_horizontal_edge_nodes ~=1)...
                        &&(topo.topologyPolicy.connect_same_level_peers ~= 0 ...
                                && topo.topologyPolicy.connect_same_level_peers ~=1)...
                        &&(topo.topologyPolicy.adjancent_peer_probability < 0 || ...
                                    topo.topologyPolicy.adjancent_peer_probability >1)...
                        )
                    throw(exception);
                elseif((topo.grid_size.rows * topo.grid_size.columns) < topo.num_nodes)
                    throw(exception);
                else
                    map.connect_policy.connect_v_edge = topo.topologyPolicy.connect_vertical_edge_nodes;
                    map.connect_policy.connect_h_edge = topo.topologyPolicy.connect_horizontal_edge_nodes;
                    map.connect_policy.connect_adjacents = topo.topologyPolicy.connect_same_level_peers;
                    map.connect_policy.peer_connect_probability = topo.topologyPolicy.adjacent_peer_probability;
                    map.connect_policy.flow = topo.topologyPolicy.flow;
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
                
                % fprintf('\nEdges coordinates at\n');
                % map.edge_coords

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
                    map.nodes{element} = Node(map.positions(element),...
                                    map.positions(element), map,...
                                    map.connect_policy);
                end
                fprintf('\nNodes placed as: \n');
                disp(map.grid);
            else
                %Manual
                map.grid = topo.grid;
                map.num_nodes = nnz(topo.grid);
                [map.grid_size(1), map.grid_size(2)]= size(topo.grid);
                map.nodes = cell(map.grid_size(1), map.grid_size(2));
                map.positions = find(topo.grid);
                
                %Install Nodes on the aforementioned points
                for element=1:numel(map.positions)
                    map.nodes{map.positions(element)} = Node(map.grid(map.positions(element)),...
                        map.positions(element), map, 0); %No policy yet
                end
            end
        end
    end
    
    methods
        function destroy(obj)        
            obj.getTopology(true);
        end
        
        function addNeighbours(obj, nodeId, neighbours)
           %Find index of node with ID nodeID
           %Warning, IDs must be unique, or else, only first will be
           %returned
           index = find(obj.grid==nodeId,1);
                      
           neighbour_index = zeros(1,numel(neighbours));
           for i=1:numel(neighbour_index)
               neighbour_index(i)= find(obj.grid==neighbours(i),1);
           end
           
           %fprintf('\n[Node %d]: Own Index: %d\tNeighbours located at:', ...
           %                     obj.nodes{index}.id, obj.nodes{index}.index);
           %disp(neighbour_index);
           
           obj.nodes{index}.add_neighbours(neighbour_index);
        end
        
        function installSystems(obj, ids, props)
            %%
            % Install systems on locations with IDs specified as in 'ids'
            % with properties as set in 'props'
            
            if(isa(ids, 'char'))
                if(strcmp(ids,'all'))                    
                    for i=1:length(obj.positions)
                        obj.nodes{obj.positions(i)}.install_system(props);
                        notify(obj, 'newSystem', ...
                            AddSystemEventData(obj.nodes{obj.positions(i)}.getSystemHandle()));
                    end
                else
                    fprintf('\nUnidentified option "%s"', ids);
                end                
            else
                for i=1:length(ids)
                    obj.nodes{find(obj.grid==ids(i),1)}.install_system(props);
                    notify(obj, 'newSystem', ...
                        AddSystemEventData(obj.nodes{find(obj.grid==ids(i),1)}.getSystemHandle()));
                end
            end
        end
        
        function installStream(obj, ids, props)
            %%
            % Install traffic streams on locations with IDs specified as in 
            % 'ids' with properties as set in 'props'
            
            if(isa(ids, 'char'))
                if(strcmp(ids,'all'))                    
                    for i=1:length(obj.nodes)
                        obj.nodes{i}.install_stream(props);
                        notify(obj, 'newStream', ...
                            AddSystemEventData(obj.nodes{i}.getSystemHandle()));
                    end
                else
                    fprintf('\nUnidentified option "%s"', ids);
                end                
            else
                for i=1:length(ids)
                    obj.nodes{find(obj.grid==ids(i),1)}.install_stream(props);
                    notify(obj, 'newStream', ...
                        AddSystemEventData(obj.nodes{find(obj.grid==ids(i),1)}.getSystemHandle()));
                end
            end
        end
        
        function initSystems(obj)
            for i=1:length(obj.positions)
                obj.nodes{obj.positions(i)}.putNeighbours(obj);
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
            for i=1:numel(obj.positions)
                pos = [obj.nodes{obj.positions(i)}.position.y, ...
                        obj.nodes{obj.positions(i)}.position.x];
                
                %fprintf('\n[Topology]:Connect for node at:');
                %disp([obj.nodes{i}.position.y,obj.nodes{i}.position.x]);
                %fprintf('\n[Topology]:Neighbours at:');
                
                for j=1:numel(obj.nodes{obj.positions(i)}.connected_neighbours)    
                    [pos_y,pos_x] = ind2sub(obj.grid_size, obj.nodes{obj.positions(i)}.connected_neighbours(j));
                    
                    obj.nodes{obj.positions(i)}.connected_neighbours(j);
                    %disp([pos_x,pos_y]);
                    
                    plot([pos(1),pos_x], [pos(2),pos_y]);                    
                end
            end
        end
    end

end
