%Create Topology
grid_size = struct('rows',1,'columns',3);
topology = Topology.getTopology(3, grid_size, 1, 1);

%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(100);

%init scheduler with topology
scheduler.init(topology);

%Install Systems on Grid
topology.installSystems(0, 1, 0, 3); %capacity(inf), num_servers per system, policy, rates

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

scheduler.destroy();
topology.destroy();
clear;
