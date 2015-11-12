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
                     'flow', 'random'); %or 'random'
                 
topology = Topology.getTopology(10, grid_size, topo_policy); 
%num_nodes, grid_size, mesh_connect_probability, connect_edges_0_1

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(100);

%init scheduler with topology
scheduler.init(topology);

%Install Systems on Grid
drop_policy = 'random'; %for no drop in non-edge nodes, or 'random'.
topology.installSystems(25, 2, drop_policy, [1.5 1.5]); %capacity(inf), num_servers per system, policy, rates

%Install Adjacencies
topology.installAdjacencies();

%Associate streams with each node
scheduler.scheduleStreams(2); %parameter is lambda value (array of lambdas)

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
