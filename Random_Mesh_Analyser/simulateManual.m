% Create a topology of manually placed nodes such that each node is
% configurable

%Placement of nodes
grid = [...
        [1 0 0 0 0];...
        [0 2 0 3 0];...    
        [0 0 4 0 7];...
        [0 5 0 6 0];...
        [10 0 9 0 8]...
        ];       
topo = struct('mode','manual',...
              'grid', grid,...
              'num_nodes',0,...
              'grid_size',0,...
              'topologyPolicy',cell(1,1)...
              );                     
%Get a topology object. This places Node objects on the desired points.        
topology = Topology.getTopology(topo); 

%Define neighbours to each node now
topology.addNeighbours(1, [2,5]);
topology.addNeighbours(10, [2,5]);
topology.addNeighbours(2, [4]);
topology.addNeighbours(5, [4,9]);
topology.addNeighbours(4, [3,6]);
topology.addNeighbours(3, [7,8]);
topology.addNeighbours(6, [7,8]);

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(20);

%init scheduler with topology
scheduler.init(topology);

%install systems on grid
systemDescr = struct(...
                'QueueSize', 0,...
                'ServerType', 'deterministic', ... %Or packetLength, or exponential
                'ServiceRates', [3],...
                'ServiceClasses', [0],...
                'Variances',[0],...
                'AbsorptionProbability',1, ...
                'Forwarding','balance' ... %or random 
                );

%Install system of particular type on particular nodes
topology.installSystems([7,8], systemDescr); %Install same kind of system on all nodes

systemDescr = struct(...
                'QueueSize', 0,...
                'ServerType', 'exponential', ... %Or Deterministic
                'ServiceRates', [3],...
                'ServiceClasses', [0],...
                'Variances',[],...                
                'AbsorptionProbability',0, ...
                'Forwarding','balance' ... %or random 
                );
topology.installSystems([1,2,3,4,5,6,9,10], systemDescr); %Install same kind of system on all nodes

%Initialize systems
topology.initSystems();

%Associate streams with each node
streamDescr = struct( ...  
                'StreamType', 'poisson', ...
                'GenerationTime', 100, ... %seconds
                'lambda', 2, ...
                'class', 0, ...
                'packetLength', 0 ...
                    );
topology.installStream([1,2,3,4,5,6,9,10], streamDescr);

%**TODO**For multiclass traffic, there should be multiple queues at each
%system.

%Run scheduler
scheduler.spinScheduler();
while(scheduler.isRunning())
    scheduler.runScheduler();
end

topology.visualize();
hold off;

scheduler.visualizePacketLife();

scheduler.showQueueLengths();
scheduler.showSystemPopulation();

scheduler.visualizeServiceTime('network',0);

scheduler.visualizePacketWaitTimes();

fprintf('\nAverage hopcounts: %d',scheduler.averageHopCounts());

scheduler.getUtilization('network',0);

scheduler.getBlockingProbability('network',0);
%Cleanup the system.
scheduler.destroy();
topology.destroy();
clear;
