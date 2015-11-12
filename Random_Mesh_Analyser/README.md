##Random Mesh Analyser

This code simulates a theoretic network of multiple nodes connected in a random manner and 
analyses the network performance in terms of Packet End to End delays, server utilizations,
service time and waiting time distribtions across the network etc.

## How to use this code:
Samples of how to create various topologies are available with the file prefixes `scenario\_X`. 
The basic steps are delineated below:

1. Create a Topology. 
   A Topology is a 2D grid of `NxM` dimensions or crosspoints. Each crossing point is considered to be a potential site for node placement. While creating a topology, user must specify the policy of connections (see example below). 
  
   ```matlab
   grid_size = struct('rows',5,'columns',5);
   topo_policy = struct('connect_vertical_edge_nodes', 0, ... %Connect vertical Edge nodes or not?
                     'connect_horizontal_edge_nodes', 1, ... %Connect horizontal Edge nodes or not?
                     'connect_same_level_peers', 0, ... %Connect peers in the same column or not?
                     'adjacent_peer_probability', 1, ... %Probability of connecting with an eligible peer.[0-1]
                     'flow', 'forward'); %or 'random'. Packets flow left to right, or randomly (could visit the same node multiple times).

   %Create topology: Place 25 Nodes on the grid.
   topology = Topology.getTopology(25, grid_size, topo_policy); 
   ```
   The Topology is implemented as a singleton, so calling it more than once will have no effect. Also, to re-run the simulation, the `destroy()` method for topology must have been called before.

2. Create a Simulation Scheduler Instance
   To create an illusion of passage of time (discrete time simulation), this scheduler must be initialized. This again is a singleton and only one scheduler can be created for a simulation. The user must specify the time (in 't' seconds for which the simulation must run). Please note that this 't' is not the actual run time, but the simulated time. That is, setting it to 100 does not mean that the simulation will run for 100 seconds, but will simulate as if it observed the system for 100 seconds. Depending on the Machine the simulation is run on, it may take a few seconds, to even hours to complete.

   ```matlab
   scheduler = SimScheduler.getScheduler();
   scheduler.setRunLength(100);
   ```

3. Tell the scheduler about the topology.

   ```matlab
   scheduler.init(topology);
   ```

4. Install Systems to be simulated on the nodes placed in the topology.
   While installing systems on nodes, one must specify the attributes of the systems. Currently, the code supports only homogeneous systems (all identical). The policy may be `left` where no drop occurs at nodes which are not at the right edge of the topology. This simulates a packet flow from right to left in a transit network where traffic streams may be merging from multiple sources into a few PoPs.

   Each system consists of an Input Queue, an internal job Scheduler, service station(s) and a transmit buffer. The service rate of servers must be specified.

   ```matlab   
   drop_policy = 'left'; %for no drop in non-edge nodes, or 'random'.
   topology.installSystems(20, 2, drop_policy, [3 3]); %capacity(0 for infinite), num_servers per system, policy, rates
   ```

5. Install adjacencies on the systems once they've been placed on the grid. This initializes their transmit buffers to enqueue packets on the neighbour's input Queues post service completion.

   ```matlab
   topology.installAdjacencies();
   ```

6. Associate traffic streams with each node with rate `lambda`. These streams are installed by the Simulation scheduler which schedules packet generation per stream and overall job scheduling.

   ```matlab
   scheduler.scheduleStreams(2);
   ```

7. Start simulation:

   ```matlab
   scheduler.spinScheduler();
   while(scheduler.isRunning())
       scheduler.runScheduler();
   end
   ```

8. Get simulation statistics:

   ```matlab
   topology.visualize();
   scheduler.visualizePacketLife();
   
   scheduler.showQueueLengths();
   scheduler.showSystemPopulation();

   scheduler.visualizeServiceTime('network',0);

   scheduler.visualizePacketWaitTimes();

   fprintf('\nAverage hopcounts: %d',scheduler.averageHopCounts());

   scheduler.getUtilization('network',0);

   scheduler.getBlockingProbability('network',0);
   ```

9. Cleanup resources

   ```matlab
   scheduler.destroy();
   topology.destroy();
   clear;
   ```
