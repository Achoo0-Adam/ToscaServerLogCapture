# ToscaServerLogCapture
PowerShell script to capture **Tosca Server** and **Support Logs** for troubleshooting.

Author: **Adam Lucey (a.lucey@tricentis.com)**
Version: 4.7
Last Updated: 2026-02-06

---

## Overview

This PowerShell script captures Tosca Server logs and optional support logs for troubleshooting or support purposes.
It collects files modified in a selected date range, organizes them by service, and creates a timestamped ZIP bundle.

Key points:
- Primary logs: %PROGRAMDATA%\TRICENTIS\ToscaServer\Logs (server logs).
- Optional support logs: %PROGRAMDATA%\TRICENTIS\Logs.
- If default server path is missing, the script prompts for a custom log directory.
- Supports Windows PowerShell 5.1+ (untested on older versions).
- ZIP filename format: ToscaLogCapture_YYYYMMDD_HHmm.zip (no seconds).

---

## Features

- Detects **Server and Support logs** automatically.
- Allows **date range** selection:
  - Today only
  - Today + Yesterday
  - Custom (supports yyyy/MM/dd or yyyy/MM/dd HH:mm)
- Lets user select services to include:
  - Server only
  - Server + Support
  - Individual service folders
- Creates **structured ZIP** with logs organized by service type and name.
- Displays **summary of files collected**.
- Waits for *ENTER** before closing, so the user can review results.

---

## Quick Start

1. Open PowerShell as Administrator
   Press Windows + S, type PowerShell, right-click, and select Run as Administrator.

2. Navigate to the script folder
   Replace ```C:\Path\To\Script``` with the folder where ```ToscaLogCapture.ps1``` is saved, then run:

   ```powershell.exe -NoExit -ExecutionPolicy Bypass -File "ToscaLogCapture.ps1"```

   - NoExit keeps the window open after the script completes.
   - ExecutionPolicy Bypass allows running the script regardless of system restrictions.

3. Follow the prompts

   Step A – Confirm or enter server log path
   Default path: ```%PROGRAMDATA%\TRICENTIS\ToscaServer\Logs```
   If not found, enter your custom installation path, for example:

   ```D:\ProgramData\TRICENTIS\ToscaServer\Logs ```

   Step B – Select date range
   Options:

   1) Today only
   2) Today + Yesterday
   3) Custom (enter start/end dates)

   For custom dates, use format: yyyy/MM/dd or yyyy/MM/dd HH:mm.
   Example:

   Start date: 2026/02/05
   End date:   2026/02/06 15:30

   Step C – Select services to include
   Options example:

   1) All Server services
   2) Server + Support logs
   3) Service1
   4) Service2

   Enter a single number or comma-separated list, for example:

   2          → server + support
   3,4        → Service1 and Service2 only

4. Review output
   The ZIP file is saved in:

   ```C:\Temp\ToscaLogCapture_YYYYMMDD_HHmm.zip```

   Example filename: ToscaLogCapture_20260206_1513.zip

5. Exit
   
  <img width="407" height="177" alt="image" src="https://github.com/user-attachments/assets/519f2697-0324-4d2e-b00b-3a33209a9e5d" />



---

## Example Output

<img width="472" height="1047" alt="image" src="https://github.com/user-attachments/assets/902738ba-8ce9-48be-91d4-e451090df55f" />


---

Notes / Tips

- Do not commit real logs to GitHub — they may contain sensitive information.
- Temporary files are stored in C:\Temp\LogCapture during execution and removed automatically after creating the ZIP.
- Test on a small date range first to verify the correct logs are captured.
- Adjust $tempRoot and $zipPath variables in the script to save files elsewhere.
- I would advise changing the ```%PROGRAMDATA%``` env variable so that your not asked for the directory everytime. 

---

Change Log

Version 4.7 (2026-02-06):
- Removed seconds from ZIP filename
- Added "Press ENTER to close" so that you can confirm the files gathered and any errors in the running of the script
- Improved prompts and support/server selection

Version 4.6 (2025-11-28):
- Initial GitHub-friendly version with date range and service selection

---

License

Provided as-is for internal use and support purposes.
