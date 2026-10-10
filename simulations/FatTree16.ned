package mpi_bcast_fattree.simulations;

import mpi_bcast_fattree.Host;
import mpi_bcast_fattree.Switch;

// FatTree16: 16 hosts, 8 edge switches, 4 aggregation switches, 2 core switches
//
// Structure (4 pods, 4 hosts per pod):
//   Pod 0: host[0..3]  -> edge[0],edge[1]  -> agg[0]
//   Pod 1: host[4..7]  -> edge[2],edge[3]  -> agg[1]
//   Pod 2: host[8..11] -> edge[4],edge[5]  -> agg[2]
//   Pod 3: host[12..15]-> edge[6],edge[7]  -> agg[3]
//   Core: core[0] connects agg[0],agg[1]; core[1] connects agg[2],agg[3]
//   Inter-core: core[0] <-> core[1]

network FatTree16
{
    parameters:
        double hostEdgeDelay @unit(s) = default(5ns);
        double edgeAggDelay @unit(s) = default(100ns);
        double aggCoreDelay @unit(s) = default(500ns);
        double coreCoreDelay @unit(s) = default(1us);
        double linkDatarate @unit(bps) = default(1Gbps);

    submodules:
        host[16]: Host {
            rank = index;
            totalHosts = 16;
        }

        edge[8]: Switch;
        agg[4]: Switch;
        core[2]: Switch;

    connections:
        // Pod 0
        host[0].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[0].port++;
        host[1].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[0].port++;
        host[2].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[1].port++;
        host[3].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[1].port++;
        edge[0].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[0].port++;
        edge[1].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[0].port++;

        // Pod 1
        host[4].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[2].port++;
        host[5].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[2].port++;
        host[6].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[3].port++;
        host[7].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[3].port++;
        edge[2].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[1].port++;
        edge[3].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[1].port++;

        // Pod 2
        host[8].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[4].port++;
        host[9].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[4].port++;
        host[10].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[5].port++;
        host[11].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[5].port++;
        edge[4].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[2].port++;
        edge[5].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[2].port++;

        // Pod 3
        host[12].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[6].port++;
        host[13].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[6].port++;
        host[14].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[7].port++;
        host[15].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[7].port++;
        edge[6].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[3].port++;
        edge[7].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[3].port++;

        // Aggregation to core
        agg[0].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[0].port++;
        agg[1].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[0].port++;
        agg[2].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;
        agg[3].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;

        // Core interconnect
        core[0].port++ <--> { delay = parent.coreCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;
}
