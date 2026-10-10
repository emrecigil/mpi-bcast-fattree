#include "Switch.h"

Define_Module(Switch);

void Switch::initialize()
{
    totalForwarded = 0;
    totalDropped = 0;
    processingDelay = par("processingDelay");

    std::string tableStr = par("routingTable").stringValue();
    routeTable = FatTreeRouting::parseRoutingTable(tableStr);

    EV << "Switch " << getFullPath() << " initialized with "
       << gateSize("port") << " ports, "
       << routeTable.size() << " routing entries." << endl;

    for (auto &entry : routeTable) {
        EV << "  route: rank " << entry.first << " -> gate " << entry.second << endl;
    }
}

void Switch::handleMessage(cMessage *msg)
{
    BroadcastMessage *bcast = dynamic_cast<BroadcastMessage *>(msg);
    if (!bcast) {
        EV << "Switch " << getFullPath() << ": non-broadcast message, dropping." << endl;
        delete msg;
        totalDropped++;
        return;
    }

    int destRank = bcast->getFinalDestRank();
    int outGate = FatTreeRouting::lookupRoute(routeTable, destRank);

    if (outGate < 0) {
        EV << "Switch " << getFullPath() << ": no route for dest=" << destRank
           << ", dropping." << endl;
        delete msg;
        totalDropped++;
        return;
    }

    // Increment hop count
    bcast->setHopCount(bcast->getHopCount() + 1);

    EV << "Switch " << getFullPath() << ": forwarding dest=" << destRank
       << " to gate " << outGate
       << " (hopCount=" << bcast->getHopCount() << ")" << endl;

    sendDelayed(bcast, processingDelay, "port$o", outGate);
    totalForwarded++;
}

void Switch::finish()
{
    recordScalar("totalForwarded", totalForwarded);
    recordScalar("totalDropped", totalDropped);

    EV << "Switch " << getFullPath()
       << ": forwarded=" << totalForwarded
       << " dropped=" << totalDropped << endl;
}
