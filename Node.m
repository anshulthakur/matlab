classdef Node < handle
    %NODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        position = struct('x',0,'y',0);
        index = 0; % could have been computed from position
        connected_neighbours = []; %array of objects of node types
        is_edge = false; % is on the edge of the grid? Could be computed
        system;
        streams;
    end
    
    methods
        function obj = Node(index, grid_size, positions, policy, edge_nodes, connect_edge)
            % initialize a node and create adjacencies with direct neighbours
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
            if(connect_edge == 0)                
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
                if((obj.position.y == 1) || (obj.position.y == grid_size(2)))
                    obj.is_edge = true;
                    % edge on left or right of matrix
                    for i=1:grid_size(1)
                        pos = find(positions==sub2ind(grid_size, i,obj.position.y),1);
                        if(~isempty(pos))
                            exclusion_list = [exclusion_list, positions(pos)]; 
                        end
                    end
                end
            end
            
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

            % Now, one column to left at a time
            found = false;
            col = obj.position.y;
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
                        if(selector<policy)
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
            obj.system = System(obj.index, capacity, num_servers, policy, rates);
        end
        
        function obj = getSystemHandle(self)
            obj = self.system;
        end
        
        function putNeighbours(obj, topology)
            %Create a cell matrix of handles of connected nodes
            neighbours = cell(1,length(obj.connected_neighbours));
            for i=1:numel(obj.connected_neighbours)
                index = find(topology.positions == obj.connected_neighbours(i), 1);
                neighbours{i} = topology.nodes{index};                
            end
            obj.system.installAdjacencies(neighbours);
        end
    end
    
end

