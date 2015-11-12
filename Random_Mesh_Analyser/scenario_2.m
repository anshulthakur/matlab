% Scenario:
% A topology of 25 nodes placed on a 5x5 grid and connected in a
% random packet flow model with drops at any node.
% Nodes on the same level (same column) can peer with each other.
% Infinite buffer capacities at each node, but single servers

%Create Topology
grid_size = struct('rows',5,'columns',5);
topo_policy = struct('connect_vertical_edge_nodes', 1, ...
                     'connect_horizontal_edge_nodes', 1, ...
                     'connect_same_level_peers', 1, ...
                     'adjacent_peer_probability', 1, ...
                     'flow', 'random'); %or 'random'
                 
topology = Topology.getTopology(25, grid_size, topo_policy); 
%num_nodes, grid_size, mesh_connect_probability, connect_edges_0_1

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(100);

%init scheduler with topology
scheduler.init(topology);

%Install Systems on Grid
drop_policy = 'random'; %for no drop in non-edge nodes, or 'random'.
topology.installSystems(0, 1, drop_policy, [3]); %capacity(inf), num_servers per system, policy, rates

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
hold off;

scheduler.showQueueLengths();

scheduler.showSystemPopulation();

scheduler.visualizeServiceTime('network',0);
hold off;

scheduler.visualizePacketWaitTimes();

fprintf('\nAverage hopcounts: %d',scheduler.averageHopCounts());

scheduler.getUtilization('network',0);

scheduler.getBlockingProbability('network',0);
%Cleanup the system.
scheduler.destroy();
topology.destroy();
clear;
