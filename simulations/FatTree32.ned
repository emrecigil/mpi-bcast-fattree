package mpi_bcast_fattree.simulations;

import mpi_bcast_fattree.Host;
import mpi_bcast_fattree.Switch;

// FatTree32: 32 hosts, 16 edge switches, 8 aggregation switches, 2 core switches
//
// Structure (8 pods, 4 hosts per pod):
//   Pod 0: host[0..3]   -> edge[0],edge[1]   -> agg[0]
//   Pod 1: host[4..7]   -> edge[2],edge[3]   -> agg[1]
//   Pod 2: host[8..11]  -> edge[4],edge[5]   -> agg[2]
//   Pod 3: host[12..15] -> edge[6],edge[7]   -> agg[3]
//   Pod 4: host[16..19] -> edge[8],edge[9]   -> agg[4]
//   Pod 5: host[20..23] -> edge[10],edge[11] -> agg[5]
//   Pod 6: host[24..27] -> edge[12],edge[13] -> agg[6]
//   Pod 7: host[28..31] -> edge[14],edge[15] -> agg[7]
//
//   Core layer (2 core switches):
//     core[0] connects agg[0],agg[1],agg[2],agg[3]  (pods 0-3, hosts 0-15)
//     core[1] connects agg[4],agg[5],agg[6],agg[7]  (pods 4-7, hosts 16-31)
//     core[0] <-> core[1]
//
// Gate assignments:
//   core[0]: port[0]=agg[0], port[1]=agg[1], port[2]=agg[2], port[3]=agg[3], port[4]=core[1]
//   core[1]: port[0]=agg[4], port[1]=agg[5], port[2]=agg[6], port[3]=agg[7], port[4]=core[0]

network FatTree32
{
    parameters:
        double hostEdgeDelay @unit(s) = default(5ns);
        double edgeAggDelay @unit(s) = default(100ns);
        double aggCoreDelay @unit(s) = default(500ns);
        double coreCoreDelay @unit(s) = default(1us);
        double linkDatarate @unit(bps) = default(1Gbps);

    submodules:
        host[32]: Host {
            rank = index;
            totalHosts = 32;
        }

        edge[16]: Switch;
        agg[8]: Switch;
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

        // Pod 4
        host[16].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[8].port++;
        host[17].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[8].port++;
        host[18].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[9].port++;
        host[19].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[9].port++;
        edge[8].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[4].port++;
        edge[9].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[4].port++;

        // Pod 5
        host[20].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[10].port++;
        host[21].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[10].port++;
        host[22].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[11].port++;
        host[23].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[11].port++;
        edge[10].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[5].port++;
        edge[11].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[5].port++;

        // Pod 6
        host[24].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[12].port++;
        host[25].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[12].port++;
        host[26].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[13].port++;
        host[27].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[13].port++;
        edge[12].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[6].port++;
        edge[13].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[6].port++;

        // Pod 7
        host[28].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[14].port++;
        host[29].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[14].port++;
        host[30].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[15].port++;
        host[31].port <--> { delay = parent.hostEdgeDelay; datarate = parent.linkDatarate; } <--> edge[15].port++;
        edge[14].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[7].port++;
        edge[15].port++ <--> { delay = parent.edgeAggDelay; datarate = parent.linkDatarate; } <--> agg[7].port++;

        // Aggregation to core
        agg[0].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[0].port++;
        agg[1].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[0].port++;
        agg[2].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[0].port++;
        agg[3].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[0].port++;

        agg[4].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;
        agg[5].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;
        agg[6].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;
        agg[7].port++ <--> { delay = parent.aggCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;

        // Core interconnect
        core[0].port++ <--> { delay = parent.coreCoreDelay; datarate = parent.linkDatarate; } <--> core[1].port++;
}
