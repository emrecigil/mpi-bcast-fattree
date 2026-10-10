#include "Host.h"

Define_Module(Host);

void Host::initialize()
{
    rank = par("rank");
    totalHosts = par("totalHosts");
    payloadSize = par("payloadSize");
    algorithmMode = par("algorithmMode");
    sendInterval = par("sendInterval");

    receivedBroadcast = false;
    receiveTime = 0;
    messagesSent = 0;
    forwardingActions = 0;
    lastLatency = 0;
    lastHopCount = 0;
    sendTimer = new cMessage("sendTimer");

    EV << "Host rank=" << rank
       << " totalHosts=" << totalHosts
       << " algorithm=" << (algorithmMode == 0 ? "naive" : "divide-and-conquer")
       << " sendInterval=" << sendInterval
       << " initialized." << endl;

    if (rank == 0) {
        cMessage *startMsg = new cMessage("startBroadcast");
        scheduleAt(simTime(), startMsg);
    }
}

BroadcastMessage *Host::createBroadcastMsg(int destRank, int logicalSender,
                                            int rangeStart, int rangeEnd)
{
    char name[64];
    snprintf(name, sizeof(name), "Bcast-%d-to-%d", logicalSender, destRank);
    BroadcastMessage *msg = new BroadcastMessage(name);
    msg->setBroadcastId(1);
    msg->setSrcRank(0);
    msg->setFinalDestRank(destRank);
    msg->setPayloadSize(payloadSize);
    msg->setByteLength(payloadSize);
    msg->setHopCount(0);
    msg->setCreationTime(simTime());
    msg->setLogicalSenderRank(logicalSender);
    msg->setAlgorithmMode(algorithmMode);
    msg->setRangeStart(rangeStart);
    msg->setRangeEnd(rangeEnd);
    return msg;
}

// ======================== SEND QUEUE ========================
// Each host sends one message at a time. After sending, it waits
// sendInterval before sending the next. This models CPU/NIC processing
// cost and is the key reason D&C outperforms naive at scale.

void Host::enqueueSend(BroadcastMessage *msg)
{
    sendQueue.push(msg);
    // If timer is not scheduled, schedule it to trigger sending
    if (!sendTimer->isScheduled()) {
        if (messagesSent == 0) {
            // Very first message: send at current time
            scheduleAt(simTime(), sendTimer);
        } else {
            // Already sent before: wait sendInterval
            scheduleAt(simTime() + sendInterval, sendTimer);
        }
    }
}

void Host::processNextSend()
{
    if (sendQueue.empty())
        return;

    BroadcastMessage *msg = sendQueue.front();
    sendQueue.pop();

    EV << "Host rank=" << rank << ": sending to dest=" << msg->getFinalDestRank() << endl;
    send(msg, "port$o");
    messagesSent++;

    // Schedule next send after sendInterval
    if (!sendQueue.empty()) {
        scheduleAt(simTime() + sendInterval, sendTimer);
    }
}

// ======================== NAIVE BROADCAST ========================

void Host::startNaiveBroadcast()
{
    EV << "Host rank=0 (root): starting NAIVE broadcast to "
       << (totalHosts - 1) << " destinations." << endl;

    for (int dest = 1; dest < totalHosts; dest++) {
        BroadcastMessage *msg = createBroadcastMsg(dest, 0, -1, -1);
        enqueueSend(msg);
    }

    receivedBroadcast = true;
    receiveTime = simTime();
}

// =================== DIVIDE AND CONQUER BROADCAST ===================

void Host::sendDCRange(int logicalSender, int rangeStart, int rangeEnd)
{
    if (rangeStart >= rangeEnd)
        return;

    if (rangeEnd - rangeStart == 1) {
        int dest = rangeStart;
        if (dest == logicalSender)
            return;
        BroadcastMessage *msg = createBroadcastMsg(dest, logicalSender, -1, -1);
        enqueueSend(msg);
        return;
    }

    int mid = (rangeStart + rangeEnd) / 2;

    // Send to midpoint first (it will handle upper half in parallel)
    if (mid != logicalSender) {
        BroadcastMessage *msg = createBroadcastMsg(mid, logicalSender, mid, rangeEnd);
        enqueueSend(msg);
    }

    // Then handle lower half ourselves
    sendDCRange(logicalSender, rangeStart, mid);
}

void Host::startDivideAndConquerBroadcast()
{
    EV << "Host rank=0 (root): starting DIVIDE-AND-CONQUER broadcast to "
       << (totalHosts - 1) << " destinations." << endl;

    int mid = totalHosts / 2;

    // Send to midpoint to handle upper half [mid, totalHosts)
    if (mid > 0 && mid < totalHosts) {
        BroadcastMessage *msg = createBroadcastMsg(mid, 0, mid, totalHosts);
        enqueueSend(msg);
    }

    // Root handles lower half [1, mid) directly
    sendDCRange(0, 1, mid);

    receivedBroadcast = true;
    receiveTime = simTime();
}

void Host::handleDivideAndConquerForward(BroadcastMessage *bcast)
{
    int rStart = bcast->getRangeStart();
    int rEnd = bcast->getRangeEnd();

    if (rStart < 0 || rEnd < 0 || rStart >= rEnd)
        return;

    EV << "Host rank=" << rank << ": D&C forwarding for range ["
       << rStart << "," << rEnd << ")" << endl;

    forwardingActions++;

    int subStart = rStart + 1;
    int subEnd = rEnd;

    if (subStart >= subEnd)
        return;

    if (subEnd - subStart == 1) {
        BroadcastMessage *msg = createBroadcastMsg(subStart, rank, -1, -1);
        enqueueSend(msg);
        return;
    }

    int mid = (subStart + subEnd) / 2;

    // Send to midpoint for upper half
    if (mid < subEnd) {
        BroadcastMessage *msg = createBroadcastMsg(mid, rank, mid, subEnd);
        enqueueSend(msg);
    }

    // Handle lower half ourselves
    sendDCRange(rank, subStart, mid);
}

// ======================== MESSAGE HANDLING ========================

void Host::handleMessage(cMessage *msg)
{
    if (msg->isSelfMessage()) {
        if (msg == sendTimer) {
            // Send queue timer: process next queued message
            processNextSend();
            return;
        }
        // Start broadcast trigger
        if (algorithmMode == 0)
            startNaiveBroadcast();
        else
            startDivideAndConquerBroadcast();
        delete msg;
        return;
    }

    BroadcastMessage *bcast = dynamic_cast<BroadcastMessage *>(msg);
    if (!bcast) {
        delete msg;
        return;
    }

    int destRank = bcast->getFinalDestRank();

    if (destRank != rank) {
        delete msg;
        return;
    }

    receiveTime = simTime();
    receivedBroadcast = true;
    lastLatency = receiveTime - bcast->getCreationTime();
    lastHopCount = bcast->getHopCount();

    EV << "Host rank=" << rank << ": RECEIVED broadcast!"
       << " from logicalSender=" << bcast->getLogicalSenderRank()
       << " hopCount=" << lastHopCount
       << " latency=" << lastLatency
       << endl;

    if (algorithmMode == 1) {
        handleDivideAndConquerForward(bcast);
    }

    delete msg;
}

// ======================== STATISTICS ========================

void Host::finish()
{
    recordScalar("rank", rank);
    recordScalar("algorithmMode", algorithmMode);
    recordScalar("receivedBroadcast", receivedBroadcast ? 1 : 0);
    recordScalar("messagesSent", messagesSent);
    recordScalar("forwardingActions", forwardingActions);

    if (receivedBroadcast) {
        recordScalar("receiveTime", receiveTime.dbl());
        if (rank != 0) {
            recordScalar("endToEndLatency", lastLatency.dbl());
            recordScalar("hopCount", lastHopCount);
        }
    }

    if (rank == 0) {
        recordScalar("rootTransmissions", messagesSent);
        printSummaryTable();
    }

    // Clean up
    cancelAndDelete(sendTimer);
    sendTimer = nullptr;
    while (!sendQueue.empty()) {
        delete sendQueue.front();
        sendQueue.pop();
    }
}

void Host::printSummaryTable()
{
    std::vector<int>    ranks;
    std::vector<bool>   received;
    std::vector<double> recvTimes;
    std::vector<int>    msgsSent;
    std::vector<int>    fwdActions;

    cModule *network = getParentModule();
    int n = totalHosts;

    for (int i = 0; i < n; i++) {
        cModule *mod = network->getSubmodule("host", i);
        if (!mod) continue;
        Host *h = dynamic_cast<Host *>(mod);
        if (!h) continue;

        ranks.push_back(h->rank);
        received.push_back(h->receivedBroadcast);
        recvTimes.push_back(h->receiveTime.dbl());
        msgsSent.push_back(h->messagesSent);
        fwdActions.push_back(h->forwardingActions);
    }

    double maxRecvTime = 0, sumRecvTime = 0;
    int recvCount = 0, totalMsgsSent = 0, totalFwd = 0;

    for (int i = 0; i < (int)ranks.size(); i++) {
        totalMsgsSent += msgsSent[i];
        totalFwd += fwdActions[i];
        if (ranks[i] != 0 && received[i]) {
            recvCount++;
            sumRecvTime += recvTimes[i];
            if (recvTimes[i] > maxRecvTime)
                maxRecvTime = recvTimes[i];
        }
    }

    double avgRecvTime = (recvCount > 0) ? sumRecvTime / recvCount : 0;

    recordScalar("broadcastCompletionTime", maxRecvTime);
    recordScalar("averageReceiveTime", avgRecvTime);
    recordScalar("maxReceiveTime", maxRecvTime);
    recordScalar("totalMessagesSentByHosts", totalMsgsSent);
    recordScalar("totalForwardingActions", totalFwd);

    const char *algoName = (algorithmMode == 0) ? "NAIVE" : "DIVIDE-AND-CONQUER";
    char buf[128];
    char content[80];

    // All lines are exactly 68 chars: | + 66 inner + |
    EV << endl;
    EV << "+------------------------------------------------------------------+" << endl;
    EV << "|            MPI_Bcast SIMULATION RESULTS SUMMARY                  |" << endl;
    EV << "+------------------------------------------------------------------+" << endl;

    snprintf(content, sizeof(content), "Algorithm         : %s", algoName);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Total Hosts       : %d", totalHosts);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Payload Size      : %d B", payloadSize);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Send Interval     : %.6f s", sendInterval.dbl());
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    EV << "+------------------------------------------------------------------+" << endl;
    EV << "|                       AGGREGATE METRICS                          |" << endl;
    EV << "+------------------------------------------------------------------+" << endl;

    snprintf(content, sizeof(content), "Completion Time   : %.9f s", maxRecvTime);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Average Recv Time : %.9f s", avgRecvTime);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Max Recv Time     : %.9f s", maxRecvTime);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Root Transmissions: %d", messagesSent);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Total Msgs Sent   : %d", totalMsgsSent);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Forwarding Actions: %d", totalFwd);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    snprintf(content, sizeof(content), "Hosts Received    : %d / %d", recvCount, totalHosts - 1);
    snprintf(buf, sizeof(buf), "| %-65s|", content); EV << buf << endl;

    // Per-host table: columns = Rank(4) + Recv(4) + Time(16) + Sent(8) + Fwd(18)
    EV << "+------------------------------------------------------------------+" << endl;
    EV << "|                       PER-HOST DETAILS                           |" << endl;
    EV << "+------+------+------------------+----------+--------------------+" << endl;
    EV << "| Rank | Recv |  Receive Time    | Msg Sent | Fwd Actions        |" << endl;
    EV << "+------+------+------------------+----------+--------------------+" << endl;

    for (int i = 0; i < (int)ranks.size(); i++) {
        char timeBuf[18];
        if (ranks[i] == 0)
            snprintf(timeBuf, sizeof(timeBuf), "    (root)      ");
        else if (received[i])
            snprintf(timeBuf, sizeof(timeBuf), " %.9f s", recvTimes[i]);
        else
            snprintf(timeBuf, sizeof(timeBuf), " NOT RECEIVED   ");

        snprintf(buf, sizeof(buf), "| %4d | %4s | %16s | %8d | %18d |",
                 ranks[i],
                 received[i] ? "YES" : " NO",
                 timeBuf,
                 msgsSent[i],
                 fwdActions[i]);
        EV << buf << endl;
    }

    EV << "+------+------+------------------+----------+--------------------+" << endl;
    EV << endl;
}
