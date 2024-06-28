The script to catch the vblank wait timed out on crtc 0 error in the kernel log.

```bash
#!/bin/bash
journalctl -k | grep "drm_wait_one_vblank"
```
```
Jun 19 00:03:05 Hedy-5 kernel: [    2.137954] ------------[ cut here ]------------
Jun 19 00:03:05 Hedy-5 kernel: [    2.137956] i915 0000:00:02.0: vblank wait timed out on crtc 0
Jun 19 00:03:05 Hedy-5 kernel: [    2.137977] WARNING: CPU: 2 PID: 283 at drivers/gpu/drm/drm_vblank.c:1310 drm_wait_one_vblank+0x1ef/0x210 [drm]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138037] Modules linked in: i915(+) drm_buddy i2c_algo_bit ttm drm_display_helper crct10dif_pclmul crc32_pclmul cec polyval_clmulni rc_core polyval_generic ghash_clmulni_intel sha256_ssse3 drm_kms_helper hid_generic sha1_ssse3 aesni_intel nvme crypto_simd ucsi_acpi intel_lpss_pci spi_intel_pci cryptd drm i2c_i801 i2c_hid_acpi xhci_pci nvme_core psmouse e1000e thunderbolt typec_ucsi intel_lpss spi_intel i2c_smbus i2c_hid xhci_pci_renesas nvme_common video idma64 typec hid wmi pinctrl_meteorlake
Jun 19 00:03:05 Hedy-5 kernel: [    2.138066] CPU: 2 PID: 283 Comm: systemd-udevd Not tainted 6.5.0-1024-oem #25-Ubuntu
Jun 19 00:03:05 Hedy-5 kernel: [    2.138070] Hardware name: LENOVO 21G3ZC1TUS/21G3ZC1TUS, BIOS R2DET29W (1.14 ) 06/11/2024
Jun 19 00:03:05 Hedy-5 kernel: [    2.138071] RIP: 0010:drm_wait_one_vblank+0x1ef/0x210 [drm]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138117] Code: fe ff ff 48 8b 7b 08 4c 8b 6f 50 4d 85 ed 74 26 e8 f6 d8 d4 d7 44 89 e1 4c 89 ea 48 c7 c7 18 7a 83 c0 48 89 c6 e8 e1 2a 33 d7 <0f> 0b e9 7b fe ff ff 48 8b 1f eb 94 4c 8b 2f eb d5 e8 eb 0c 36 d8
Jun 19 00:03:05 Hedy-5 kernel: [    2.138119] RSP: 0018:ffffa1c7c0b33718 EFLAGS: 00010246
Jun 19 00:03:05 Hedy-5 kernel: [    2.138122] RAX: 0000000000000000 RBX: ffff962967368000 RCX: 0000000000000000
Jun 19 00:03:05 Hedy-5 kernel: [    2.138123] RDX: 0000000000000000 RSI: 0000000000000000 RDI: 0000000000000000
Jun 19 00:03:05 Hedy-5 kernel: [    2.138124] RBP: ffffa1c7c0b33770 R08: 0000000000000000 R09: 0000000000000000
Jun 19 00:03:05 Hedy-5 kernel: [    2.138126] R10: 0000000000000000 R11: 0000000000000000 R12: 0000000000000000
Jun 19 00:03:05 Hedy-5 kernel: [    2.138127] R13: ffff96294324cb20 R14: 0000000000000001 R15: ffff962967347030
Jun 19 00:03:05 Hedy-5 kernel: [    2.138128] FS:  00007e78036028c0(0000) GS:ffff962c9fe80000(0000) knlGS:0000000000000000
Jun 19 00:03:05 Hedy-5 kernel: [    2.138130] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
Jun 19 00:03:05 Hedy-5 kernel: [    2.138132] CR2: 000064927f387e20 CR3: 000000012043e006 CR4: 0000000000770ee0
Jun 19 00:03:05 Hedy-5 kernel: [    2.138134] DR0: 0000000000000000 DR1: 0000000000000000 DR2: 0000000000000000
Jun 19 00:03:05 Hedy-5 kernel: [    2.138135] DR3: 0000000000000000 DR6: 00000000ffff07f0 DR7: 0000000000000400
Jun 19 00:03:05 Hedy-5 kernel: [    2.138136] PKRU: 55555554
Jun 19 00:03:05 Hedy-5 kernel: [    2.138137] Call Trace:
Jun 19 00:03:05 Hedy-5 kernel: [    2.138139]  <TASK>
Jun 19 00:03:05 Hedy-5 kernel: [    2.138141]  ? show_regs+0x6d/0x80
Jun 19 00:03:05 Hedy-5 kernel: [    2.138147]  ? __warn+0x89/0x160
Jun 19 00:03:05 Hedy-5 kernel: [    2.138151]  ? drm_wait_one_vblank+0x1ef/0x210 [drm]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138195]  ? report_bug+0x17e/0x1b0
Jun 19 00:03:05 Hedy-5 kernel: [    2.138201]  ? handle_bug+0x46/0x90
Jun 19 00:03:05 Hedy-5 kernel: [    2.138205]  ? exc_invalid_op+0x18/0x80
Jun 19 00:03:05 Hedy-5 kernel: [    2.138209]  ? asm_exc_invalid_op+0x1b/0x20
Jun 19 00:03:05 Hedy-5 kernel: [    2.138214]  ? drm_wait_one_vblank+0x1ef/0x210 [drm]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138256]  ? drm_wait_one_vblank+0x1ef/0x210 [drm]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138297]  ? __pfx_autoremove_wake_function+0x10/0x10
Jun 19 00:03:05 Hedy-5 kernel: [    2.138302]  drm_crtc_wait_one_vblank+0x17/0x30 [drm]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138344]  intel_crtc_wait_for_next_vblank+0xe/0x20 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138582]  intel_plane_disable_noatomic+0x13b/0x230 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.138791]  intel_find_initial_plane_obj+0x1d6/0x260 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.139013]  intel_crtc_initial_plane_config+0x61/0xe0 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.139211]  intel_display_driver_probe_nogem+0x1c8/0x250 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.139418]  i915_driver_probe+0x30d/0x5a0 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.139564]  ? drm_privacy_screen_get+0x16d/0x190 [drm]
Jun 19 00:03:05 Hedy-5 kernel: [    2.139608]  ? acpi_dev_found+0x64/0x80
Jun 19 00:03:05 Hedy-5 kernel: [    2.139613]  i915_pci_probe+0xd0/0x170 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.139758]  local_pci_probe+0x44/0xb0
Jun 19 00:03:05 Hedy-5 kernel: [    2.139764]  pci_call_probe+0x55/0x1a0
Jun 19 00:03:05 Hedy-5 kernel: [    2.139768]  pci_device_probe+0x84/0x120
Jun 19 00:03:05 Hedy-5 kernel: [    2.139770]  really_probe+0x1c9/0x430
Jun 19 00:03:05 Hedy-5 kernel: [    2.139775]  __driver_probe_device+0x8c/0x190
Jun 19 00:03:05 Hedy-5 kernel: [    2.139779]  driver_probe_device+0x24/0xd0
Jun 19 00:03:05 Hedy-5 kernel: [    2.139782]  __driver_attach+0x10b/0x210
Jun 19 00:03:05 Hedy-5 kernel: [    2.139786]  ? __pfx___driver_attach+0x10/0x10
Jun 19 00:03:05 Hedy-5 kernel: [    2.139790]  bus_for_each_dev+0x8a/0xf0
Jun 19 00:03:05 Hedy-5 kernel: [    2.139793]  driver_attach+0x1e/0x30
Jun 19 00:03:05 Hedy-5 kernel: [    2.139796]  bus_add_driver+0x127/0x240
Jun 19 00:03:05 Hedy-5 kernel: [    2.139799]  driver_register+0x5e/0x130
Jun 19 00:03:05 Hedy-5 kernel: [    2.139803]  __pci_register_driver+0x62/0x70
Jun 19 00:03:05 Hedy-5 kernel: [    2.139806]  i915_pci_register_driver+0x23/0x30 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.139944]  i915_init+0x34/0x120 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.140080]  ? __pfx_i915_init+0x10/0x10 [i915]
Jun 19 00:03:05 Hedy-5 kernel: [    2.140213]  do_one_initcall+0x5b/0x340
Jun 19 00:03:05 Hedy-5 kernel: [    2.140219]  do_init_module+0x68/0x260
Jun 19 00:03:05 Hedy-5 kernel: [    2.140223]  load_module+0xb85/0xcd0
Jun 19 00:03:05 Hedy-5 kernel: [    2.140229]  init_module_from_file+0x96/0x100
Jun 19 00:03:05 Hedy-5 kernel: [    2.140232]  ? init_module_from_file+0x96/0x100
Jun 19 00:03:05 Hedy-5 kernel: [    2.140237]  idempotent_init_module+0x11c/0x2b0
Jun 19 00:03:05 Hedy-5 kernel: [    2.140242]  __x64_sys_finit_module+0x64/0xd0
Jun 19 00:03:05 Hedy-5 kernel: [    2.140246]  x64_sys_call+0x130f/0x20b0
Jun 19 00:03:05 Hedy-5 kernel: [    2.140248]  do_syscall_64+0x55/0x90
Jun 19 00:03:05 Hedy-5 kernel: [    2.140251]  ? exit_to_user_mode_prepare+0x30/0xb0
Jun 19 00:03:05 Hedy-5 kernel: [    2.140254]  ? syscall_exit_to_user_mode+0x37/0x60
Jun 19 00:03:05 Hedy-5 kernel: [    2.140257]  ? do_syscall_64+0x61/0x90
Jun 19 00:03:05 Hedy-5 kernel: [    2.140260]  ? do_syscall_64+0x61/0x90
Jun 19 00:03:05 Hedy-5 kernel: [    2.140262]  entry_SYSCALL_64_after_hwframe+0x73/0xdd
Jun 19 00:03:05 Hedy-5 kernel: [    2.140265] RIP: 0033:0x7e7803cfc88d
Jun 19 00:03:05 Hedy-5 kernel: [    2.140276] Code: 5b 41 5c c3 66 0f 1f 84 00 00 00 00 00 f3 0f 1e fa 48 89 f8 48 89 f7 48 89 d6 48 89 ca 4d 89 c2 4d 89 c8 4c 8b 4c 24 08 0f 05 <48> 3d 01 f0 ff ff 73 01 c3 48 8b 0d 73 b5 0f 00 f7 d8 64 89 01 48
Jun 19 00:03:05 Hedy-5 kernel: [    2.140278] RSP: 002b:00007ffd05bf4368 EFLAGS: 00000246 ORIG_RAX: 0000000000000139
Jun 19 00:03:05 Hedy-5 kernel: [    2.140280] RAX: ffffffffffffffda RBX: 000064927f388ac0 RCX: 00007e7803cfc88d
Jun 19 00:03:05 Hedy-5 kernel: [    2.140282] RDX: 0000000000000000 RSI: 00007e7803e94441 RDI: 0000000000000014
Jun 19 00:03:05 Hedy-5 kernel: [    2.140283] RBP: 0000000000020000 R08: 0000000000000000 R09: 0000000000000002
Jun 19 00:03:05 Hedy-5 kernel: [    2.140284] R10: 0000000000000014 R11: 0000000000000246 R12: 00007e7803e94441
Jun 19 00:03:05 Hedy-5 kernel: [    2.140286] R13: 000064927f394110 R14: 000064927f370de0 R15: 000064927f34d990
Jun 19 00:03:05 Hedy-5 kernel: [    2.140288]  </TASK>
Jun 19 00:03:05 Hedy-5 kernel: [    2.140289] ---[ end trace 0000000000000000 ]---
```
