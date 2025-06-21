# Windows-Quick-Boost ⚡

> **One-click cleaner & tuner for Windows 10 / Windows 11**
> Frees disk space, trims background bloat, tweaks services, and shows a simple “before vs after” report.

---

## ⚠️ Disclaimer

Before running **Windows-Quick-Boost**, please create a **System Restore point**:

1. Press **Win + R**, type `rstrui` and press **Enter**.
2. Click **Create**.
3. Name it **Pre-Windows-Quick-Boost** and click **Create** again.
4. Wait for confirmation—then you’re safe to continue.

---

## ✅ Quick Start Guide

Choose one of two simple ways to run the script:

### Option 1 — Double-click & Run as Administrator

1. **Download** `Windows-Quick-Boost.ps1` from this repo.
2. **Copy** it to any folder (e.g. **Downloads** or **Desktop**).
3. **Right-click** the file → **Run with PowerShell** → **Run as Administrator**.
4. Watch the progress bar; read your final report.
5. Enjoy your faster, cleaner PC!

### Option 2 — One-line PowerShell (temporary policy bypass)

1. **Download** and **copy** `Windows-Quick-Boost.ps1` to a folder (e.g. `C:\Scripts`).
2. **Open PowerShell as Administrator**:

   * Start menu → type **powershell** → right-click **Windows PowerShell** → **Run as Administrator**.
3. **Paste & run**:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File \"C:\Scripts\Windows-Quick-Boost.ps1\"
   ```

The script runs with a bypassed policy—your default policy remains unchanged.

Read the colour-coded “before vs after” dashboard when it finishes.

---

## 🛠️ What Windows-Quick-Boost Does

| Area       | Action Taken                                                                                         |
| ---------- | ---------------------------------------------------------------------------------------------------- |
| Disk       | Deletes `%TEMP%`, `C:\Windows\Temp`, Prefetch & Windows-Update cache, then runs `cleanmgr /sagerun`. |
| RAM / CPU  | Disables Hibernation (`hiberfil.sys`), shortens hung-app timeout, flushes DNS cache.                 |
| Services   | Disables or sets to Manual: SysMain (on SSD), Bluetooth, Print Spooler, Tablet Input.                |
| Visuals    | Switches Windows to the Best Performance visual-effects preset.                                      |
| Power Plan | Activates or creates the High Performance power plan.                                                |
| Benchmarks | Captures disk, RAM, CPU, process & service counts before & after; writes full log + JSON report.     |
| Report     | Prints a big, easy-to-read, colour-coded summary table.                                              |

*Note: No core Windows features are removed. All changes can be manually reversed (see [How to Undo Changes](#how-to-undo-changes)).*

---

## 🖼️ Step-by-Step (for Absolute Beginners)

| Step | Action                           | Example / Screenshot                                 |
| ---- | -------------------------------- | ---------------------------------------------------- |
| 1    | Download & extract               | *(ZIP-extract screenshot in `docs/` folder)*         |
| 2    | Open PowerShell as Administrator | Right-click PowerShell → Run as Administrator        |
| 3    | Navigate to the script folder    | `cd C:\Users\You\Downloads\Windows-Quick-Boost-main` |
| 4    | Run the script (Option 1 or 2)   | *(Paste command or double-click)*                    |
| 5    | Read the final report            | *(Screenshot of colour-coded table)*                 |

---

## 🔄 How to Undo Changes

| Change Made                           | How to Revert                                                                |
| ------------------------------------- | ---------------------------------------------------------------------------- |
| Hibernation disabled                  | `powercfg /h on`                                                             |
| SysMain, Spooler, Bluetooth, Tablet   | `Set-Service <Name> -StartupType Automatic` *(replace `<Name>` accordingly)* |
| Best-Performance visuals applied      | System → Advanced System Settings → Performance → Let Windows decide         |
| High-Performance power plan activated | Settings → System → Power & battery → choose Balanced                        |

---

## 📂 Logs & Reports

All logs & JSON reports are saved to:

```
C:\Users\Public\Windows-Quick-Boost-<YYYY-MM-DD_HH-MM-SS>\
```

---

## ℹ️ Frequently Asked Questions

**Q:** Script won’t run—execution policy blocked!
**A:** Use Option 2 above (`-ExecutionPolicy Bypass`). The bypass is temporary and doesn’t change your default policy.

**Q:** My antivirus flagged something.
**A:** Windows-Quick-Boost modifies system services & registry. Allow it once or add an exclusion for `Windows-Quick-Boost.ps1`.

**Q:** How often should I run this?
**A:** Monthly, or whenever your PC feels sluggish.

---

## 🤝 Contributing

Issues & pull requests are welcome! Ideas:

* Add an interactive `-WhatIf` mode
* Detect Modern Standby laptops and skip hibernation toggle
* Localise messages

**Steps:**

* Fork the repo
* Create a feature branch (`git checkout -b feature-name`)
* Commit your changes
* Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---