% Create a topology of manually placed nodes such that each node is
% configurable

%Placement of nodes
grid = [...
        [1 2 3];...
        [4 5 6];...    
        [7 8 9]...
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
topology.addNeighbours(2, [1,5,3]);
topology.addNeighbours(3, [2,6]);
topology.addNeighbours(4, [1,5,7]);
topology.addNeighbours(6, [3,5,9,8]);
topology.addNeighbours(7, [4,5,8]);
topology.addNeighbours(8, [5,6,9]);

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(50);

%init scheduler with topology
scheduler.init(topology);

%install systems on grid
systemDescr = struct(...
                'QueueSize', 10,...
                'ServerType', 'exponential', ... %Or packetLength, or exponential
                'ServiceRates', [9],...
                'ServiceClasses', [0],...
                'Variances',[0],...
                'AbsorptionProbability',1, ...
                'Forwarding','balance' ... %or random 
                );

%Install system of particular type on particular nodes
topology.installSystems([1 5 9], systemDescr); %Install same kind of system on all nodes

systemDescr = struct(...
                'QueueSize', 10,...
                'ServerType', 'exponential', ... %Or Deterministic
                'ServiceRates', [5],...
                'ServiceClasses', [0],...
                'Variances',[],...                
                'AbsorptionProbability',0, ...
                'Forwarding','balance' ... %or random 
                );
topology.installSystems([2 3 4 6 7 8], systemDescr); %Install same kind of system on all nodes

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
topology.installStream([1 2 3 4 5 6 7 8 9], streamDescr);

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
fprintf('\nMean Packet Lifetime: %d',scheduler.getMeanPacketLifetime());
scheduler.getUtilization('network',0);

scheduler.getBlockingProbability('network',0);
%Cleanup the system.
%scheduler.destroy();
%topology.destroy();
%clear;
