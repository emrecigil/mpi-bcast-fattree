package mpi_bcast_fattree;

// Host.ned - Phase 2
// Host module supporting naive and divide-and-conquer broadcast algorithms.

simple Host
{
    parameters:
        int rank;
        int totalHosts;                    // total number of hosts in the network
        int payloadSize = default(1024);   // broadcast payload in bytes
        int algorithmMode = default(0);    // 0 = naive, 1 = divide-and-conquer
        double sendInterval @unit(s) = default(0.0005s);  // delay between consecutive sends (models CPU/NIC cost)
        @display("i=device/pc");
    gates:
        inout port;
}
