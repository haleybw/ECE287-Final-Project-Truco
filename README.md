# ECE 287 PROJECT------ Truco Card Game on Intel FPGA
 # Bruin Haley
 # IAN Kmiliauskis

 ##### Final Version 12/13/2024

# Truco Card Game on FPGA with VGA and 7-Segment Display


## Overview

This project implements a **Truco** card game on an FPGA, featuring the following components:

1. **VGA Driver** (`vga_driver.v`): Responsible for generating signals for a 640x480 VGA display.
2. **On-Board 7-Segment Display Driver** (`fivedigit_decimal.v`): Converts the game data (scores, etc.) into signals for the FPGA's 7-segment displays.
3. **Truco Game Logic** (`project.v`): Implements the rules of the Truco card game, handles scoring, and interacts with both the VGA driver and 7-segment display driver.

---

## Modules

### 1. VGA Driver (`vga_driver.v`)

The **VGA Driver** module generates the necessary horizontal and vertical sync signals for a 640x480 VGA display. It also tracks pixel locations to control the rendering process accurately.

#### Parameters:
- **h_active** = 640 (horizontal active pixels)
- **h_front_porch** = 16 (horizontal front porch)
- **h_sync_pulse** = 96 (horizontal sync pulse)
- **h_back_porch** = 48 (horizontal back porch)
- **h_total_pixels** = 800 (total horizontal pixels)
- **v_active** = 480 (vertical active lines)
- **v_front_porch** = 10 (vertical front porch)
- **v_sync_pulse** = 2 (vertical sync pulse)
- **v_back_porch** = 33 (vertical back porch)
- **v_total_lines** = 525 (total vertical lines)

#### Inputs:
- `clk`: System clock (50 MHz)
- `rst`: Reset signal (active high)

#### Outputs:
- `hsync`: Horizontal sync signal
- `vsync`: Vertical sync signal
- `h_count`: Horizontal pixel count (0 to 799)
- `v_count`: Vertical line count (0 to 524)

### 2. On-Board 7-Segment Display Driver (`fivedigit_decimal.v`)
The **7-Segment Display Driver** converts a 16-bit signed integer (game data, such as scores) into the proper signals for a 7-segment display, including handling negative numbers via two's complement representation.

#### Inputs:
- `input_value`: 16-bit signed integer (the value to be displayed)
- `rst`: Reset signal (active high)

#### Outputs:
- `neg_sign_2_hex`: Negative sign display for the 7-segment display
- `d_4_sign_2_hex`, `d_3_sign_2_hex`, `d_2_sign_2_hex`, `d_1_sign_2_hex`, `d_0_sign_2_hex`: Displays for the five digits (each digit is a 7-segment signal)

### 3. Truco Game Logic (`project.v`)
The **Truco Game Logic** module handles the rules of the Truco card game, managing the rounds, scorekeeping, and player actions. It interfaces with the VGA driver to render graphics and the 7-segment display driver to display the score.

#### Inputs:
- `clk`: System clock (50 MHz)
- `rst`: Reset signal (active high)
- `player_inputs`: Simulated player inputs (e.g., card plays, betting actions)

#### Outputs:
- `game_state`: The current state of the game (e.g., round number, player status)
- `score`: Player scores to be displayed
- `vga_data`: Data for VGA rendering
- `on_board_data`: Data for 7-segment display rendering



## How to Use

### Step 1: Set Up the FPGA Project
1. Add all three modules (`vga_driver.v`, `fivedigit_decimal.v`, and `project.v`) to your FPGA project.
2. Connect the modules to the system clock (`clk`) and reset signal (`rst`).

### Step 2: Display Setup
- **VGA Display**: Connect the `hsync` and `vsync` signals to the VGA connector. Use `h_count` and `v_count` to manage pixel locations for rendering.
- **7-Segment Display**: Connect the `neg_sign_2_hex` and `d_4_sign_2_hex` to the 7-segment display pins.

### Step 3: Running the Game
- Implement player input signals that trigger game actions (e.g., card plays, betting, score updates).
- The VGA display will render the game state, and the 7-segment display will show the current score.

---

## Conclusion

This project integrates the **Truco** card game logic with FPGA-based VGA and 7-segment displays. The **VGA Driver** controls the display timing and rendering, while the **On-Board 7-Segment Display Driver** displays game data. The **Truco Game Logic** module implements the core game mechanics, controlling the state of the game and interfacing with the display modules.

---