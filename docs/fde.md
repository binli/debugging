# Ubuntu 26.04 Hardware-Backed FDE Installation Failure Analysis

## System Info

- System: Lenovo ThinkPad with Intel fTPM (CSxE-based firmware TPM)
- Secure Boot: ENABLED (SecureBoot = 0x01)
- Boot chain: shim (Microsoft UEFI CA 2011) -> GRUB -> /casper/vmlinuz (Ubuntu live installer)
- Boot result: Exit Boot Services Returned with Success (boot completed OK)
- Event log source: `tpm2_eventlog binary_bios_measurements`

## TPM2 Event Log Analysis

### Key Findings

#### 1. Single Hash Algorithm TPM

The TPM only supports SHA-256 (numberOfAlgorithms: 1). There is NO SHA-1 bank at all. The `tpm2_pcrread` output confirms:
- sha1: (empty)
- sha256: populated

This may cause issues. Some versions of systemd-cryptenroll or the Ubuntu installer's TPM2 tooling expect both SHA-1 and SHA-256 PCR banks to be present, and fail when SHA-1 is absent.

#### 2. SBAT Level

SbatLevel = `sbat,1,2024010900 / shim,4 / grub,3 / grub.debian,4`

This is the elevated SBAT pushed by Microsoft in mid-2024. The boot completed successfully, so the installed shim meets the requirement, but this SBAT level could cause issues if the installer tries to enroll a PCR policy that includes PCR 7 (Secure Boot state) and the predicted values don't match post-install.

#### 3. PCR 7 State

PCR 7 = `0xFE6EA086...` measures Secure Boot variables (PK, KEK, db, dbx) plus the shim verification authority (Microsoft UEFI CA 2011) and MokListRT (Canonical Master CA). After installation, if the boot chain changes (e.g., GRUB is installed to disk with different signatures), PCR 7 will differ and TPM unsealing will fail.

#### 4. PCR Values Summary

| PCR | Value | Content |
|-----|-------|---------|
| 0 | 0x32A7C7DA... | Firmware (CRTM, POST code, platform firmware blobs) |
| 1 | 0x603E4C50... | Firmware config (Lenovo vars, boot order, boot entries) |
| 2 | 0x61FD7A98... | Boot/runtime services drivers |
| 3 | 0x3D458CFE... | (default - no events) |
| 4 | 0x4548BB3D... | Boot applications (shim, GRUB, kernel) |
| 5 | 0xA5CEB755... | EFI actions (Exit Boot Services) |
| 6 | 0x3D458CFE... | (default - no events) |
| 7 | 0xFE6EA086... | Secure Boot policy (PK, KEK, db, dbx, SbatLevel, MokListRT) |
| 8 | 0x2AD57C48... | GRUB commands (grub.cfg, menuentry, kernel cmdline) |
| 9 | 0x79B72121... | GRUB loaded files (grub.cfg, vmlinuz, initrd) |
| 14 | 0x306F9D8B... | Shim MOK state (MokList, MokListX, MokListTrusted) |

## Root Cause: secboot BootCurrent Bug

The most probable cause is a bug in Canonical's secboot library, fixed in:

**https://github.com/canonical/secboot/pull/536**

Title: "efi/preinstall: Stop relying on BootCurrent"
Author: chrisccoulson (Chris Coulson, Canonical)
Status: Merged (April 2026)
Fixes: https://github.com/canonical/secboot/issues/517, https://github.com/canonical/secboot/issues/519

### The Problem

The old secboot code relied on the `BootCurrent` EFI variable to find the `EV_EFI_BOOT_SERVICES_APPLICATION` event in the TCG log that corresponds to the initial OS loader (shim). This broke on some systems because:

1. Some firmware doesn't set a Boot variable path matching the OS loader when booting from removable media (e.g., USB installer).
2. Some systems don't have `BootCurrent` set at all when booting from removable media.

### Evidence in the Event Log

- **EventNum 42** (PCR 4): `Calling EFI Application from Boot Option`
- **EventNum 54** (PCR 4): shim loaded at 0x7dc47018 with DevicePath pointing to `\EFI\BOOT\BOOTX64.EFI` (removable media path)
- **Boot0001**: points to `\EFI\ubuntu\shimx64.efi` (installed OS path)

The system is booting from removable media (USB installer), so the actual boot path (`\EFI\BOOT\BOOTX64.EFI`) doesn't match what BootCurrent/Boot0001 says (`\EFI\ubuntu\shimx64.efi`). The old secboot code would fail to correlate the TCG log entry with the boot variable, causing the pre-install checks to fail and hardware-backed encryption to be rejected.

### The Fix

The PR changes secboot to use the first OS-present `EV_EFI_BOOT_SERVICES_APPLICATION` event (that isn't Absolute) as the initial OS loader, instead of trying to match via `BootCurrent`. This is more robust on firmware that doesn't properly set `BootCurrent` for removable media boots.

## Suggested Actions

### 1. Use a Newer Installer ISO

If the ISO was built before this PR was merged (April 2026), grab a daily build:
https://cdimage.ubuntu.com/daily-live/current/

### 2. Verify the Fix is Included

```bash
dpkg -l golang-github-canonical-go-secboot-dev 2>/dev/null || \
snap info ubuntu-desktop-installer | grep version
```

### 3. Alternative: Enable SHA-1 PCR Bank

In BIOS setup, check: Security -> Security Chip -> TPM 2.0 -> SHA-1 PCR Bank -> Enable

### 4. Workaround: Install Without FDE First

Install without hardware-backed encryption, then manually enroll:

```bash
sudo systemd-cryptenroll --tpm2-device=auto \
  --tpm2-pcrs=7+11 /dev/<luks-partition>
```
