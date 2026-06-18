# Integration Test Checklist (run on a real unraid box / VM)

**English** | [中文](TESTING.zh-CN.md)

Prerequisite: a release has been published (push a date tag to trigger the release workflow), or build locally and test by hand.

1. Install: Plugins → Install Plugin → paste the .plg URL → Install.
   - [ ] Installs without errors; the log shows "komari-agent installed".
   - [ ] The Settings → Komari Agent page opens.
2. Configure and start:
   - [ ] Fill Endpoint + Token, check Enabled + Disable Web SSH, Save & Apply.
   - [ ] Status shows running; the host appears online on the Komari dashboard.
3. Architecture correctness:
   - [ ] `uname -m` matches the cached binary suffix under `/boot/config/plugins/komari-agent/`.
4. Reboot persistence (core acceptance):
   - [ ] Reboot unraid → after boot, with no manual action, Status is running and the host comes back online.
5. Crash recovery:
   - [ ] `kill $(cat /var/run/komari-agent.pid)` → within a minute Status returns to running.
6. Disable semantics:
   - [ ] Click Stop → Status stopped; wait 2 minutes, the watchdog does not bring it back.
   - [ ] Reboot unraid → stays stopped (ENABLED=no honored).
7. Offline cache:
   - [ ] Disconnect the network, reboot unraid → still starts from the USB-flash cache.
8. Update:
   - [ ] Change VERSION to a specific tag, click Check Update → cache is replaced, agent restarts on the new version.
9. Uninstall:
   - [ ] Remove the plugin → process stops; `/etc/cron.d/komari-agent` and `/etc/rc.d/rc.komari-agent` removed; directories cleaned up.
