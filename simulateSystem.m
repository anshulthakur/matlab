scheduler = SimScheduler.getScheduler();
scheduler.setRunLength(10);

system{1} =  System(1,0,1,0,[], 2); %Initialize system
packet = Packet(); %Create Packet

scheduler.addSystem(system);

scheduler.runScheduler();

scheduler.RegisterPacketDestroy(packet);
system.enqueue(packet); %enqueue packet

while(scheduler.isRunning())
    scheduler.runScheduler();
end
scheduler.destroy();
clear packet;
clear system;
clear scheduler;


%Create Topology
%Create SimScheduler
%Install Systems on Grid
%Install Adjacencies