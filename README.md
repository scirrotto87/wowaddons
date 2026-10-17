# StarskyUI for WoW Forever

StarskyUI 0.1.1 is a free UI prototype for WoW Forever, interface 16001. It provides character-specific profiles, local diagnostics, native Edit Mode access and an optional movable settings launcher. Native UI positions remain under native Edit Mode.

The addon is disabled by default. Enable it only for the intended character. Use `/starskyui` for settings and `/starskyui report` for a local diagnostic report. Reports are not sent automatically. The first login does not show a new panel.

The package contains the full readable Lua source and its TOC. It has no runtime dependencies, paid feature gates, advertisements or in-game donation requests. It includes no saved character settings, backups, private guides or third-party addon code.

Status: experimental. Offline Lua 5.1 checks pass; in-game compatibility and rendering checks remain pending. This project is not affiliated with or approved by Blizzard Entertainment.

Install only the `StarskyUI` directory in the intended client's `Interface/AddOns` directory, after a backup with WoW closed. Do not replace the whole AddOns or WTF directory. Disable StarskyUI for that character to stop it loading.

Development follows Blizzard's [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534/1) and the [Blizzard EULA](https://www.blizzard.com/en-us/legal/fba4d00f-c7e4-4883-b8b9-1b4500a402ea/blizzard-end-user-license-agreement). Source review and tests are not a guarantee of policy compliance or enforcement outcomes.
