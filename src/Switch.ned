package mpi_bcast_fattree;

// Switch.ned - Phase 2
// Deterministic routing switch for fat-tree topology.
// Uses a routing table parameter to forward messages to the correct output port.

simple Switch
{
    parameters:
        string routingTable = default("");  // format: "rank:gateIdx,rank:gateIdx,..."
        double processingDelay @unit(s) = default(200ns);  // switch forwarding delay
        @display("i=device/switch");
    gates:
        inout port[];
}
