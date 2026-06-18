###@VERSION@###
- Initial release for unraid: runs the Komari monitoring agent bare-metal on the host
- Per-architecture binary downloaded from GitHub and cached on the USB flash
- Auto-start on boot, crash recovery via the watchdog, config persisted across reboots
- Settings page: Token / Auto-discovery modes, Disable Web SSH, advanced options
- Settings page polish: native Unraid form layout, click-to-show field help, save-time validation, action feedback (Save / Check Update results), and a Basic/Advanced view matching the VM Manager animation
- Multi-language UI (English, Simplified / Traditional Chinese, Japanese) that follows Unraid's active language
- Live log streaming (SSE) with a console-styled viewer, and a status badge in the page title bar
- Agent auto-update (semver), with the new build synced back to the flash cache
- CI and tag-triggered automated releases, with release notes rendered from the changelog
