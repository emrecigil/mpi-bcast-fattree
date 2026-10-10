#ifndef FATTREEROUTING_H_
#define FATTREEROUTING_H_

#include <omnetpp.h>
#include <map>
#include <vector>
#include <string>

using namespace omnetpp;

// FatTreeRouting: deterministic routing for fat-tree topologies.
//
// Each switch has a parameter "routingTable" which is a string of the form:
//   "rank1:gateIndex1,rank2:gateIndex2,..."
// This maps destination host ranks to output gate indices.
//
// The routing table is populated from the NED/ini configuration, making the
// switch routing fully deterministic and explainable.

class FatTreeRouting
{
  public:
    // Parse a routing table string into a map: destRank -> gateIndex
    static std::map<int, int> parseRoutingTable(const std::string &tableStr);

    // Look up the output gate index for a given destination rank.
    // Returns -1 if not found.
    static int lookupRoute(const std::map<int, int> &table, int destRank);
};

#endif
