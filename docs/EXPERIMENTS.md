# Experiment Descriptions - Phase 2

## Overview

This project compares two MPI_Bcast-like broadcast algorithms on fat-tree topologies:

- **Naive Broadcast**: Root (rank 0) sends individual unicast messages to every destination host. No forwarding by non-root hosts.
- **Optimized (Divide-and-Conquer) Broadcast**: Root divides the destination set recursively. It sends to a midpoint host, which then becomes an active forwarder for its assigned subset. This continues recursively until all hosts have received the broadcast.

## Configurations

| Config Name     | Algorithm          | Hosts | Topology  | Payload |
|-----------------|--------------------|-------|-----------|---------|
| Naive_4         | Naive              | 4     | FatTree4  | 1024B   |
| Opt_4           | Divide-and-Conquer | 4     | FatTree4  | 1024B   |
| Naive_8         | Naive              | 8     | FatTree8  | 1024B   |
| Opt_8           | Divide-and-Conquer | 8     | FatTree8  | 1024B   |
| Naive_16        | Naive              | 16    | FatTree16 | 1024B   |
| Opt_16          | Divide-and-Conquer | 16    | FatTree16 | 1024B   |
| Naive_32        | Naive              | 32    | FatTree32 | 1024B   |
| Opt_32          | Divide-and-Conquer | 32    | FatTree32 | 1024B   |
| Naive_8_256B    | Naive              | 8     | FatTree8  | 256B    |
| Naive_8_4096B   | Naive              | 8     | FatTree8  | 4096B   |
| Opt_8_256B      | Divide-and-Conquer | 8     | FatTree8  | 256B    |
| Opt_8_4096B     | Divide-and-Conquer | 8     | FatTree8  | 4096B   |

## Topologies

All topologies follow a fat-tree-like hierarchical structure:

- **FatTree4**: 4 hosts, 2 edge switches, 1 core switch
- **FatTree8**: 8 hosts, 4 edge switches, 2 aggregation switches, 1 core switch
- **FatTree16**: 16 hosts, 8 edge switches, 4 aggregation switches, 2 core switches
- **FatTree32**: 32 hosts, 16 edge switches, 8 aggregation switches, 4 core switches

Each pod contains 4 hosts connected to 2 edge switches. Edge switches connect to an aggregation switch. Aggregation switches connect to core switches. Core switches are interconnected.

## Metrics Collected

Each host records the following scalars in `finish()`:

| Metric             | Description                                                  |
|--------------------|--------------------------------------------------------------|
| `rank`             | Host's rank identifier                                       |
| `algorithmMode`    | 0 = naive, 1 = divide-and-conquer                           |
| `receivedBroadcast`| 1 if the host received the broadcast, 0 otherwise           |
| `receiveTime`      | Simulation time when the broadcast was received              |
| `messagesSent`     | Number of messages sent by this host                         |
| `forwardingActions`| Number of forwarding actions (D&C only, non-root)            |
| `rootTransmissions`| Messages sent by root (recorded only at rank 0)             |

Each switch records:

| Metric           | Description                                     |
|------------------|-------------------------------------------------|
| `totalForwarded` | Number of messages forwarded by this switch      |
| `totalDropped`   | Number of messages dropped (no route found)      |

## Derived Metrics (computed from raw scalars)

| Derived Metric           | How to Compute                                                |
|--------------------------|---------------------------------------------------------------|
| broadcastCompletionTime  | max(receiveTime) across all hosts with rank > 0               |
| averageReceiveTime       | avg(receiveTime) across all hosts with rank > 0               |
| maxReceiveTime           | same as broadcastCompletionTime                               |
| totalMessageCopies       | sum(messagesSent) across all hosts + sum(totalForwarded) across switches |
| totalHopCount            | sum of hop counts from all received messages (logged in EV)   |
| rootTransmissions        | messagesSent at rank 0                                        |

## Link Parameters

Tier-aware propagation delays model realistic fiber distances within a data center.
Values are based on ~5 ns/m propagation speed in fiber optic cable and typical
cable lengths: rack-internal ~1 m, intra-pod ~20 m, inter-pod ~100 m, core-to-core ~200 m.

| Parameter        | Default Value | Description                          |
|------------------|---------------|--------------------------------------|
| hostEdgeDelay    | 5ns           | Host to edge switch (~1 m rack-internal) |
| edgeAggDelay     | 100ns         | Edge to aggregation switch (~20 m intra-pod) |
| aggCoreDelay     | 500ns         | Aggregation to core switch (~100 m inter-pod) |
| coreCoreDelay    | 1us           | Core to core switch (~200 m core-to-core) |
| linkDatarate     | 1 Gbps        | All links                            |
| processingDelay  | 200ns         | Switch forwarding processing delay   |
| payloadSize      | 1024 bytes    | Broadcast message payload            |
| sendInterval     | 0.002s        | Host CPU/NIC per-message processing cost |
