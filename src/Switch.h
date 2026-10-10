#ifndef SWITCH_H_
#define SWITCH_H_

#include <omnetpp.h>
#include <map>
#include "BroadcastMessage_m.h"
#include "FatTreeRouting.h"

using namespace omnetpp;

class Switch : public cSimpleModule
{
  private:
    std::map<int, int> routeTable;  // destRank -> output gate index
    int totalForwarded;
    int totalDropped;
    simtime_t processingDelay;

  protected:
    virtual void initialize() override;
    virtual void handleMessage(cMessage *msg) override;
    virtual void finish() override;
};

#endif
