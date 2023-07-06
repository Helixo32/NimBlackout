# NimBlackout

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/yourusername/blackout-nim/blob/main/LICENSE)
[![Nim Version](https://img.shields.io/badge/nim-1.6.8-orange.svg)](https://nim-lang.org/)

> **Note**: This project is for educational purposes only. The use of this code for any malicious activity is strictly prohibited. I am not responsible for any misuse of this software.

NimBlackout is an adaptation of the [@Blackout](https://github.com/ZeroMemoryEx/Blackout) project originally developed in C++ by [@ZeroMemoryEx](https://github.com/ZeroMemoryEx), which consists of removing AV/EDRs using the gmer (BYOVD) driver.

The main reason for this project was to understand how BYOVD attacks work, and then to provide a valid PoC developed in Nim.

All credit must goes to the original author [@ZeroMemoryEx](https://github.com/ZeroMemoryEx).


# Usage
- Put Blackout.sys driver into current directory
- Launch NimBlackout
  ```
  NimBlackout.exe <process name>
  ```

  In order to prevent restarting process (like MsMpEng.exe), keep the program running.
