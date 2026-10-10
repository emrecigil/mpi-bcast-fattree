#ifndef HOST_H_
#define HOST_H_

#include <omnetpp.h>
#include <vector>
#include <queue>
#include "BroadcastMessage_m.h"

using namespace omnetpp;

class Host : public cSimpleModule
{
  private:
    int rank;
    int totalHosts;
    int payloadSize;
    int algorithmMode;  // 0=naive, 1=divide-and-conquer
    simtime_t sendInterval;  // delay between consecutive sends

    // Reception tracking
    bool receivedBroadcast;
    simtime_t receiveTime;

    // Transmission tracking
    int messagesSent;
    int forwardingActions;
    simtime_t lastLatency;
    int lastHopCount;

    // Send queue: messages waiting to be sent (one at a time with sendInterval)
    std::queue<BroadcastMessage *> sendQueue;
    cMessage *sendTimer;  // self-message to trigger next send

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;

  private:
    void startNaiveBroadcast();
    void startDivideAndConquerBroadcast();
    void handleDivideAndConquerForward(BroadcastMessage *bcast);

    BroadcastMessage *createBroadcastMsg(int destRank, int logicalSender,
                                          int rangeStart, int rangeEnd);
    void enqueueSend(BroadcastMessage *msg);
    void processNextSend();
    void sendDCRange(int logicalSender, int rangeStart, int rangeEnd);
    void printSummaryTable();
};

#endif
