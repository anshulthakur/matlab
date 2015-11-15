% Scenario:
% A topology of 25 nodes placed on a 5x5 grid and connected in a
% forward packet flow model with no dropping at transit nodes.
% Nodes on the same level (same column) do not peer with each other.
% Two servers per system (rates 3 per server) and lambda is 2
% Each node has a buffer capacity of 20 packets.

%Create Topology
grid_size = struct('rows',5,'columns',5);
topo_policy = struct('connect_vertical_edge_nodes', 0, ...
                     'connect_horizontal_edge_nodes', 1, ...
                     'connect_same_level_peers', 0, ...
                     'adjacent_peer_probability', 1, ...
                     'flow', 'forward'); %or 'random'
                 
topo = struct('mode', 'auto',...
              'grid', [],...
              'num_nodes', 25,...
              'grid_size', grid_size,...
              'topologyPolicy', topo_policy...
              );                    
topology = Topology.getTopology(topo); 

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(50);

%init scheduler with topology
scheduler.init(topology);

%Install Systems on Grid
systemDescr = struct(...
                'QueueSize', 20,...
                'ServerType', 'exponential', ... %Or Deterministic
                'ServiceRates', [1.5 1.5],...
                'ServiceClasses', [0],...
                'Variances',[],...
                'AbsorptionProbability',0, ...
                'Forwarding','balance' ... %or random 
                );
topology.installSystems('all', systemDescr); %Install same kind of system on all nodes

%Install Adjacencies
topology.initSystems();

%Associate streams with each node
streamDescr = struct( ...  
                'StreamType', 'poisson', ...
                'GenerationTime', scheduler.getTtl(), ... %seconds
                'lambda', 2, ...
                'class', 0, ...
                'packetLength', 0 ...
                    );
topology.installStream('all', streamDescr);


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
