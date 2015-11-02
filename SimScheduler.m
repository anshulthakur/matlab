classdef SimScheduler < handle
    %SIMSCHEDULER Overall Simulation Scheduler controlling entire sequence
    
    properties
        topology ; %Topology being simulated
        running = false;
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
            
            fprintf('\nRun scheduler at t=%d',obj.time);        
            
            if(obj.time < obj.ttl)
                obj.time = obj.time +1;
                for i=1:length(obj.systems)
                    obj.systems{i}.serve();
                end
                %Transmit
                for i=1:length(obj.systems)
                    obj.systems{i}.transmit();
                end
            
            else
                fprintf('\nSimulation complete. Scheduler halting.');
                obj.running = false;
            end
            if(obj.time == 1)
                fprintf('\nScheduler starting.');
                obj.running = true;
            end
        end
        
        function setRunLength(obj, time)
            obj.ttl = time;
        end
        
        function setTopology(obj, top)
            obj.topology = top;
        end
        
        function status = isRunning(obj)
            status = obj.running;
        end
        
        function addSystems(obj, ~, systems)
            fprintf('\nAdding %d system',numel(systems.system));
            for i=1:length(systems.system)
                obj.systems = [obj.systems, cell(1,1)];
                obj.systems{end} = systems.system{i};
                fprintf('\nAdded System (id: %d)',obj.systems{end}.id); 
            end
        end
        
        function PacketStatUpdate(obj, packet)
            fprintf('\nPacket Lifetime: %d',packet.age_in_network);
        end
        
        function hdl = RegisterPacketDestroy(obj, packet)
            hdl = addlistener(packet, 'deletePacket',...
                @(src,~)obj.PacketStatUpdate(src));
        end
        
        function hdl = RegisterSystemAdd(obj, topology)
            hdl = addlistener(topology, 'newSystem',...
                @(src, data)obj.addSystems(src, data));
        end
        
        function init(obj, topology,packetStreams)
            obj.RegisterSystemAdd(topology);
            
        end
                
    end
    
end

