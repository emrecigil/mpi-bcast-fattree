package mpi_bcast_fattree.simulations;

import mpi_bcast_fattree.Host;
import mpi_bcast_fattree.Switch;

// TestNetwork.ned
// Fat-tree-like topology: 4 hosts, 2 edge switches, 1 core switch

network TestNetwork
{
    submodules:
        host0: Host { rank = 0; }
        host1: Host { rank = 1; }
        host2: Host { rank = 2; }
        host3: Host { rank = 3; }

        edge0: Switch;
        edge1: Switch;
        core0: Switch;

    connections:
        host0.port <--> { delay = 0.001s; datarate = 1Gbps; } <--> edge0.port++;
        host1.port <--> { delay = 0.001s; datarate = 1Gbps; } <--> edge0.port++;
        host2.port <--> { delay = 0.001s; datarate = 1Gbps; } <--> edge1.port++;
        host3.port <--> { delay = 0.001s; datarate = 1Gbps; } <--> edge1.port++;
        edge0.port++ <--> { delay = 0.001s; datarate = 1Gbps; } <--> core0.port++;
        edge1.port++ <--> { delay = 0.001s; datarate = 1Gbps; } <--> core0.port++;
}
