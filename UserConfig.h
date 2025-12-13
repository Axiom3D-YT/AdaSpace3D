#ifndef USER_CONFIG_H
#define USER_CONFIG_H

// ===================================================================================
//   ADA SPACE 3D - USER CONFIGURATION
//   Tweak these settings to customize the feel of your SpaceMouse
// ===================================================================================

// -----------------------------------------------------------------------------------
//   1. VISUAL SETTINGS (LEDs)
// -----------------------------------------------------------------------------------

// The firmware drives BOTH outputs simultaneously. Connect whichever you like.
// - Addressable Strip: GPIO 4 (NeoPixel)
// - Simple LED:        GPIO 3 (Standard 2-leg LED)

// Choose your Lighting Mode:
// 0 = Static (Solid Color)
// 1 = Breathing (Gently Fades In/Out)
// 2 = Reactive (Dims when idle, Brightens on movement)
#define LED_MODE            2

// --- LED Hardware Setup ---
#define NUM_ADDRESSABLE_LEDS 3      // Number of LEDs in your strip (GPIO 4)
#define LED_BRIGHTNESS       128    // Global brightness (0 to 255)

// --- Color Configuration ---
// Set your preferred color (0-255).
// This color is used for Static, Breathing, and Reactive modes.
// Note: Reactive mode will scale the brightness of this color.

// Current Setting: Green
#define LED_COLOR_R         0
#define LED_COLOR_G         255
#define LED_COLOR_B         0

/* Common Colors:
   Red:    R=255, G=0,   B=0
   Green:  R=0,   G=255, B=0
   Blue:   R=0,   G=0,   B=255
   Cyan:   R=0,   G=255, B=255
   Purple: R=255, G=0,   B=255
   Orange: R=255, G=100, B=0
   White:  R=255, G=255, B=255
*/


// -----------------------------------------------------------------------------------
//   2. SENSOR SENSITIVITY
// -----------------------------------------------------------------------------------

// Translation Sensitivity (Moving X/Y)
// Higher = Faster movement. Default: 100
#define CONFIG_TRANS_SCALE     100

// Zoom Sensitivity (Push/Pull Z)
// Default: 50
#define CONFIG_ZOOM_SCALE      50

// Rotation Sensitivity (Tilt/Roll)
// Default: 40
#define CONFIG_ROT_SCALE       40

// Deadzones
// Minimum movement required to register. Keep small.
#define CONFIG_DEADZONE        1.0
#define CONFIG_ZOOM_DEADZONE   2.5


// -----------------------------------------------------------------------------------
//   3. ADVANCED / HARDWARE
//   ⚠️ Only change these if you have modified the hardware or pinout
// -----------------------------------------------------------------------------------

// Button Pins (HID Buttons 13-16)
#define BUTTON1_PIN         A0
#define BUTTON2_PIN         A1
#define BUTTON3_PIN         A2
#define BUTTON4_PIN         A3

// Sensor Power Pin (Used for resetting the sensor)
#define MAG_POWER_PIN       15

// USB Identification (SpaceMouse Pro Wireless)
// VID/PID used to mimic official hardware.
#define USB_VID             0x256f
#define USB_PID             0xc631

// Debug Mode
// Set to true to view raw sensor data in Serial Monitor.
// ⚠️ MUST be false for normal use (Mouse will not work in Debug Mode)
#define DEBUG_MODE          false

#endif // USER_CONFIG_H
