%Create a topology of of 1 M/D/1 system and vary the lambda from 1 to 20
%and plot the packet lifetime (Packet Delay) for each case
rate = 100; %packets per second
lifetimes = zeros(1,25);
for i=1:25
    lambda = i;
    %Placement of nodes
    grid = [[1 2 3 4 5]];       
    topo = struct('mode','manual',...
                  'grid', grid,...
                  'num_nodes',0,...
                  'grid_size',0,...
                  'topologyPolicy',cell(1,1)...
                  );                     
    %Get a topology object. This places Node objects on the desired points.        
    topology = Topology.getTopology(topo); 
    
    %Define neighbours to each node now
    topology.addNeighbours(1, [2]);
    topology.addNeighbours(2, [3]);
    topology.addNeighbours(3, [4]);
    topology.addNeighbours(4, [5]);

    %Create SimScheduler
    scheduler = SimScheduler.getScheduler();
    scheduler.setRunLength(50);

    %init scheduler with topology
    scheduler.init(topology);

    %install systems on grid
    systemDescr = struct(...
                    'QueueSize', 0,...
                    'ServerType', 'deterministic', ... %Or packetLength, or exponential
                    'ServiceRates', [rate],...
                    'ServiceClasses', [0],...
                    'Variances',[0],...
                    'AbsorptionProbability',1, ...
                    'Forwarding','balance' ... %or random 
                    );

    %Install system of particular type on particular nodes
    topology.installSystems([5], systemDescr); %Install same kind of system on all nodes

    %install systems on grid
    systemDescr = struct(...
                    'QueueSize', 0,...
                    'ServerType', 'exponential', ... %Or packetLength, or exponential
                    'ServiceRates', [rate],...
                    'ServiceClasses', [0],...
                    'Variances',[0],...
                    'AbsorptionProbability',0, ...
                    'Forwarding','balance' ... %or random 
                    );

    %Install system of particular type on particular nodes
    topology.installSystems([1 2 3 4], systemDescr); %Install same kind of system on all nodes

    %Initialize systems
    topology.initSystems();

    %Associate streams with each node
    streamDescr = struct( ...  
                    'StreamType', 'poisson', ...
                    'GenerationTime', 100, ... %seconds
                    'lambda', lambda, ...
                    'class', 0, ...
                    'packetLength', 0 ...
                        );
    topology.installStream([1 2 3 4], streamDescr);

    %**TODO**For multiclass traffic, there should be multiple queues at each
    %system.

    %Run scheduler
    scheduler.spinScheduler();
    while(scheduler.isRunning())
        scheduler.runScheduler();
    end

    %topology.visualize();
    %hold off;
    %scheduler.visualizePacketLife();
    scheduler.showQueueLengths();
    lifetimes(i) = (scheduler.getMeanPacketLifetime());
    %scheduler.visualizePacketWaitTimes();
    %Cleanup the system.
    scheduler.destroy();
    topology.destroy();
    clear grid scheduler topo topology;
end
hold off;
fig = figure();
set(fig,'defaulttextinterpreter','latex');
plot(4:4:100, lifetimes, 'x:');
hold on;
theory_lives = zeros(1,25);
for i=1:length(theory_lives)
    lambda = i*4;
    theory_lives(i) = ((1/rate) + ((lambda*(1/(rate * rate)))/(2*(1 - (lambda * (1/rate))))))*1000;
end
plot(4:4:100, theory_lives, 'o-');
xlabel('\lambda (per sec)');
ylabel('delay (ms)');
legend('Simulation', 'Theory');