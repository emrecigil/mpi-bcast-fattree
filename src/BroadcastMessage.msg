// BroadcastMessage.msg
// Phase 2: Extended message definition for MPI_Bcast-like broadcast comparison

packet BroadcastMessage
{
    int broadcastId;
    int srcRank;
    int finalDestRank;
    int payloadSize;
    int hopCount = 0;
    simtime_t creationTime;
    int logicalSenderRank;    // rank of the node that initiated this particular send
    int algorithmMode;        // 0 = naive, 1 = divide-and-conquer

    // Divide-and-conquer metadata: the range this receiver is responsible for
    int rangeStart = -1;
    int rangeEnd = -1;
}
