# MPI_Bcast on Fat-Tree Topologies (OMNeT++)

An OMNeT++ simulation comparing two `MPI_Bcast`-style broadcast algorithms on
fat-tree data-center topologies with 4, 8, 16 and 32 hosts. Built as a course
project for BBM442 at Hacettepe University.

- **Naive:** the root (rank 0) unicasts the message to every other host itself.
- **Divide-and-conquer (D&C):** the root hands the upper half of the rank range
  to the midpoint host and keeps the lower half; every receiver that owns a
  range repeats the split until each range holds a single host.

## Results

Broadcast completion time is the latest receive time over all non-root hosts.
Payload 1024 B, from [`results_summary.csv`](results_summary.csv):

| Hosts | Naive completion | D&C completion | Reduction | Root sends (naive → D&C) |
|------:|-----------------:|---------------:|----------:|-------------------------:|
| 4     | 4.03 ms          | 2.02 ms        | 50.0%     | 3 → 2                    |
| 8     | 12.05 ms         | 4.02 ms        | 66.7%     | 7 → 3                    |
| 16    | 28.06 ms         | 6.02 ms        | 78.6%     | 15 → 4                   |
| 32    | 60.06 ms         | 8.02 ms        | 86.7%     | 31 → 5                   |

- Naive completion grows linearly with the host count (about 2 ms per extra
  host); D&C grows with log₂ N, adding about 2 ms each time the host count doubles.
- Total messages sent by hosts are the same for both (N − 1); D&C spreads them
  over the forwarding hosts instead of serializing them at the root.
- Switch forwarding work drops by about half, e.g. 163 → 76 switch forwards at
  32 hosts, because forwarders sit closer to their targets.
- Payload size barely matters here: with 8 hosts, 256 B / 1 KB / 4 KB all give a
  66.7% reduction.

### What drives the result

Each host pays a fixed `sendInterval = 2 ms` per message, modelling the CPU/NIC
cost of issuing a send. Link delays are tier-aware but tiny by comparison
(5 ns host–edge, 100 ns edge–aggregation, 500 ns aggregation–core, 1 µs
core–core; 1 Gbps links, 200 ns switch processing). The comparison is therefore
dominated by **how many sends happen one after another on the critical path**:
N − 1 at the naive root versus about log₂ N along any D&C chain. Different
per-message costs would change the absolute times but not that ordering.

## Topologies

Simplified three-tier fat-trees built from pods of 4 hosts on 2 edge switches:

| Topology  | Hosts | Edge | Aggregation | Core |
|-----------|------:|-----:|------------:|-----:|
| FatTree4  | 4     | 2    | –           | 1    |
| FatTree8  | 8     | 4    | 2           | 1    |
| FatTree16 | 16    | 8    | 4           | 2    |
| FatTree32 | 32    | 16   | 8           | 4    |

Routing is deterministic shortest-path (`src/FatTreeRouting.*`). See
[`docs/EXPERIMENTS.md`](docs/EXPERIMENTS.md) for every configuration, metric and
parameter.

## Running

Requires OMNeT++ 6.x (developed on 6.3.0); no INET dependency.

```bash
make makefiles && make          # build src/mpi_bcast_fattree
bash scripts/run_all.sh         # run all 12 configurations (Cmdenv)
bash scripts/export_results.sh  # collect scalars into results_summary.csv
```

A single configuration can also be run from `simulations/`, e.g.
`./run -u Cmdenv -c Opt_16`.

## Layout

```
src/          Host, Switch, routing and BroadcastMessage definitions
simulations/  FatTree4/8/16/32 networks and omnetpp.ini (all configurations)
scripts/      batch run + CSV export
docs/         experiment descriptions
```
