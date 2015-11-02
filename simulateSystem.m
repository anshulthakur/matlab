%Create Topology
grid_size = struct('rows',1,'columns',2);
topology = Topology.getTopology(2, grid_size, 1, 1);
%Create SimScheduler
scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(10);
%init Scheduler with scheduler
scheduler.init(topology);

%Install Systems on Grid
topology.installSystems(0, 1, 0, 2);
%Install Adjacencies
topology.installAdjacencies();

%system{1} =  System(1,0,1,0,[], 2); %Initialize system
%packet = Packet(); %Create Packet

%scheduler.addSystems(system);

scheduler.runScheduler();

scheduler.RegisterPacketDestroy(packet);
system.enqueue(packet); %enqueue packet

while(scheduler.isRunning())
    scheduler.runScheduler();
end
scheduler.destroy();
topology.destroy();
clear;
