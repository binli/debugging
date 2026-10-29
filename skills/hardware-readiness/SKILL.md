---
name: hardware-readiness
description: Assess PCI/USB device driver readiness, fingerprint reader support, and NVIDIA GPU driver support using hw-support, fp-support, and nv-support in ~/.cache/oem-scripts/. Compare database evidence with target OS/kernel and observed driver status.
version: 1.0.0
author: Li Bin (binli)
license: MIT
platforms: [linux]
---

# Hardware Readiness

Assess hardware enablement using the helpers in `~/.cache/oem-scripts/`:

| Device | Helper | Input |
| --- | --- | --- |
| General PCI/USB device | `hw-support query` | `vvvv:dddd` vendor/device or vendor/product ID |
| USB fingerprint reader | `fp-support query` | `vvvv:pppp` USB vendor/product ID |
| NVIDIA GPU | `nv-support query` | Four-digit PCI device ID, without the `10de:` vendor prefix |

## When to Use

- Check whether a PCI or USB device has a known driver and which kernels are recorded as supporting it.
- Check a fingerprint reader's libfprint driver and recorded Ubuntu/upstream versions.
- Check an NVIDIA GPU's recorded proprietary driver versions and features.
- Review a hardware inventory, `lspci`/`lsusb` output, or a target machine's driver bindings.
- Produce a readiness report for a specified Ubuntu release, kernel, or platform.

## Boundaries

- Default to read-only checks. Do not install drivers/packages, load/unload modules, change Secure Boot, update databases, fetch submodules, or file Jira/Launchpad issues without explicit approval.
- Use these helpers; do not silently substitute similarly named scripts elsewhere.
- Use only the `query` subcommands for assessment. `fp-support` and `nv-support` also have `ubuntu`/`upstream` import commands that modify their databases; do not use them during a query.
- Database support is not proof of installation, active driver binding, or functional hardware. Report those separately.
- Do not enumerate the agent's machine when the user is asking about another machine. Use supplied IDs/logs or request the target inventory instead.

## Prerequisites and Paths

Python 3 and the cached tools must be available. The helpers use database paths relative to their working directory. **Set the shell tool's working directory to `~/.cache/oem-scripts/` (expanded to an absolute path)** for all commands below, even when invoking a helper by absolute path.

Required data:

- General hardware: `hw-probe/hw-support.db`; `pci.ids` and `usb.ids` supply device names.
- Fingerprint: `fp_db.json`.
- NVIDIA: `nv_db.json`.

Check that the relevant files exist and are readable before interpreting a no-match result. Missing fingerprint/NVIDIA databases can look like empty databases; `hw-support` may emit warnings or no output. Report missing data as a database problem, not an unsupported device. If needed, report file modification times as cache timestamps, not verified upstream freshness.

## Workflow

### 1. Establish the Target

Use the user's supplied inventory first. Establish the device bus and ID, and the target OS/kernel or driver version if a compatibility verdict is requested. If the target version is unknown, provide the recorded support evidence without claiming readiness for a particular Ubuntu release.

For a requested local-machine assessment, collect read-only evidence as available:

```bash
cat /etc/os-release
uname -r
lspci -Dnnk
lsusb
lsusb -t
```

Do not require root or install missing utilities automatically. If commands are unavailable, use readable sysfs entries or ask for target logs. Keep each physical device/location distinct; identical IDs can occur more than once. Deduplicate database lookups by bus and ID, not the inventory records.

- PCI IDs are the vendor/device pair (for example `8086:51f1`), not a subsystem ID or PCI address.
- USB IDs are the vendor/product pair (for example `04f3:0c18`), not a bus/device number.
- For NVIDIA GPUs, confirm PCI vendor `10de` and a GPU/display function before querying `nv-support`. NVIDIA audio and USB controller functions are not GPU IDs.
- Validate IDs as four hexadecimal digits on each side of `:`. `nv-support` accepts only four hexadecimal device-ID digits.

### 2. Query General PCI/USB Support

Run from the helper directory:

```bash
python3 hw-support query 8086:51f1
```

Record vendor/device name, `Drivers`, and `Support Scope` (recorded kernels). A no-output result means no match was returned, not that no Linux driver exists.

**Bus ambiguity:** the current CLI tries PCI first, then USB only when PCI has no driver match. For a known USB device, or whenever bus-correct results are needed, use the existing library with an explicit bus instead of trusting this automatic choice:

```bash
python3 - <<'PY'
import json
from hw_support.core import HWDatabase

device_id = "04f3:0c18"  # Replace with the validated target ID.
is_pci = False  # True for PCI; False for USB.
db = HWDatabase()
vendor, product = device_id.lower().split(":")
name_lookup = db.get_pci_info if is_pci else db.get_usb_info
vendor_name, device_name = name_lookup(vendor, product)
drivers, kernels = db.get_hw_supported_info(device_id, ispci=is_pci)
print(json.dumps({"bus": "pci" if is_pci else "usb", "id": device_id,
                  "vendor": vendor_name, "device": device_name,
                  "drivers": drivers, "kernels": kernels}))
PY
```

For many devices, instantiate `HWDatabase` once and query the validated inventory in one Python invocation. Avoid dumping the entire database. Multiple drivers may produce a warning; preserve that ambiguity rather than selecting a driver arbitrarily. The helper aggregates driver names and kernels; do not infer a per-kernel driver mapping from those separate lists.

### 3. Check Fingerprint Readers

For a known or suspected USB fingerprint reader, also run:

```bash
python3 fp-support query 04f3:0c18
```

- Output maps recorded libfprint version/source labels to driver names.
- `known_unsupported` is explicit negative evidence for that recorded source/version, not a driver name. Preserve differences between Ubuntu and upstream results.
- `Device not found in database.` means unknown in the available cache, not definitely unsupported.
- A generic USB driver binding is not evidence that fingerprint authentication works. libfprint/fprintd support is a separate userspace requirement.
- Do not assume every USB device from a fingerprint vendor is a fingerprint reader. Use inventory names, class/interface evidence, and database matches; label uncertainty.
- If runtime verification is requested, inspect installed libfprint/fprintd versions and existing service/log evidence as available. Do not enroll, verify, or collect fingerprints automatically.

### 4. Check NVIDIA GPUs

For a GPU with PCI ID `10de:2f18`, pass only `2f18`:

```bash
python3 nv-support query 2f18
```

Record GPU name, listed versions, and features. Also retain general PCI support evidence where relevant.

- Recorded NVIDIA versions are database evidence, not proof that those packages are available for the target release or installed on the target machine.
- Do not describe a recorded version as the minimum supported version or infer support for every newer version.
- Feature flags (for example `kernelopen`) describe recorded capabilities. They do not prove which kernel module is active. The database merges features across imports; do not claim each feature is verified for each listed version.
- A `nouveau` binding does not prove NVIDIA's proprietary driver is active. Distinguish the two.
- When local runtime verification is requested and the tools exist, use read-only `nvidia-smi` and PCI driver-binding evidence. A failed/missing `nvidia-smi` alone does not establish that the GPU is unsupported.
- Only investigate DKMS, Secure Boot, firmware, or logs further when needed to explain a target-machine mismatch; never change them automatically.

### 5. Compare Database Evidence with Runtime State

- `lspci -nnk`: **Kernel driver in use** indicates the bound PCI driver; **Kernel modules** only lists candidate modules.
- USB: use interface-level driver symlinks under `/sys/bus/usb/devices/` and `lsusb -t`. Do not mistake the generic parent USB-device driver for the functional interface driver.
- `lsmod` only proves that a module is loaded somewhere, not that it is bound to this device.
- No bound kernel driver is not automatically a failure: some devices are driven in userspace, and some interfaces do not require a separate functional driver.
- A bound driver is not proof of working firmware, successful suspend/resume, or working end-user functionality. State when functional testing remains unverified.
- A kernel absent from `Support Scope` is **not recorded**, not necessarily unsupported. Do not infer Ubuntu release compatibility or all intermediate/newer kernel support from a list of recorded kernel versions.

## Report Format

Return a concise table, using one row per device/function and keeping source versions explicit:

| Bus / location | ID / device | Recorded driver support | Target runtime | Assessment |
| --- | --- | --- | --- | --- |
| PCI / supplied address | vendor:device / name | Driver and recorded kernel(s) | Bound driver or not checked | Evidence-based result |
| USB / supplied port | vendor:product / fingerprint reader | libfprint driver and version/source | Runtime evidence or not checked | Evidence-based result |
| PCI / supplied address | 10de:device / GPU | NVIDIA versions and relevant features | Bound driver / nvidia-smi or not checked | Evidence-based result |

Use clear assessment labels:

- **Recorded support**: a database match exists; runtime or target-version compatibility may still be unverified.
- **Driver active; function unverified**: device-specific runtime binding is observed, but functionality has not been tested.
- **Verified working**: target-specific functional evidence is available; say what was tested.
- **Known unsupported (recorded version)**: explicit negative evidence such as libfprint's `known_unsupported`.
- **Unknown / not recorded**: no cache match or insufficient target information.
- **Needs investigation**: conflicting evidence or observed runtime errors; describe the evidence without guessing a cause.

Summarize unresolved devices, missing data, and the next read-only check. Do not label an entire platform ready solely from database matches. Avoid full database dumps, unrelated inventory, serial numbers, or biometric data. Use the `jira-bot` or `lp-bot` skill only if the user requests issue lookup or tracking; do not create issues automatically.
