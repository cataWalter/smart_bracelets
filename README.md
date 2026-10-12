# Smart Bracelets — Child Safety over a Wireless Sensor Network

[![TinyOS](https://img.shields.io/badge/OS-TinyOS-orange)](https://github.com/tinyos/tinyos-main)
[![nesC](https://img.shields.io/badge/Language-nesC-blue)](https://nescc.sourceforge.net/)
[![Platform](https://img.shields.io/badge/Hardware-MicaZ%20motes-lightgrey)](#)
[![Simulation](https://img.shields.io/badge/Simulation-TOSSIM%20%2B%20Node--RED-red)](https://github.com/tinyos/tinyos-main)

> A parent/child safety system built on **TinyOS** for resource-constrained wireless sensor nodes. A bracelet worn by the child tracks its position and detects falls; the parent's bracelet receives alerts (fall / missing) with the child's last known coordinates.

Academic project — *D. Frigerio & W. Catalfamo*.

---

## 🎯 Goal

Implement a pair of smart bracelets (one for a **child**, one for the **parent**) that communicate over a Wireless Sensor Network (WSN) to guarantee the child's safety.

The system operates in three modes:

| Mode | Description |
|---|---|
| **Pairing** | Associates a child bracelet with its parent bracelet via a shared pairing key. |
| **Operation** | The parent bracelet continuously reads status/location messages from the child. |
| **Alert** | If the child is **FALLING**, a `FALL` alarm is sent with the child's location. If no message is received for one minute, a `MISSING` alarm is sent with the last known position. |

---

## 📡 Message data structure

Wireless messages (`msggtype`) are kept minimal to fit the tight memory budget of MicaZ motes:

| Field | Meaning |
|---|---|
| `type` | Message type (status / alarm) |
| `key[20]` | Pairing key |
| `source` | Source node id |
| `dest` | Destination node id |
| `status` | Status of the child |
| `x`, `y` | Last known coordinates of the child |

Example alarm output:

```
DEBUG (4): ! - FALLING - ! @58,80
DEBUG (2): ! - MISSING - ! --------- last found @46,94
```

The alarms are structured so the parent always knows the **last known location** of the child.

---

## 🏗️ Architecture & code

Written in **nesC** for the TinyOS event-driven model.

```
src/
├── SmartBracelet.h          # Shared message struct (msggtype) & constants
├── SmartBraceletC.nc        # Core bracelet node logic (pairing / operation / alert)
├── SmartBraceletAppC.nc     # Application wiring (components configuration)
├── Makefile                 # TinyOS build for the micaz platform
├── RunSimulation.py         # TOSSIM simulation driver (Python)
├── TOSSIM.py                # Python bindings to the TOSSIM radio simulator
├── topology.txt             # Network topology (node links & signal strengths)
├── meyer-heavy.txt          # Noise/loss model for the radio channel
└── Node-RED flow.txt        # Node-RED flow for visualizing alarms
```

Key engineering aspects:

- **Event-driven concurrency** — split-phase radio operations typical of TinyOS/nesC.
- **Resource awareness** — compact fixed-size message structs for 8-bit motes.
- **Radio simulation** — realistic link/noise behaviour via the *meyer-heavy* loss model.

---

## 🧪 Simulation

The project can be fully simulated without physical hardware using **TOSSIM** + **Node-RED**:

1. `RunSimulation.py` boots the TOSSIM simulator, loading `topology.txt` and `meyer-heavy.txt`.
2. Virtual serial ports are created with **socat** (e.g. `/dev/pts/2` ↔ `/dev/pts/3`).
3. A **Node-RED** flow reads the serial stream and renders the alarm messages for debugging.

A simulation log is included in `src/` for reference.

---

## 📄 Report

A short project report (`report.pdf`) documents the design, the message/alarm structures and the simulation setup.

---

## 📄 License

Academic project — released for portfolio purposes.
