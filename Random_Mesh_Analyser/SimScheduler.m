classdef SimScheduler < handle
    %SIMSCHEDULER Overall Simulation Scheduler controlling entire sequence
    
    properties
        topology ; %Topology being simulated
        running = false;
        packet_lifetimes;
        packet_hopcounts;
        packet_wait_times;
    end
    
    properties (Access = private)
        ttl;    %Time instants to run simulation for
        time;
        systems;
        num_systems;
    end

    methods (Access=private)
        function obj = SimScheduler()
            fprintf('\nNew Scheduler instance');
            obj.ttl = 0;            
            obj.time = 0;
            obj.systems = {};
            obj.num_systems = 0;
            
            obj.packet_hopcounts = [];
            obj.packet_lifetimes = [];
            obj.packet_wait_times = [];
        end
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
      function obj = getScheduler(destroy)
          if(nargin~=0)
              clear uniqueInstance;
              return;
          end
          persistent uniqueInstance
          if isempty(uniqueInstance)
              obj = SimScheduler();
              uniqueInstance = obj;
          else
              obj = uniqueInstance;
          end
      end
    end 

    methods              
        function destroy(obj)
            SimScheduler.getScheduler(true);
        end        
        
        function time = getTime(obj)
            time = obj.time;
        end
        
        function runScheduler(obj)
            
            %fprintf('\nRun scheduler at t=%d',obj.time);        
            
            if((obj.ttl == 0) || ((obj.ttl ~=0) && (obj.time < obj.ttl)))                
                %allow systems to process
                for i=1:length(obj.systems)
                    obj.systems{i}.serve();
                end
                %Transmit their buffers
                for i=1:length(obj.systems)
                    obj.systems{i}.transmit();
                end
                %take packet out of each stream and conditionally enqueue
                for i=1:length(obj.systems)
                   for j=1:length(obj.systems{i}.streams)                       
                       packet = obj.systems{i}.streams{j}.getPendingPacket(obj.time);
                       if(isa(packet,'Packet'))
                           obj.RegisterPacketDestroy(packet);
                           %enqueue into system
                           obj.systems{i}.enqueue(packet);
                       end
                   end
                end                
                obj.time = obj.time +1;
            else
                fprintf('\nSimulation complete. Scheduler halting.');
                obj.running = false;
            end
        end
        
        function setRunLength(obj, time)
            obj.ttl = time * 1000; %milliseconds
        end
        
        function setTopology(obj, top)
            obj.topology = top;
        end
        
        function status = isRunning(obj)
            status = obj.running;
        end
        
        function addSystems(obj, ~, systems)
            for i=1:length(systems.system)
                obj.systems = [obj.systems, cell(1,1)];
                obj.systems{end} = systems.system{i};
                fprintf('\nAdded System (id: %d)',obj.systems{end}.id); 
            end
        end
        
        function PacketStatUpdate(obj, packet)
            %fprintf('\nPacket Lifetime: %d',packet.age_in_network);
            obj.packet_lifetimes = [obj.packet_lifetimes, ...
                                            round(packet.age_in_network)];
            obj.packet_hopcounts = [obj.packet_hopcounts, ...
                                            round(packet.hop_count)];
            obj.packet_wait_times = [obj.packet_wait_times, ...
                                    packet.wait_times];
            clear packet;
        end
        
        function hdl = RegisterPacketDestroy(obj, packet)
            hdl = addlistener(packet, 'deletePacket',...
                @(src,~)obj.PacketStatUpdate(src));
        end
        
        function hdl = RegisterSystemAdd(obj, topology)
            hdl = addlistener(topology, 'newSystem',...
                @(src, data)obj.addSystems(src, data));
        end
        
        function init(obj, topology)
            obj.setTopology(topology);
            obj.RegisterSystemAdd(topology);            
        end
        
        function ttl = getTtl(obj)
            ttl = obj.ttl/1000; %Reconvert to seconds
        end
        
        function spinScheduler(obj)
           obj.running = true; 
           fprintf('\nScheduler starting.');
        end
        
        function scheduleStreams(obj, lambdas)
            %for each stream, assiciate a class of traffic             
            for i=1:length(obj.systems)
               stream = cell(1,length(lambdas));
               for j=1:length(lambdas)
                   stream{j}=Stream(obj.ttl, lambdas(j), j);
               end
               obj.systems{i}.streams = stream;
               fprintf('\nAssociated %d streams with System %d', ...
                                        length(stream), obj.systems{i}.id);
            end
        end
        
        function visualizePacketLife(obj)
            histogram(obj.packet_lifetimes, 'Normalization','pdf');
        end
        
        function visualizePacketWaitTimes(obj)
            histogram(obj.packet_wait_times, 'Normalization','pdf');
        end
        
        function val = averageHopCounts(obj)
            val = mean(obj.packet_hopcounts);
        end
        
        function showQueueLengths(obj)
            q_len = zeros(1,length(obj.systems));
            for i=1:length(obj.systems)
                fprintf('\n[System %d]\t%d', obj.systems{i}.id, ...
                                obj.systems{i}.getQueueLength);
                q_len(i) = obj.systems{i}.getQueueLength;
            end
            fprintf('\nMean Queue Length: %d', mean(q_len));
        end

        function showSystemPopulation(obj)
            q_len = zeros(1,length(obj.systems));
            for i=1:length(obj.systems)
                fprintf('\n[System %d]\t%d', obj.systems{i}.id, ...
                                obj.systems{i}.getCustomerCount);
                q_len(i) = obj.systems{i}.getCustomerCount;
            end
            fprintf('\nMean System Population: %d', mean(q_len));
        end
        
        function visualizeServiceTime(obj, scope, id)
            distribution=[];
            if(strcmp(scope,'local'))
                for i=1:length(obj.systems)
                    if(obj.systems{i}.id == id)
                        histogram(obj.systems{i}.getDistribution(),...
                                                    'Normalization','pdf');
                        break;
                    end
                end                
            elseif(strcmp(scope,'network'))
                for i=1:length(obj.systems)
                    distribution = [distribution, obj.systems{i}.getDistribution()];
                end                
                histogram(distribution, 'Normalization', 'pdf');
            end                
        end
        
        function utilization = getUtilization(obj, scope, id)        
            utilization = cell(1,1);
            fprintf('\nServer Utilization Statistics:');
            if(strcmp(scope,'local'))
                for i=1:length(obj.systems)
                    if(obj.systems{i}.id == id)
                        utilization{1} = obj.systems{i}.getUtilization();
                        fprintf('\n[Server %d]: %d',...
                                    obj.systems{i}.id, utilization{1});
                        break;
                    end
                end                
            elseif(strcmp(scope,'network'))
                utilization=cell(1,length(obj.systems));
                for i=1:length(obj.systems)
                    utilization{i} = obj.systems{i}.getUtilization();
                    fprintf('\n[Server %d]: %d',...
                                    obj.systems{i}.id, utilization{i});
                end                
            end            
        end
        
        
                
    end
    
end
