package mpi_bcast_fattree.simulations;

import mpi_bcast_fattree.Host;
import mpi_bcast_fattree.Switch;

// FatTree8: 8 hosts, 4 edge switches, 2 aggregation switches, 1 core switch
//
// Topology (3-tier simplified fat-tree):
//
//   host0,1 -- edge0 --\         /-- edge2 -- host4,5
//                        agg0 --+
//   host2,3 -- edge1 --/    \   \-- edge3 -- host6,7
//                             core0
//                            /
//   (agg0 and agg1 both     /
//    connect to core0)     agg1
//
// Actually a cleaner layout:
//   Pod 0: host0,1 -> edge0; host2,3 -> edge1; edge0,edge1 -> agg0
//   Pod 1: host4,5 -> edge2; host6,7 -> edge3; edge2,edge3 -> agg1
//   Core: agg0 <-> core0 <-> agg1
//
// Gate assignments:
//   edge0: port[0]=host0, port[1]=host1, port[2]=agg0
//   edge1: port[0]=host2, port[1]=host3, port[2]=agg0
//   edge2: port[0]=host4, port[1]=host5, port[2]=agg1
//   edge3: port[0]=host6, port[1]=host7, port[2]=agg1
//   agg0: port[0]=edge0, port[1]=edge1, port[2]=core0
//   agg1: port[0]=edge2, port[1]=edge3, port[2]=core0
//   core0: port[0]=agg0, port[1]=agg1

network FatTree8
{
    parameters:
        double hostEdgeDelay @unit(s) = default(5ns);
        double edgeAggDelay @unit(s) = default(100ns);
        double aggCoreDelay @unit(s) = default(500ns);
        double coreCoreDelay @unit(s) = default(1us);
        double linkDatarate @unit(bps) = default(1Gbps);

    submodules:
        host[8]: Host {
            rank = index;
            totalHosts = 8;
        }

        edge[4]: Switch;
        agg[2]: Switch;
        core: Switch;

    connections:
        // Pod 0: hosts to edge switches
        host[0].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[0].port++;
        host[1].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[0].port++;
        host[2].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[1].port++;
        host[3].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[1].port++;

        // Pod 1: hosts to edge switches
        host[4].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[2].port++;
        host[5].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[2].port++;
        host[6].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[3].port++;
        host[7].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[3].port++;

        // Edge to aggregation
        edge[0].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[0].port++;
        edge[1].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[0].port++;
        edge[2].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[1].port++;
        edge[3].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[1].port++;

        // Aggregation to core
        agg[0].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core.port++;
        agg[1].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core.port++;
}
