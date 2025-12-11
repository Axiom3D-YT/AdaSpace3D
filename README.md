# AdaSpace3D 🚀

**The definitive firmware upgrade for your DIY SpaceMouse.**

[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-nc-sa/4.0/) ![Platform](https://img.shields.io/badge/platform-RP2040-red.svg) ![Status](https://img.shields.io/badge/status-Stable-green.svg)

**AdaSpace3D** is a drop-in firmware replacement for any DIY SpaceMouse using an **RP2040** and **TLx493D** sensor.

It fixes the biggest issue with previous DIY firmwares: **It replaces glitchy mouse/keyboard emulation with Native 3DConnexion Driver Support.**

Your DIY build will now be recognized by Windows/macOS as a genuine **SpaceMouse Pro Wireless**. No more glitchy shortcuts, no more keybinding headaches—just buttery smooth 5DOF navigation in 3D software (Fusion360, OrcaSlicer, Blender, etc.).

---

## ✨ Features

* **Native Driver Support:** Emulates the official 3DConnexion USB protocol. Works out-of-the-box with standard drivers.
* **Unified Firmware:** One file for everyone. The code **automatically detects** if your sensor is connected via **Stemma QT (Cable)** or **Soldered Headers**.
* **Reactive Lighting:**
    * **Dual Drive:** Supports both Addressable (NeoPixel) and Standard LEDs simultaneously.
    * **Smart Feedback:** LED glows dim when idle and brightens as you move the knob.
* **5DOF Navigation:** Smooth X, Y, Z translation + Pitch and Roll.
* **Bulletproof Flasher:** Includes a custom "One-Click" build script that handles libraries, compilers, and upload automatically.

> [!IMPORTANT]
> **Hardware Limitation:** Spin/Twist rotation is **not functional** due to the physics of the current sensor setup. For best results, configure your 3DConnexion driver to use either **Pan/Zoom** or **Rotation** mode—not both simultaneously. Use the programmable buttons to toggle between these modes on-the-fly.

---

## 🛠️ Hardware Support

This firmware is designed for the **Adafruit QT Py RP2040**, but will possibly work on other RP2040 boards with possible minor pin changes.

| Component | Pin (Default) | Notes |
| :--- | :--- | :--- |
| **Sensor** | **TLx493D** | Auto-detects on `Wire1` (Stemma) or `Wire` (Solder). |
| **Buttons** | A0, A1, A2, A3 | Mapped to HID Buttons 13, 14, 15, 16. |
| **NeoPixel** | GPIO 4 | Addressable RGB Strip (WS2812). |
| **Simple LED** | GPIO 3 | Standard 2-leg LED (PWM brightness). |

> **Note:** The firmware drives **GPIO 3 and GPIO 4 simultaneously**. You can connect your LED to either pin depending on your build, and change the behavior in `UserConfig.h`.

---
## 🚀 Quick Start (Windows)

We have included a "One-Click" tool so you don't need to install Arduino IDE or mess with libraries manually.

1.  **Download** this repository as a ZIP and extract it.
2.  Open `UserConfig.h` in any text editor to customize your settings (Sensitivity, LED Colors, etc.).
3.  **Plug in** your RP2040 device.
4.  **Enter Bootloader Mode:**
    * Hold down the **BOOT** button.
    * Press and release the **RESET** button.
    * Release the **BOOT** button.
    * *A new drive named `RPI-RP2` should appear on your computer.*
5.  Double-click **`FLASH.bat`**.

The script will automatically:
* Download the compiler (Arduino CLI).
* Install the RP2040 Core and Infineon Sensor libraries.
* Compile the firmware with the correct "SpaceMouse" USB ID.
* Detect the `RPI-RP2` drive and flash it instantly.

> [!TIP]
> For manual builds without the script (Linux/macOS/advanced users), see [ADVANCED-INSTRUCTIONS.md](ADVANCED-INSTRUCTIONS.md).

---

## ⚙️ Configuration (`UserConfig.h`)

You can tweak the feel of your SpaceMouse without touching the complex code.

```cpp
// --- SENSOR SETTINGS ---
// Increase if movement feels too slow. Default: 150.0
#define CONFIG_TRANS_SCALE     150.0  

// --- LED CONFIGURATION ---
// 0 = Static (Solid Color)
// 1 = Breathing (Pulse)
// 2 = Reactive (Dim resting color, Brightens on movement)
#define LED_MODE            2

// Choose your preferred color (RGB 0-255)
#define LED_COLOR_R         0
#define LED_COLOR_G         255
#define LED_COLOR_B         255
```




## 🤝 Credits & Acknowledgments

This project stands on the shoulders of giants in the DIY community.

* **Salim Benbouzid:** For setting the seed and inspiring the DIY SpaceMouse revolution.
* **AndunHH:** For his excellent work on the software side, proving the concept of using the Infineon sensor for navigation.
* **LeoSpaceLab:** For refining the mechanical design that brought us all here.

**Developed with ❤️ for the maker community by Axiom3d (aka Uzzo)**




This work is licensed under a **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0)**.

You are free to:
* **Share:** Copy and redistribute the material in any medium or format.
* **Adapt:** Remix, transform, and build upon the material.

Under the following terms:
* **Attribution:** You must give appropriate credit to the original authors.
* **NonCommercial:** You may not use the material for commercial purposes.
* **ShareAlike:** If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
