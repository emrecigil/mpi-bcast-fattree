package mpi_bcast_fattree.simulations;

import mpi_bcast_fattree.Host;
import mpi_bcast_fattree.Switch;

// FatTree4: 4 hosts, 2 edge switches, 1 core switch
//
// Topology:
//   host0 --+-- edge0 --+-- core0 --+-- edge1 --+-- host2
//   host1 --+           |           |           +-- host3
//                       +-----------+
//
// Gate assignments:
//   edge0: port[0]=host0, port[1]=host1, port[2]=core0
//   edge1: port[0]=host2, port[1]=host3, port[2]=core0
//   core0: port[0]=edge0, port[1]=edge1

network FatTree4
{
    parameters:
        double hostEdgeDelay @unit(s) = default(5ns);
        double edgeAggDelay @unit(s) = default(100ns);
        double aggCoreDelay @unit(s) = default(500ns);
        double coreCoreDelay @unit(s) = default(1us);
        double linkDatarate @unit(bps) = default(1Gbps);

    submodules:
        host[4]: Host {
            rank = index;
            totalHosts = 4;
        }

        edge[2]: Switch;
        core: Switch;

    connections:
        // Hosts to edge switches
        host[0].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[0].port++;
        host[1].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[0].port++;
        host[2].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[1].port++;
        host[3].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[1].port++;

        // Edge to core
        edge[0].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core.port++;
        edge[1].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core.port++;
}
