% Scenario:
% A topology of 10 nodes placed on a 5x5 grid and connected in a
% forward packet flow model with random dropping at transit nodes.
% Nodes on the same level (same column) peer with each other
% probabilistically. Buffer sizes are arbitrarily fixed at 25. Number of
% servers per node are doubled, but rates are halved.

%Create Topology
grid_size = struct('rows',5,'columns',5);
topo_policy = struct('connect_vertical_edge_nodes', 1, ...
                     'connect_horizontal_edge_nodes', 1, ...
                     'connect_same_level_peers', 1, ...
                     'adjacent_peer_probability', 0.3, ...
                     'flow', 'forward'); %or 'random'
                 
topo = struct('mode', 'auto',...
              'grid', [],...
              'num_nodes', 10,...
              'grid_size', grid_size,...
              'topologyPolicy', topo_policy...
              );                    
topology = Topology.getTopology(topo); 

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(100);

%init scheduler with topology
scheduler.init(topology);

%Install Systems on Grid
systemDescr = struct(...
                'QueueSize', 25,...
                'ServerType', 'exponential', ... %Or Deterministic
                'ServiceRates', [1.5 1.5],...
                'ServiceClasses', [0],...
                'Variances',[],...
                'AbsorptionProbability', 'random', ...
                'Forwarding','random' ... %or random 
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
