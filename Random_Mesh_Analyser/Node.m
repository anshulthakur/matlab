classdef Node < handle
    %NODE Represents an entity placed on a Topology Grid.
    %   A Node is placed on a Topology map which is represented as a
    %   multidimensional array of discrete points in space. Each node is
    %   identified by its array index and based on the policy of
    %   connections, has a set of identified adjacencies with which it
    %   could peer with.
    
    properties
        position = struct('x',0,'y',0);
        index = 0;
        connected_neighbours = []; %array of objects of node types
        is_edge = false;
        system;
        policy = 1;
        sink = 0;
    end
    
    methods
        function obj = Node(index, grid_size, positions, policy, edge_nodes, connect_prob)
            %% 
            % Initialize a node and create adjacencies with direct neighbours
            % Inputs:
            % index: index on the topology [integer]
            % grid_size: size of the 2-D Topology Grid created as a 
            %            1x2 array of integers. [x-size, y-size]
            % Positions: Positions of all other nodes that have been placed
            %            The nodes might have been randomly placed by the
            %            code, or explicitly placed by the user.
            % Policy:   A dictionary of policies that the node must obey.
            %           'connect_v_edge': [0/1] - Connect vertically
            %           adjacent edge nodes?
            %           'connect_h_edge': [0/1] - Connect horizontally
            %           adjacent edge nodes?
            %           'connect_adjacents': [0/1] - Connect with peers on
            %           the same vertical column of grid or not?
            %           'flow': 'random'/'left' - If option is set to
            %           random, the node will search for possible peers in
            %           both left and right direction. Thus, packets coming
            %           from one direction may be sent to any other peer in
            %           a left/right direction. If set to 'left', it will
            %           only search from left to right, such that no back
            %           routing of packets will take place towards left. 
            % Connect Probability: Given a set of discovered neighbours,
            %           this values specifies the probability with which
            %           the node will actually peer with the neighbour. If
            %           set to 1, node will peer with every neighbour
            %           discovered. If 0, with none.
            
            [obj.position.x, obj.position.y] = ind2sub(grid_size, index);
            fprintf('\n Node placed at ');
            disp([obj.position.x, obj.position.y]);
            obj.index = index;
            matches = [];
            % Find matches in x direction
            % starting from the current row, traverse up once to find the
            % nearest neighbour in the same column, then in the lower
            % direction.
            % Then, move to adjacent column towards left, and repeat. If
            % no neighbour is found in that column, advance one left until 
            % end of grid is reached (in which case, it is an edge node) or
            % a column with a neighbour is detected. Mark that as a match.
            % Similarly in the right direction...
            % Whether to mark the node as edge node needs to be
            % contemplated, because in case we don't consider it as edge
            % node, and the entire grid has no node on the edge, we are in
            % trouble.
            % In such case, it must be marked as edge node. (That can be
            % done on policy basis!)
            
            % Is it an edge node? If yes, construct an exclusion list of
            % nodes not to peer with
            exclusion_list = [];
            if(policy.connect_h_edge == 0)                
                if((obj.position.x == 1) || (obj.position.x == grid_size(1)))                     
                    obj.is_edge = true;
                    % edge on top or bottom of matrix
                    for i=1:grid_size(2)
                        pos = find(positions==sub2ind(grid_size, obj.position.x, i),1);
                        if(~isempty(pos))
                            exclusion_list = [exclusion_list, positions(pos)]; 
                        end
                    end
                end
            end
            if(policy.connect_v_edge ==0)
                if((obj.position.y == 1) || (obj.position.y == grid_size(2)))
                    obj.is_edge = true;
                    if(obj.position.y == grid_size(2))
                        obj.sink = true;
                        %fprintf('\nFound sink at Node index %d',obj.index);
                    end
                    % edge on left or right of matrix
                    for i=1:grid_size(1)
                        pos = find(positions==sub2ind(grid_size, i,obj.position.y),1);
                        if(~isempty(pos))
                            exclusion_list = [exclusion_list, positions(pos)]; 
                        end
                    end
                end
            end
            
            if(policy.connect_adjacents == 1)
                % First, move up in row
                for i=obj.position.x -1:-1:1
                    pos = find(positions==sub2ind(grid_size, i, obj.position.y),1);
                    if(~isempty(pos))
                        % Not empty. Add to match
                        if(isempty(find(exclusion_list == positions(pos),1)))
                            matches(end +1) = positions(pos);
                            fprintf('\nFound neighbour at ');
                            disp(ind2sub(grid_size,positions(pos)));
                        else
                            fprintf('\nFound edge peer. Exclude!');
                        end
                        break;
                    end
                    % No node at this position, move ahead
                end
                % Then, move down in row
                for i=obj.position.x + 1:grid_size(1)
                    pos = find(positions==sub2ind(grid_size, i, obj.position.y),1);
                    if(~isempty(pos))
                        % Not empty. Add to match
                        if(isempty(find(exclusion_list == positions(pos),1)))
                            matches(end +1) = positions(pos);
                            fprintf('\nFound neighbour at ');
                            disp(ind2sub(grid_size,positions(pos)));
                        else
                            fprintf('\nFound edge peer. Exclude!');
                        end
                        break;
                    end
                    % No node at this position, move ahead
                end
            end

            % Now, one column to left at a time
            found = false;
            col = obj.position.y;
            if(strcmp(policy.flow,'random'))
                while(~found)
                    %take one cloumn step back
                    if(col > 1)
                        col = col -1 ;
                    else
                        break;
                    end
                    for i=1:grid_size(1)
                        pos = find(positions==sub2ind(grid_size,i, col),1);
                        if(~isempty(pos))
                            % Not empty. Add to match
                            if(isempty(find(exclusion_list == positions(pos),1)))
                                found = true;
                                matches(end +1) = positions(pos);
                                fprintf('\nFound neighbour at ');
                                disp(ind2sub(grid_size,positions(pos)));
                            else
                                fprintf('\nFound edge peer. Exclude!');
                            end
                        end
                        % No node at this position, move ahead
                    end
                end
            end
            % Now, one column to right at a time
            found = false;
            col = obj.position.y;
            
            while(~found)
                %take one cloumn step back
                if(col < grid_size(2))
                    col = col +1 ;
                else
                    break;
                end
                for i=1:grid_size(1)
                    pos = find(positions==sub2ind(grid_size, i, col),1);
                    if(~isempty(pos))
                        % Not empty. Add to match
                        if(isempty(find(exclusion_list == positions(pos),1)))
                            found = true;
                            matches(end +1) = positions(pos);
                            fprintf('\nFound neighbour at ');
                            disp(ind2sub(grid_size,positions(pos)));
                        else
                            fprintf('\nFound edge peer. Exclude!');
                        end
                    end
                    % No node at this position, move ahead
                end
            end
            
            % By the end of this, we have a matrix of possible adjacencies
            % for this node. Filter the elements based on policy.
            % Do it recursively until at least one member is selected.
            if(numel(matches)>0)
                while(numel(obj.connected_neighbours) == 0)
                    for element=1:numel(matches)
                        selector = rand(1,1);
                        if(selector<connect_prob)
                            % Add as adjacency
                            obj.connected_neighbours(end+1)=matches(element);
                        end
                    end
                end
            else
                fprintf('\nNo adjacencies found!');
            end
            
            obj.system = {};
            % If it isn't on the edge, but does not have any node on the
            % edge side, it could be the edge node. Determine...
        end
        
        function install_system(obj, capacity, num_servers, policy, rates)
            %%
            % Install a Queueing system on the node. 
            % Parameters:
            % Capacity: Input Queue capacity
            % Num_servers: Number of server stations to install in the
            % system.
            % Policy: Currently unused. Meant for dealing with class
            % traffic.
            % Rates: An array of Service Rates. The dimensions must match
            % with the number specified in num_servers.
            if(strcmp(policy, 'left'))
                %don't drop packets
                obj.policy = 0;
            else
                %fprintf('\n[System %d]:Drop packets', obj.index);
            end
            obj.system = System(obj.index, capacity, num_servers, policy, rates);
        end
        
        function obj = getSystemHandle(self)
            obj = self.system;
        end
        
        function putNeighbours(obj, topology)
            %%
            % Create a cell matrix of handles of connected nodes
            neighbours = cell(1,length(obj.connected_neighbours));
            for i=1:numel(obj.connected_neighbours)
                index = find(topology.positions == obj.connected_neighbours(i), 1);
                neighbours{i} = topology.nodes{index};                
            end
            obj.system.installAdjacencies(neighbours, obj.policy);
        end
    end
    
end

