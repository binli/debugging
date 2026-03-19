---
name: driver-debug
description: Debug Linux kernel drivers with token-efficient dynamic documentation loading. Use this skill when debugging driver issues, analyzing kernel crashes, dmesg logs, oops messages, lockdep warnings, or investigating hardware/device driver problems. Automatically discovers and loads relevant kernel documentation from Documentation/ based on the specific subsystem.
---

# Linux Kernel Driver Debugging

**Methodology Credits:** This skill incorporates proven methodologies from:
- Brendan Gregg (USE Method, performance analysis)
- Linus Torvalds (debugging philosophy)
- Steven Rostedt (ftrace creator and maintainer)
- Julia Evans (debugging education)
- Kaiwan N. Billimoria (Linux Kernel Debugging book)

## Overview

Debug Linux kernel drivers efficiently by dynamically loading relevant documentation only when needed. This skill provides core debugging knowledge and automatically discovers subsystem-specific documentation from the kernel's Documentation/ tree, minimizing token usage while maximizing relevance.

## Debugging Philosophy & Mindset

### Understand, Don't Just Step Through

**Linus Torvalds' Principle:** "Without a debugger, you basically have to go the next step: understand what the program does."

- Interactive debuggers can lead to superficial fixes that patch symptoms rather than root causes
- Print-based debugging (printk, ftrace) forces you to think about the architecture
- Real problems require understanding the code flow, not just single-stepping

### Focus on Root Cause, Not Symptoms

- Ask "Why?" repeatedly to get to the root cause (Five Whys method from Toyota)
- A crash is often a symptom; the real bug may be earlier in the execution path
- Use-after-free crashes show up far from the actual premature free()

### Information is Key

**Julia Evans' Insight:** "Fixing bugs requires information about what programs are doing."

- Gather data before forming hypotheses
- Use the right tool for the information you need
- Learn new debugging tools when existing ones don't provide needed information

## Systematic Debugging Approaches

### The USE Method (Brendan Gregg)

**Purpose:** Solve ~80% of issues with ~5% of effort through systematic health checks.

**Framework:** For every resource, check **U**tilization, **S**aturation, and **E**rrors.

**Definitions:**
- **Utilization**: Average time the resource was busy servicing work
- **Saturation**: Degree of extra work queued that can't be serviced immediately
- **Errors**: Count of error events

**Step-by-Step Procedure:**

1. **List resources** your driver uses:
   - Hardware: IRQs, DMA channels, I/O ports, memory regions
   - Software: CPU time, kernel memory, locks, workqueues, timers

2. **Check errors first** (fastest to interpret):
   - dmesg errors, /sys/class/ error counters, perf error events

3. **Check utilization** for each resource:
   - Is the resource being used appropriately?

4. **Check saturation** (queuing/waiting):
   - Are requests backing up? Is work being delayed?

5. **Drill down** into problematic areas

**Quick Linux USE Checklist for Driver Issues:**

| Resource | Utilization | Saturation | Errors |
|----------|-------------|------------|--------|
| **CPU** | `vmstat 1` (us+sy columns) | `vmstat` r > CPU count | `perf stat` error counters |
| **Memory** | `free -m`, `sar -r` | `vmstat` si/so (swapping) | `dmesg \| grep -i oom` |
| **Interrupts** | `/proc/interrupts` rate | Check IRQ affinity, misses | Spurious IRQ messages |
| **DMA** | Device-specific counters | Buffer exhaustion | DMA mapping errors |
| **Locks** | `/proc/lock_stat` holdtime | `/proc/lock_stat` waittime | lockdep warnings |
| **Network** | `sar -n DEV` rx/tx vs max | ifconfig drops/overruns | ifconfig errors |
| **Storage I/O** | `iostat -x` %util | `iostat` avgqu-sz > 1 | smartctl, dmesg I/O errors |
| **Workqueues** | ftrace workqueue events | Stalled workqueue warnings | Task blocked messages |

**When to use:** Early in investigation for quick systematic bottleneck identification.

### Problem Statement Method

Before debugging, clearly define:
1. **What** is the problem? (observed behavior)
2. **When** does it occur? (always, intermittent, after suspend, etc.)
3. **What changed?** (new hardware, kernel version, configuration)
4. **How can it be reproduced?** (steps to trigger)

A clear problem statement often reveals the solution.

## Core Debugging Tools

### Essential Debugging Commands

**dmesg Analysis**
```bash
# View recent kernel messages
dmesg | tail -100

# Filter by subsystem/driver
dmesg | grep -i <subsystem>

# Show timestamps
dmesg -T

# Follow new messages
dmesg -w
```

**Dynamic Debug (pr_debug, dev_dbg)**
```bash
# Enable all debug messages for a driver
echo 'file <driver_file.c> +p' > /sys/kernel/debug/dynamic_debug/control

# Enable for entire subsystem
echo 'module <module_name> +p' > /sys/kernel/debug/dynamic_debug/control

# Enable specific function
echo 'func <function_name> +p' > /sys/kernel/debug/dynamic_debug/control
```

**ftrace - Function Tracer**
```bash
# Trace specific function
cd /sys/kernel/debug/tracing
echo function > current_tracer
echo <function_name> > set_ftrace_filter
echo 1 > tracing_on
cat trace

# Trace function graph
echo function_graph > current_tracer
```

**Lockdep Analysis**
- Check `/proc/lockdep` for lock dependencies
- Review lockdep warnings in dmesg for deadlock patterns
- Look for "possible circular locking dependency" messages

**Device/Driver Info**
```bash
# List loaded modules
lsmod

# Module details
modinfo <module_name>

# Device tree
ls -la /sys/bus/*/devices/
lspci -vv  # PCI devices
lsusb -vv  # USB devices
```

## Subsystem Documentation Map

When debugging driver issues, automatically discover relevant documentation using this map:

| Subsystem | Documentation Path | Common Issues |
|-----------|-------------------|---------------|
| **PCI** | `Documentation/PCI/` | ASPM, MSI/MSI-X, power management |
| **USB** | `Documentation/usb/` | Suspend/resume, power management, enumeration |
| **I2C** | `Documentation/i2c/` | Bus errors, timing, fault codes |
| **SPI** | `Documentation/spi/` | Transfer failures, chip select issues |
| **GPIO** | `Documentation/driver-api/gpio/` | Pin configuration, IRQ handling |
| **DMA** | `Documentation/core-api/dma-api.rst` | DMA mapping, coherency issues |
| **Power** | `Documentation/power/` | Suspend/resume, runtime PM |
| **Thunderbolt** | `Documentation/admin-guide/thunderbolt.rst` | Hotplug, tunneling, link training |
| **Network** | `Documentation/networking/` | Driver model, ethtool, napi |
| **Block** | `Documentation/block/` | I/O scheduling, queue management |
| **Graphics** | `Documentation/gpu/` | DRM, display, modesetting |
| **Sound** | `Documentation/sound/` | ALSA, codec issues |
| **Input** | `Documentation/input/` | Event handling, device registration |
| **HID** | `Documentation/hid/` | Device descriptors, parsing |
| **ACPI** | `Documentation/firmware-guide/acpi/` | DSDT/SSDT, methods |
| **Device Tree** | `Documentation/devicetree/bindings/` | DT parsing, overlays |
| **Tracing** | `Documentation/trace/` | ftrace, tracepoints, events |
| **Locking** | `Documentation/locking/` | Spinlocks, mutexes, RCU |
| **Memory** | `Documentation/core-api/memory-allocation.rst` | Allocation failures, leaks |

## Dynamic Documentation Discovery Workflow

### Step 1: Identify the Subsystem

From the error message, dmesg log, or driver path, extract keywords:

**Examples:**
- `drivers/pci/` → subsystem: **pci**
- `i2c_transfer failed` → subsystem: **i2c**
- `thunderbolt 0000:00:0d.2` → subsystem: **thunderbolt**
- `usb 1-3: device descriptor read error` → subsystem: **usb**

### Step 2: Search for Relevant Documentation

Use `grep` to find documentation efficiently:

```bash
# Find all docs mentioning the subsystem
grep -r -i "<keyword>" Documentation/ --include="*.rst" | head -20

# Find specific topic docs
grep -r -i "<error_message>" Documentation/<subsystem>/ --include="*.rst"
```

**Examples:**
```bash
# For USB suspend issues
grep -r -i "suspend\|autosuspend" Documentation/usb/ --include="*.rst"

# For PCI ASPM problems
grep -r -i "aspm\|l1ss" Documentation/PCI/ --include="*.rst"

# For lockdep warnings
grep -r -i "lockdep\|deadlock" Documentation/locking/ --include="*.rst"
```

### Step 3: Load Only Relevant Documentation

**Token-efficient approach:**
- Use `view` tool to read ONLY the specific .rst file identified
- Read specific sections by using line ranges if files are large
- Avoid loading entire Documentation/ directory

**Example:**
```
view Documentation/usb/power-management.rst
view Documentation/PCI/pci.rst [100, 200]  # Only lines 100-200
```

### Step 4: Apply Documentation Knowledge

Use the loaded documentation to:
- Understand error codes and their meanings
- Identify required kernel config options
- Find debugging knobs and sysfs interfaces
- Discover common pitfalls and solutions

## Common Crash Analysis Patterns

### Oops/Panic Messages

**Key information to extract:**
- **IP (Instruction Pointer)**: Shows failing function
- **Call Trace**: Stack backtrace showing call path
- **Register values**: May indicate null pointer (0x0000...)
- **Code disassembly**: Shows assembly around crash

**Example workflow:**
```bash
# Extract call trace
dmesg | grep -A 30 "Call Trace"

# Decode stack trace with symbols
scripts/decode_stacktrace.sh vmlinux < dmesg.log

# Translate function+offset to exact source line
scripts/faddr2line vmlinux function_name+0x123/0x456

# Disassemble the Code: line from oops
scripts/decodecode < oops.txt
```

### NULL Pointer Dereferences

Look for:
- `BUG: kernel NULL pointer dereference`
- `IP: <function>+0x<offset>`
- Register showing `0x0000000000000000`

**Common causes:**
- Missing null checks before accessing pointers
- Race conditions during device initialization
- Use-after-free bugs

### Lockdep Warnings

**Types:**
- `possible circular locking dependency` - Potential deadlock
- `inconsistent lock state` - Lock held in wrong context
- `possible recursive locking detected` - Same lock taken twice

**Analysis:**
- Review the lock chain shown in the warning
- Check if locks are always acquired in consistent order
- Verify lock types match usage context (e.g., don't sleep with spinlock)

### Memory Corruption

**Symptoms:**
- Random crashes in unrelated code
- `slab corruption` messages
- `list_del corruption` or `list_add corruption`

**Debug tools:**
- Enable KASAN (Kernel Address Sanitizer) in config
- Use SLUB debugging: `slub_debug=FZP`
- Check for buffer overruns, use-after-free

## Workflow Decision Tree

**Start here** → What type of issue?

1. **Driver won't load**
   - Check dmesg for module init errors
   - Verify module dependencies with `modinfo`
   - Search Documentation/<subsystem>/ for initialization requirements
   - Check kernel config options

2. **Driver crashes (oops/panic)**
   - Extract call trace from dmesg
   - Identify crashing function
   - **⚠️ For Intel i915/xe/iwlwifi**: If no call trace or unclear crash → Check linux-firmware for firmware updates FIRST
   - Load relevant driver-api documentation
   - Analyze for null pointer, locking, or memory issues
   - **Root cause analysis**: Ask "Why?" 5 times to find the real cause, not just the crash site

3. **Device not working/detected**
   - **USE Method first**: Check errors in dmesg, sysfs counters
   - Check device visibility: `lspci`, `lsusb`, `/sys/bus/`
   - Review dmesg for probe failures
   - **⚠️ For Intel i915/xe/iwlwifi**: If no clear call trace or fix path → Check linux-firmware for firmware updates FIRST
   - Search Documentation/<subsystem>/ for enumeration/probing
   - Verify device tree/ACPI tables if applicable

4. **Performance/timing issues**
   - **USE Method first**: Identify which resource is the bottleneck (CPU, I/O, locks, DMA)
   - Check utilization, saturation, errors for each resource
   - Use ftrace to trace function calls
   - Enable tracepoints for subsystem
   - Load Documentation/trace/ for advanced tracing
   - Check for interrupt storms, busy-wait loops

5. **Suspend/resume problems**
   - Enable PM debug: `echo 1 > /sys/power/pm_debug_messages`
   - Check dmesg during suspend/resume
   - **USE Method**: Check if resource cleanup/restore is complete (locks released, DMA stopped)
   - Load Documentation/power/ docs
   - Review driver's PM callbacks

6. **Locking/deadlock issues**
   - Enable lockdep warnings
   - Analyze lockdep output for circular dependencies
   - **USE Method**: Check lock saturation via `/proc/lock_stat` waittime
   - Load Documentation/locking/ for lock rules
   - Review lock ordering in driver code

## Advanced Debugging Techniques

### printk and pr_* Macros

```c
pr_info("Message\n");         // Informational
pr_warn("Warning\n");          // Warning
pr_err("Error\n");             // Error
pr_debug("Debug\n");           // Debug (needs dynamic_debug or DEBUG)
dev_info(&dev->dev, "Info\n"); // Device-specific
```

### ftrace Function Filtering

```bash
# Trace only driver functions
echo ':mod:<module_name>' > /sys/kernel/debug/tracing/set_ftrace_filter

# Exclude noisy functions
echo '!<function>' >> /sys/kernel/debug/tracing/set_ftrace_notrace
```

### Tracepoints

```bash
# List available tracepoints
ls /sys/kernel/debug/tracing/events/

# Enable subsystem tracepoints
echo 1 > /sys/kernel/debug/tracing/events/<subsystem>/enable

# Read trace output
cat /sys/kernel/debug/tracing/trace
```

### kgdb/kdb (Kernel Debugger)

For interactive debugging with breakpoints and step-through:
- Boot with `kgdboc=ttyS0,115200 kgdbwait`
- Connect gdb to serial port
- Set breakpoints, inspect variables

### eBPF/bpftrace (Modern Production-Safe Tracing)

**eBPF** enables dynamic, low-overhead observability from inside the kernel without invasive agents or code changes.

**When to use:** Production systems where traditional debugging isn't feasible; need dynamic tracing without recompilation.

**Key tools:**
- **bpftrace**: High-level tracing language for one-liners and short scripts (inspired by awk/DTrace)
- **BCC**: Toolkit for complex tools written in Python+C

**Quick examples:**
```bash
# Trace all kernel functions in a driver module
bpftrace -e 'kprobe:module_name:* { printf("%s\n", probe); }'

# Count function calls in a driver
bpftrace -e 'kprobe:driver_function { @calls = count(); }'

# Trace function arguments
bpftrace -e 'kprobe:sys_open { printf("open: %s\n", str(arg0)); }'

# Profile kernel stack traces
bpftrace -e 'profile:hz:99 /pid/ { @[kstack] = count(); }'
```

**Advantages over traditional tracing:**
- Production-safe with minimal overhead
- No kernel recompilation needed
- Dynamic attachment/detachment
- Programmable filtering and aggregation

**Resources:** brendangregg.com/ebpf.html, github.com/iovisor/bcc

## Kernel Script Tools

The Linux kernel provides many helpful scripts in `scripts/` directory for debugging and analysis:

### Crash/Oops Analysis
```bash
# Decode stack traces with full inline call chains
scripts/faddr2line vmlinux function_name+0x123/0x456

# Disassemble "Code:" line from kernel oops
scripts/decodecode < oops.txt
# Or with architecture-specific options:
AFLAGS=--32 scripts/decodecode < oops_i386.txt

# Decode entire stack trace with symbols
scripts/decode_stacktrace.sh vmlinux < dmesg.log

# Pretty-print oops with colors and annotations
scripts/markup_oops.pl vmlinux < oops.txt
```

### Stack Usage Analysis
```bash
# Check stack usage of all functions
scripts/checkstack.pl vmlinux

# Compare stack usage between builds
scripts/stackdelta oldvmlinux newvmlinux

# Track individual function stack usage
scripts/stackusage
```

### Code Size Analysis
```bash
# Compare binary size changes between builds
scripts/bloat-o-meter old/vmlinux new/vmlinux

# Compare module sizes
scripts/bloat-o-meter old/driver.ko new/driver.ko

# Analyze specific object files
scripts/bloat-o-meter old/file.o new/file.o
```

### Memory Allocation Debugging
```bash
# Translate GFP flags to human-readable form
scripts/gfp-translate GFP_KERNEL
scripts/gfp-translate 0x2400c0  # Hex GFP mask

# Example: Understanding allocation failures
# GFP_KERNEL = __GFP_RECLAIM | __GFP_IO | __GFP_FS
```

### Configuration and Module Analysis
```bash
# Extract .config from compiled kernel image
scripts/extract-ikconfig vmlinux
scripts/extract-ikconfig /boot/vmlinuz-$(uname -r)

# Compare kernel configs
scripts/diffconfig .config.old .config.new

# Check/modify config options programmatically
scripts/config --enable DEBUG_INFO
scripts/config --disable MODULE_SIG
scripts/config --state DEBUG_KERNEL

```


### ftrace Debugging
```bash
# Bisect ftrace functions causing crashes
scripts/tracing/ftrace-bisect.sh

# This script helps identify which traced function causes system hangs
# by automatically bisecting the available_filter_functions list
```

### Object Analysis
```bash
# Disassemble a single function from object file
scripts/objdump-func vmlinux schedule

# Compare two object files
scripts/objdiff old.o new.o
```

### Firmware and Binary Extraction
```bash
# Extract kernel module signature
scripts/extract-module-sig.pl module.ko

# Extract vmlinux from compressed kernel images
scripts/extract-vmlinux /boot/vmlinuz-$(uname -r)
```

## Script Tool Workflows

### Workflow 1: Analyzing a Kernel Oops
```bash
# 1. Save dmesg to file
dmesg > oops.log

# 2. Decode full stack trace
scripts/decode_stacktrace.sh vmlinux < oops.log > decoded.txt

# 3. Find exact source line of crash
# Extract function+offset from decoded output
scripts/faddr2line vmlinux function_name+0x123/0x456

# 4. Disassemble the faulting code section
scripts/decodecode < oops.log
```

### Workflow 2: Investigating Stack Overflow
```bash
# 1. Check which functions use most stack
scripts/checkstack.pl vmlinux | head -20

# 2. If you made changes, compare before/after
scripts/stackdelta old/vmlinux new/vmlinux

# 3. Focus on specific subsystem
scripts/checkstack.pl vmlinux | grep drivers/usb
```

### Workflow 3: Debugging Memory Allocation Issues
```bash
# 1. Identify the GFP flags from error message
# Example: "page allocation failure: order:0, mode:0x2400c0"

# 2. Translate to understand what was requested
scripts/gfp-translate 0x2400c0

# Output shows: GFP_KERNEL with __GFP_NOWARN
# This tells you the allocation context and constraints
```

### Workflow 4: Code Size Regression Analysis
```bash
# 1. After making changes, compare sizes
scripts/bloat-o-meter vmlinux.old vmlinux.new

# 2. Drill down to specific files if needed
make drivers/thunderbolt/tb.o
scripts/bloat-o-meter tb.o.old tb.o

# 3. Identify which functions grew
# Consider if the size increase is justified
```

### Workflow 5: Finding Functions Causing ftrace Crashes
```bash
# If enabling function tracing causes system to hang/crash
cd /sys/kernel/tracing
scripts/tracing/ftrace-bisect.sh

# Follow the script's interactive prompts to bisect
# and identify the problematic function
```

## Common Hardware-Specific Patterns

### Thunderbolt/USB4 Issues
```bash
# Check link status and authorization (use grep '' for better output)
grep '' /sys/bus/thunderbolt/devices/*/authorized
grep '' /sys/bus/thunderbolt/devices/domain*/security

# Check NVM version
grep '' /sys/bus/thunderbolt/devices/*/nvm_version

# Monitor hotplug events
udevadm monitor --kernel --subsystem-match=thunderbolt

# List all thunderbolt devices and their properties
ls -la /sys/bus/thunderbolt/devices/
```

### USB Type-C/UCSI Debugging
```bash
# Check connector status (grep '' shows filename:value)
grep '' /sys/class/typec/port*/power_role
grep '' /sys/class/typec/port*/data_role

# Check partner information
ls -la /sys/class/typec/port*/port*-partner/

# UCSI debugging (requires debugfs access)
sudo cat /sys/kernel/debug/usb/ucsi 2>/dev/null
```

### PCIe ASPM/Power Management
```bash
# Check ASPM state via lspci
lspci -vv | grep -i aspm

# Check current ASPM policy
cat /sys/module/pcie_aspm/parameters/policy
# Output: [default] performance powersave powersupersave

# Change ASPM policy (requires root)
echo performance | sudo tee /sys/module/pcie_aspm/parameters/policy
echo powersave | sudo tee /sys/module/pcie_aspm/parameters/policy

# Check device power state
grep '' /sys/bus/pci/devices/*/power_state

# LTR (Latency Tolerance Reporting) info
lspci -vvv | grep -i ltr
```

### Workqueue & Race Condition Debugging
```bash
# Monitor workqueue activity via tracing (requires root/debugfs)
sudo bash -c 'echo 1 > /sys/kernel/debug/tracing/events/workqueue/enable'
sudo cat /sys/kernel/debug/tracing/trace

# Check for hung/blocked tasks
dmesg | grep -i "blocked for more than"
cat /proc/sched_debug | grep -A 5 "runnable tasks"

# Enable workqueue debugging in kernel (needs CONFIG_WQ_WATCHDOG)
# Check dmesg for workqueue stall warnings
dmesg | grep -i "workqueue.*stalled"
```

### WiFi Driver Issues
```bash
# Check firmware loading
dmesg | grep -i firmware

# Monitor wireless events
iw event -f

# Check regulatory domain
iw reg get

# Interface statistics and connection info
iw dev wlan0 station dump
iw dev wlan0 link
```

### Intel Graphics and WiFi Driver Issues (i915, xe, iwlwifi)

**IMPORTANT: Firmware-First Strategy**

For Intel i915 (integrated graphics), xe (discrete graphics), and iwlwifi (WiFi) drivers, many issues are **firmware-related** rather than driver bugs. If you don't have a clear call trace or code-level fix path, **always check for firmware updates first**.

```bash
# Check currently loaded firmware version
dmesg | grep -E "i915|xe|iwlwifi" | grep -i firmware

# Example output:
# [    2.123] i915 0000:00:02.0: [drm] Loaded firmware i915/tgl_dmc_ver2_12.bin
# [    3.456] iwlwifi 0000:00:14.3: loaded firmware version 77.09bf6d39.0 op_mode iwlmvm
```

**When to suspect firmware issues:**

| Driver | Common Firmware-Related Symptoms |
|--------|----------------------------------|
| **i915/xe** | Display not working, blank screen, PSR (Panel Self Refresh) issues, DMC (Display Microcontroller) errors, GuC/HuC load failures, GPU hangs without stack trace |
| **iwlwifi** | Connection drops, poor performance, firmware crashes ("Microcode SW error detected"), CT (Continuous Time) kills, no clear driver code issue |

**Firmware Update Workflow:**

```bash
# 1. Check linux-firmware repository for latest firmware
# Navigate to your linux-firmware repository or clone it:
# git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git

# 2. Check for available firmware versions
ls -lh linux-firmware/i915/      # For Intel graphics
ls -lh linux-firmware/iwlwifi/   # For Intel WiFi

# 3. Compare with installed firmware
ls -lh /lib/firmware/i915/
ls -lh /lib/firmware/iwlwifi/

# 4. Check git log for recent firmware updates
cd linux-firmware
git log --oneline -- i915/ | head -20
git log --oneline -- iwlwifi/ | head -20

# 5. Test with updated firmware
# Copy new firmware to /lib/firmware/ and regenerate initramfs
sudo update-initramfs -u
# Reboot and test
```

**i915/xe Graphics-Specific Checks:**
```bash
# Check DMC (Display Microcontroller) firmware status
dmesg | grep -i dmc

# Check GuC (Graphics Microcontroller) firmware status
dmesg | grep -i guc

# Check HuC (HEVC/Media MicroController) firmware status
dmesg | grep -i huc

# Display panel info and PSR status
cat /sys/kernel/debug/dri/0/i915_display_info 2>/dev/null | grep -i psr
```

**iwlwifi WiFi-Specific Checks:**
```bash
# Check for microcode errors
dmesg | grep -i "microcode sw error"

# Check firmware version and capabilities
dmesg | grep iwlwifi | grep -E "firmware|loaded|version"

# Monitor for firmware crashes
journalctl -k -f | grep iwlwifi
```

**⚠️ REMINDER: Before diving deep into driver code debugging for i915, xe, or iwlwifi:**
1. ✅ Check if there's a firmware update available in linux-firmware
2. ✅ Review recent firmware changelog in linux-firmware git history
3. ✅ Test with updated firmware version
4. ✅ Only proceed with driver code analysis if firmware update doesn't resolve the issue

**Where to find firmware:**
- Official repository: https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git
- Ubuntu/Debian package: `linux-firmware` (may lag behind upstream)
- Check `WHENCE` file in linux-firmware for firmware version info and licensing

## Real-World Debugging Scenarios

### Scenario: Spurious Hotplug/Unplug Events
**Symptoms:** Device repeatedly disconnects and reconnects

**Debug steps:**
```bash
# 1. Monitor kernel events with udev
udevadm monitor --kernel --property

# 2. Watch for disconnect/connect patterns
dmesg -w | grep -E "disconnect|connect"

# 3. Look for error patterns in driver
dmesg | grep -i -E "(error|timeout|failed)" | tail -50

# 4. Disable power management for testing
echo on | sudo tee /sys/bus/*/devices/*/power/control
```

### Scenario: Device Not Resuming from Suspend
**Symptoms:** Device stops working after system suspend/resume

**Debug steps:**
```bash
# 1. Enable PM debugging
echo 1 | sudo tee /sys/power/pm_debug_messages
echo N | sudo tee /sys/module/printk/parameters/console_suspend

# 2. Check PM callbacks execution
dmesg | grep -E "PM: (suspend|resume)" | tail -100

# 3. Test runtime PM separately
echo auto | sudo tee /sys/bus/*/devices/*/power/control
# Wait for autosuspend
echo on | sudo tee /sys/bus/*/devices/*/power/control

# 4. Look for failed PM callbacks
dmesg | grep -i "failed to \(suspend\|resume\)"
```

### Scenario: Kernel Deadlock/Lockup
**Symptoms:** System freezes, no response

**Debug steps:**
```bash
# If system still partially responsive:
echo t | sudo tee /proc/sysrq-trigger  # Dump all task states
echo w | sudo tee /proc/sysrq-trigger  # Dump blocked tasks

# Check for blocked tasks
dmesg | grep -A 20 "blocked for more than"

# Check for lockdep warnings
dmesg | grep -i "possible circular locking dependency"

# After reboot, analyze saved log
scripts/decode_stacktrace.sh vmlinux < saved_dmesg.log
```

### Scenario: Module Unload/Cleanup Race
**Symptoms:** Oops or crash during module removal

**Debug steps:**
```bash
# 1. Reproduce with detailed logging
rmmod -v module_name
dmesg | tail -50

# 2. Check for use-after-free patterns
# Verify all async work is cancelled
grep -r "cancel_work\|cancel_delayed_work\|del_timer" drivers/module/

# 3. Enable KASAN if available (rebuild kernel with CONFIG_KASAN=y)

# 4. Verify cleanup order in module_exit
# Resources should be freed in reverse order of allocation
```

## Token Optimization Strategy

**CRITICAL: Follow this strategy to minimize token usage:**

1. **Never load entire Documentation/ directory** - Always target specific files
2. **Search before reading** - Use `grep` to find relevant docs first
3. **Read selectively** - Use line ranges for large files
4. **Cache patterns** - Common debug steps are in this skill, not in Documentation/
5. **Just-in-time loading** - Only read Documentation/ when investigating specific subsystem issues

**Example of efficient workflow:**
```
User: "Debug USB device not suspending"
→ Use core knowledge from this skill about USB power management
→ grep "autosuspend" Documentation/usb/ to find relevant file
→ view ONLY that file: Documentation/usb/power-management.rst
→ Apply information to debug the specific issue
```

## Quick Reference: Kernel Config Options

Enable these for better debugging:

```
CONFIG_DYNAMIC_DEBUG=y          # pr_debug support
CONFIG_FTRACE=y                  # Function tracing
CONFIG_FUNCTION_TRACER=y         # ftrace support
CONFIG_DEBUG_INFO=y              # Debug symbols
CONFIG_DEBUG_KERNEL=y            # Kernel debugging
CONFIG_LOCKDEP=y                 # Lock dependency tracking
CONFIG_PROVE_LOCKING=y           # Lock correctness checking
CONFIG_DEBUG_ATOMIC_SLEEP=y      # Catch sleeping in atomic context
CONFIG_KASAN=y                   # Address sanitizer (significant overhead)
CONFIG_UBSAN=y                   # Undefined behavior sanitizer
```

## Additional Resources

If the subsystem documentation doesn't answer the question:
- Check kernel source code comments in `drivers/<subsystem>/`
- Review header files in `include/linux/`
- Search LKML archives: https://lore.kernel.org/
- Check subsystem mailing lists in MAINTAINERS file
