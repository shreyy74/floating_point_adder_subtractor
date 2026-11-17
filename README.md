# 32-bit Floating Point Adder and Subtractor

## Project Overview

This project implements a 32-bit IEEE 754 floating-point adder and subtractor using SystemVerilog.

The design supports both addition and subtraction through a common arithmetic unit. It consists of a combinational floating-point arithmetic core and a clocked wrapper module for synchronous operation.

## Features

- 32-bit IEEE 754 single-precision input and output format.
- Floating-point addition and subtraction.
- Shared arithmetic hardware for both operations.
- Exponent alignment and significand arithmetic.
- Normalization and rounding logic.
- Handling of special cases including NaN and infinity.
- Clocked interface with reset and valid signals.

## Architecture

The design consists of two main modules:

### 1. `fp_addsub_core`

The combinational arithmetic unit responsible for:

- Selecting addition or subtraction.
- Aligning operand exponents.
- Performing significand addition or subtraction.
- Normalizing the result.
- Applying rounding.
- Handling special floating-point values.

### 2. `fp_addsub`

The synchronous wrapper module responsible for:

- Clock synchronization.
- Reset handling.
- Input validity control.
- Registering the arithmetic result.
- Generating the output valid signal.

## Module Interface

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 bit | Clock |
| `reset` | Input | 1 bit | Synchronous reset |
| `in_valid` | Input | 1 bit | Input validity |
| `sub` | Input | 1 bit | Operation select |
| `a` | Input | 32 bits | First operand |
| `b` | Input | 32 bits | Second operand |
| `out_valid` | Output | 1 bit | Output validity |
| `result` | Output | 32 bits | Floating-point result |

### Operation Selection

- `sub = 0`: Floating-point addition (A + B)
- `sub = 1`: Floating-point subtraction (A - B)

## Repository Structure

```text
floating_point_adder_subtractor/
│
├── FP_ADDSUB/
│   └── rtl.sv
│
├── ci.yaml
│
└── README.md
```

## Technology Stack

- **HDL:** SystemVerilog
- **Number Format:** IEEE 754 Single Precision (32-bit)
- **Design:** Combinational arithmetic core with synchronous wrapper
- **Version Control:** Git and GitHub

## Integration
