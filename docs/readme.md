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
  <img src="https://github.com/meds-uet/CAN-Bus/blob/main/docs/top%20module.jpg" width="400" height="500">
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




