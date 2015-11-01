classdef Transmit < BaseQueue
    %Transmit Transmits a packet by a rule on the connected nodes
    
    properties
        neighbours;
        policy;
        buffer;
        commutator;
    end
    
    methods
        function obj = Transmit(num_servers)            
            obj.buffer = BaseQueue(num_servers);            
        end
        
        function transmit(obj)
           if(obj.buffer.NumElements > 0)
               %dequeue and transmit
               packet = obj.buffer.remove();
               if(~isa(packet,'Packet'))
                   %empty queue
                   fprintf('\nNot a packet!');
                   return
               end
               %randmoly select next destination
               egress = datasample(obj.commutator, 1);
               if(egress ~= 1)
                   %enqueue in the next system
                   fprintf('\nEnqueue into System %d',...
                                            obj.neighbours{egress}.id);
                   obj.neighbours{egress}.enqueue(packet);
               else
                   %drop packet
                   fprintf('\nDrop packet.');
                   packet.destroy();
               end
           end
        end
        
        function initTx(obj, neighbours)            
            obj.neighbours = neighbours;
            random_dist = rand([1,numel(neighbours)+1]); %Can drop too, so, add 1
            obj.policy = random_dist./sum(random_dist); %Probability of sending to each neighbour
            obj.commutator = datasample(1:numel(random_dist),10000,...
                                'Weights', random_dist); %10000 ensures neat probability
        end
        
        function addToBuffer(obj, station)            
            obj.buffer.add(station.current_job{end});
            %fprintf('\nAdd to Tx Buffer. Population: %d',obj.buffer.NumElements);
        end
        
        function event_handle = RegisterServiceDone(obj, station)
            event_handle = addlistener(station, 'serviceDone',...
                @(src, ~)obj.addToBuffer(src));
        end
    end
    
end

