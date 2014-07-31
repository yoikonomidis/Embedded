Overview
========

xCORE-Analog support library
----------------------------

The xCORE-Analog devices include an analog tile with various peripherals including ADC, RTC, WDT and sleep mode controller. This library provides an API to control these features without the need for detailed knowledge of the operation of these functions.


ADC library features
++++++++++++++++++++

- Individual ADC channel enable/disable
- Individual or packetised ADC conversion trigger and conversion result reading
- Choice of 8,16 or 32 bit data packing (converter is 12b resolution)
- ADC sample trigger control
 

WDT library features
++++++++++++++++++++

- Enable/Disable watchdog
- Timeout setting in milliseconds (up to one minute)
- Kick function to reset timer

Sleep library features
++++++++++++++++++++++

- Sleep mode and wake control functions
- RTC (Real Time Clock) configuration and control. Converts time and wake times to milliseconds.
- Deep sleep memory (128Byte) access and validation for state storage during sleep

Resource requirements for xCORE-Analog support library
++++++++++++++++++++++++++++++++++++++++++++++++++++++

Using the entire API, the following resource requirements is expected.

+------------------+----------------------------------------+
| Resource         | Usage                                  |
+==================+========================================+
| Stack            | 304 bytes                              |
+------------------+----------------------------------------+
| Program          | 572 bytes                              |
+------------------+----------------------------------------+

+---------------+-------+
| Resource      | Usage |
+===============+=======+
| 32b port      |   1b  |
+---------------+-------+
| Channels      |   1   |
+---------------+-------+
| Timers        |   0   |
+---------------+-------+
| Clocks        |   0   |
+---------------+-------+
| Logical Cores |   0   |
+---------------+-------+

