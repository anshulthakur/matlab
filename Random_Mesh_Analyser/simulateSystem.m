%Create Topology
grid_size = struct('rows',5,'columns',5);

topo_policy = struct('connect_vertical_edge_nodes', 0, ...
                     'connect_horizontal_edge_nodes', 1, ...
                     'connect_same_level_peers', 0, ...
                     'adjacent_peer_probability', 1, ...
                     'flow', 'forward'); %or 'random'
                 
topology = Topology.getTopology(25, grid_size, topo_policy); 
%num_nodes, grid_size, mesh_connect_probability, connect_edges_0_1

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(20);

%init scheduler with topology
scheduler.init(topology);

%Install Systems on Grid
drop_policy = 'left'; %for no drop in non-edge nodes, or 'random'.
topology.installSystems(0, 2, drop_policy, [3 3]); %capacity(inf), num_servers per system, policy, rates

%Install Adjacencies
topology.installAdjacencies();

%Associate streams with each node
scheduler.scheduleStreams(2); %parameter is lambda value (array of lambdas)
%**BUG**For multiclass traffic, there should be multiple queues at each
%system.

%Run scheduler
scheduler.spinScheduler();
while(scheduler.isRunning())
    scheduler.runScheduler();
end

%Visualize:

%1. Service time distribution across network.
%2. Service time distribution across each node.
%3. Waiting time distribution across network.
%4. Packet delay distribution [and average]
%5. Busy period distribution [and average]
%6. Queue size distribution [and average]

topology.visualize();
hold off;

figure('Name','Packet Life');
scheduler.visualizePacketLife();

scheduler.showQueueLengths();
scheduler.showSystemPopulation();

figure('Name','Service Times');
scheduler.visualizeServiceTime('network',0);

figure('Name','Packet Waiting Times');
scheduler.visualizePacketWaitTimes();

fprintf('\nAverage hopcounts: %d',scheduler.averageHopCounts());

scheduler.getUtilization('network',0);

%Cleanup the system.
scheduler.destroy();
topology.destroy();
clear;