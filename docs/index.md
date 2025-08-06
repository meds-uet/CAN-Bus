# ***CAN BUS IP CORE***
## ***What is CAN Protocol?***

CAN (Controller Area Network) is a serial communication protocol originally developed by Bosch in 1986 for use in automotive systems, but now widely used in industrial, medical, and embedded systems.

## ***OVERVIEW***

- **Project** : CAN BUS IP CORE
- **Target** : SoC Integration
- **Protocol Supported** :  CAN 2.0A / 2.0B
- **Language** : SystemVerilog

The CAN Bus IP Core is designed to transmit and receive CAN frames with full support for arbitration, error handling, bit stuffing, and CRC checking. It is intended for integration into FPGA/ASIC-based SoC designs.

# ***Top Level Diagram***
 
<p align="center">
  <img src="https://github.com/meds-uet/CAN-Bus/blob/main/docs/images_design/top%20module.jpg" width="400" height="500">
</p>

## ***Sub Modules***

Each submodule below contributes to a specific stage of CAN frame transmission and reception, forming the core logic of the IP.
1. ***can_tranmitter***
2. ***can_receiver***
3. ***can_tx_priority***
4. ***can_filtering***
5. ***can_arbitration***
6. ***can_bitstuff***
7. ***can_crc15_gen***
8. ***can_error_detection***
9. ***can_timing***


## CAN Transmitter Module (`can_transmitter`)

###  Description
The `can_transmitter` module handles the bit-level serialization of a CAN frame according to the CAN 2.0A/B protocol. It implements a finite state machine (FSM) that transitions through each field of the frame — from Start of Frame (SOF) to Interframe Space (IFS) — and generates a single `tx_bit` at each sample point on the CAN bus.

This module supports both **standard (11-bit ID)** and **extended (29-bit ID)** frames and includes handling for **remote transmission requests (RTR)**, **data fields**, **CRC transmission**, and **frame delimiters**.

---

###  Inputs

| Signal       | Width  | Description                                               |
|--------------|--------|-----------------------------------------------------------|
| `clk`        | 1      | System clock                                              |
| `rst_n`      | 1      | Asynchronous active-low reset                             |
| `tx_enable`  | 1      | Starts frame transmission from IDLE                       |
| `tx_point`   | 1      | Sample point at which bit should be output                |
| `initiate`   | 1      | Resets FSM to IDLE state (used for re-init or abort)      |
| `tx_id_std`  | 11     | Standard 11-bit identifier                                |
| `tx_id_ext`  | 18     | Remaining bits for extended ID (to form 29-bit ID)        |
| `tx_ide`     | 1      | Identifier Extension bit (0 = Standard, 1 = Extended)     |
| `tx_rtr`     | 1      | Remote Transmission Request bit                           |
| `tx_dlc`     | 4      | Data Length Code (number of data bytes: 0 to 8)           |
| `tx_data`    | 8×8    | Data payload (up to 8 bytes)                              |
| `tx_crc`     | 15     | Precomputed CRC for frame contents                        |

---

###  Outputs

| Signal      | Width | Description                                      |
|-------------|--------|--------------------------------------------------|
| `tx_bit`    | 1     | Output serialized CAN bit at `tx_point`          |
| `tx_done`   | 1     | Set high for one cycle after frame transmission  |

---

###  FSM States Summary

| State               | Description                                          |
|---------------------|------------------------------------------------------|
| `STATE_IDLE`        | Waits for `tx_enable`                                |
| `STATE_SOF`         | Transmits Start of Frame (SOF = 0)                   |
| `STATE_ID_STD`      | Sends 11-bit standard ID                             |
| `STATE_BIT_RTR_1`   | Sends RTR bit for standard frame                     |
| `STATE_BIT_IDE`     | Sends IDE bit to distinguish standard/extended frame |
| `STATE_ID_EXT`      | Sends remaining 18 bits of extended ID               |
| `STATE_BIT_RTR_2`   | Sends RTR bit for extended frame                     |
| `STATE_BIT_R_1`     | Sends reserved bit (1st)                             |
| `STATE_BIT_R_0`     | Sends reserved bit (2nd)                             |
| `STATE_DLC`         | Sends 4-bit Data Length Code                         |
| `STATE_DATA`        | Sends the data bytes                                 |
| `STATE_CRC`         | Sends 15-bit CRC                                     |
| `STATE_CRC_DELIMIT` | Sends CRC delimiter (1)                              |
| `STATE_ACK`         | Sends recessive bit for ACK                          |
| `STATE_ACK_DELIMIT` | Sends ACK delimiter                                  |
| `STATE_EOF`         | Sends 7-bit End Of Frame                             |
| `STATE_IFS`         | Sends 3-bit Inter-frame space and sets `tx_done`     |

---

###  Design Behavior

- Frame transmission starts when `tx_enable` is asserted and `tx_point` is high.
- Bit and byte counters track field progress in each state.
- CRC must be calculated externally and provided via `tx_crc`.
- FSM resets on `rst_n` or `initiate`.

---

###  Design Notes

- Compliant with CAN 2.0A and 2.0B.
- `tx_point` ensures correct synchronization with CAN timing.
- Suitable for use in a complete CAN controller with separate arbitration/error FSMs.

---

### Data Path and Controller

Here is the data serialization data path:

<p align="center">
  <img src="https://github.com/meds-uet/CAN-Bus/tree/main/docs/images_design" width="400" height="500">
</p>

Here is the FSM for transmitter:

<p align="center">
  <img src="https://github.com/meds-uet/CAN-Bus/blob/main/docs/images_design/Transmitter%20FSM.png" width="400" height="500">
</p>


## CAN Receiver Module (`can_receiver`)

###  Description
The `can_receiver` module receives and decodes a CAN frame bit-by-bit at each sampling point (`rx_point`). It reconstructs the full frame according to the CAN 2.0A/B protocol, supporting both **standard (11-bit ID)** and **extended (29-bit ID)** formats. It outputs all parsed fields of the CAN frame, including identifiers, control bits, data, and CRC, and signals completion with `rx_done`.

---

###  Inputs

| Signal       | Width | Description                                               |
|--------------|--------|-----------------------------------------------------------|
| `clk`        | 1     | System clock                                              |
| `rst_n`      | 1     | Asynchronous active-low reset                             |
| `rx_point`   | 1     | Sample point trigger (bit sampling sync pulse)            |
| `rx_bit`     | 1     | Serial bit from CAN bus to be decoded                     |

---

###  Outputs

| Signal       | Width   | Description                                            |
|--------------|---------|--------------------------------------------------------|
| `rx_id_std`  | 11      | Standard 11-bit identifier                             |
| `rx_id_ext`  | 18      | Remaining bits for extended identifier (for 29-bit ID) |
| `rx_ide`     | 1       | Identifier Extension bit (0 = standard, 1 = extended)  |
| `rx_rtr`     | 1       | Remote Transmission Request bit                        |
| `rx_dlc`     | 4       | Data Length Code (0–8)                                 |
| `rx_data`    | 8×8     | Reconstructed data bytes                               |
| `rx_crc`     | 15      | Received CRC bits (no validation in this module)       |
| `rx_done`    | 1       | Goes high for one cycle after successful frame receive |

---

###  FSM States Summary

| State               | Description                                              |
|---------------------|----------------------------------------------------------|
| `STATE_IDLE`        | Wait for SOF (Start of Frame)                            |
| `STATE_ID_STD`      | Receive 11-bit standard ID                               |
| `STATE_BIT_RTR_1`   | Receive RTR bit (for standard ID)                        |
| `STATE_BIT_IDE`     | Receive IDE bit                                          |
| `STATE_ID_EXT`      | Receive 18-bit extended ID if `rx_ide` = 1               |
| `STATE_BIT_RTR_2`   | Receive RTR bit (for extended ID)                        |
| `STATE_BIT_R_1`     | Reserved bit (ignored)                                   |
| `STATE_BIT_R_0`     | Reserved bit (ignored)                                   |
| `STATE_DLC`         | Receive 4-bit data length code                           |
| `STATE_DATA`        | Receive actual data bytes (up to 8)                      |
| `STATE_CRC`         | Receive 15-bit CRC                                       |
| `STATE_CRC_DELIMIT` | Receive CRC delimiter (ignored)                          |
| `STATE_ACK`         | ACK slot (ignored in this module)                        |
| `STATE_ACK_DELIMIT` | ACK delimiter (ignored)                                  |
| `STATE_EOF`         | End of Frame (7 bits of recessive level)                |
| `STATE_IFS`         | Inter-frame space (3 bits)                               |

---

###  Design Behavior

- Each `rx_bit` is shifted into internal registers when `rx_point` is high.
- Frame fields (IDs, DLC, data, CRC) are parsed and saved.
- Data bytes are reassembled using an internal shift register.
- `rx_done` indicates completion of a valid frame capture.
- No CRC or ACK validation is performed here (can be added externally).

---

###  Key Internal Registers

| Register           | Purpose                                     |
|--------------------|---------------------------------------------|
| `rx_id_std_ff`     | Stores standard 11-bit ID                   |
| `rx_id_ext_ff`     | Stores 18-bit extension for extended ID     |
| `rx_data_array`    | Holds 8 bytes of received data              |
| `rx_crc_ff`        | Captures 15-bit CRC from the frame          |
| `rx_done_ff`       | Indicates reception complete                |
| `data_byte_ff`     | Internal shift register for byte assembly   |

---

### FSM Diagram 

Here is the FSM for receiver:

<p align="center">
  <img src="https://github.com/meds-uet/CAN-Bus/blob/main/docs/images_design/Receiver%20FSM.png" width="400" height="500">
</p>

## `can_bitstuff` Module Documentation

### Overview

The `can_bitstuff` module implements bit stuffing and de-stuffing logic for a CAN (Controller Area Network) protocol transmitter and receiver. Bit stuffing is used to ensure synchronization and avoid long runs of identical bits, which could cause the receiver to lose track of bit timing.

This module supports both insertion (for transmission) and removal (for reception) of stuffed bits.

### Interface

#### Inputs

| Signal         | Width | Description                                                                 |
|----------------|-------|-----------------------------------------------------------------------------|
| `clk`          | 1     | System clock                                                                |
| `rst_n`        | 1     | Active-low synchronous reset                                                |
| `bit_in`       | 1     | Incoming bit to be processed (from TX or RX)                                |
| `sample_point` | 1     | Indicates when to sample and count bits                                     |
| `insert_mode`  | 1     | Mode select: `1` for stuffing (TX), `0` for de-stuffing (RX)                |

#### Outputs

| Signal             | Width | Description                                                                            |
|--------------------|-------|----------------------------------------------------------------------------------------|
| `bit_out`          | 1     | Output bit after applying bit stuffing or de-stuffing logic                            |
| `insert_or_remove` | 1     | Indicates whether a bit stuffing (in insert mode) or bit skipping (in receive mode) is triggered |

### Functionality

#### Bit Stuffing (Transmit Mode)

In insert mode (`insert_mode = 1`):

- The module tracks the number of consecutive identical bits using `same_count`.
- If five consecutive identical bits are detected (`same_count == 5`), the module outputs the complement of the last bit as the sixth bit (stuffed bit).
- The `insert_or_remove` signal is asserted to indicate that stuffing occurred.

#### Bit De-stuffing (Receive Mode)

In de-stuffing mode (`insert_mode = 0`):

- The module tracks the same pattern of five consecutive identical bits.
- On the sixth same bit (the stuffed bit), `insert_or_remove` is asserted to indicate the receiver should ignore this bit.
- The actual skipping of this bit should be handled by receiver logic outside this module.

### Internal Logic

- `same_count`: A 3-bit counter that increments when `bit_in` matches the previous bit. Reset to 1 on mismatch.
- `prev_bit`: Holds the previous sampled bit to compare with the current input.
- Bit stuffing/de-stuffing is evaluated only at `sample_point`.

## Bit Stuffing Data Path

<p align="center">
  <img src="https://github.com/meds-uet/CAN-Bus/blob/main/docs/images_design/Bit_stuffing.png" width="400" height="500">
</p>

## Bit Destuffing Data Path

<p align="center">
  <img src="https://github.com/meds-uet/CAN-Bus/blob/main/docs/images_design/de_stuffing.png" width="400" height="500">
</p>

## CAN Arbitration Module

### Overview

The `can_arbitration` module is responsible for detecting arbitration loss in a Controller Area Network (CAN) protocol. Arbitration occurs during the ID field of a CAN frame when multiple nodes may attempt to transmit simultaneously. Arbitration loss is detected when a transmitter sends a recessive bit (`1`) but sees a dominant bit (`0`) on the bus, indicating another node with a higher priority is transmitting.

---

### Functionality

This module monitors the transmitted (`tx_bit`) and received (`rx_bit`) bits during the arbitration phase. If the node transmits a recessive bit but receives a dominant bit at a `sample_point` during the active arbitration phase, the module flags this as an arbitration loss.

---

### Port Description

| Signal Name        | Direction | Width | Description                                                                 |
|--------------------|-----------|--------|-----------------------------------------------------------------------------|
| `clk`              | Input     | 1      | System clock                                                                |
| `rst_n`            | Input     | 1      | Active-low synchronous reset                                                |
| `tx_bit`           | Input     | 1      | Transmitted bit (0 = dominant, 1 = recessive)                               |
| `rx_bit`           | Input     | 1      | Received bit from CAN bus                                                   |
| `sample_point`     | Input     | 1      | Indicates a valid sampling point for comparison                             |
| `arbitration_active` | Input   | 1      | High during the arbitration field (usually during the ID field)            |
| `arbitration_lost` | Output    | 1      | High when arbitration loss is detected                                     |

---

### Internal Logic

- A flip-flop `lost_ff` holds the arbitration loss state.
- At each `sample_point`, if:
  - `arbitration_active` is asserted,
  - the node transmits `1` (recessive), and
  - it receives `0` (dominant),
  then `lost_ff` is set to `1`.
- Once arbitration ends (`arbitration_active` = 0), the loss flag is cleared.

---

### Usage

This module is used in CAN transmitters to detect if they have lost arbitration and should back off from transmission to allow a higher-priority frame to continue uninterrupted.

---

### Arbitration Design Diagram

<p align="center">
  <img src="https://github.com/meds-uet/CAN-Bus/blob/main/docs/images_design/Arbitration.jpg" width="400" height="500">
</p>
