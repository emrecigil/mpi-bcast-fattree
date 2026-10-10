#include "FatTreeRouting.h"
#include <sstream>

std::map<int, int> FatTreeRouting::parseRoutingTable(const std::string &tableStr)
{
    std::map<int, int> table;
    if (tableStr.empty())
        return table;

    std::stringstream ss(tableStr);
    std::string entry;
    while (std::getline(ss, entry, ',')) {
        // Each entry is "rank:gateIndex"
        size_t colon = entry.find(':');
        if (colon == std::string::npos)
            continue;
        int rank = std::stoi(entry.substr(0, colon));
        int gate = std::stoi(entry.substr(colon + 1));
        table[rank] = gate;
    }
    return table;
}

int FatTreeRouting::lookupRoute(const std::map<int, int> &table, int destRank)
{
    auto it = table.find(destRank);
    if (it != table.end())
        return it->second;
    return -1;
}
