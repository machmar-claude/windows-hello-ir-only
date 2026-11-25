# Windows Hello IR-only

Makes Windows Hello face sign-in work in the dark again, without disabling your webcam.

Since the April 2025 Windows update, Hello also needs the **colour** camera to see your face
whenever the colour and IR cameras are in the same camera "sensor group". Some drivers do that
(for example Realtek's `Rts-DMFT-Group`). In a dim room the colour camera can't see you, so Hello fails.
This script removes that group, so Hello uses the IR camera on its own. The webcam keeps working in other apps.

## Use

1. Download `windows-hello-ir-only.zip` from [Releases](../../releases/latest) and extract it.
   Double-click **`fix.cmd`** and accept the admin prompt.
2. Reboot.
3. Settings → Accounts → Sign-in options → Facial recognition: **Remove**, then set it up again.
   The setup preview should now be black-and-white.

To go back: double-click **`undo.cmd`**, reboot, set up face recognition again.
Undo uses the `backup` folder that `fix.cmd` creates next to the script, so keep that folder.

## How it works

Windows' camera service (Frame Server) bundles cameras into **sensor groups**. Cameras that carry the
same `FSSensorGroupID` value end up in one group. That value comes from the camera driver's INF or from
the camera's own firmware. Windows Hello signs you in through a group that has a face sign-in stream.
When that group holds both the colour and the IR camera, Hello checks the colour picture as well.

`hello-ir-only.ps1`:

1. Reads the groups Windows has published under
   `HKLM\SOFTWARE\Microsoft\Windows Media Foundation\FrameServer\SensorGroups` and picks the ones that
   combine two or more cameras and have a face sign-in stream.
2. For each camera in such a group, finds where the group is stored: the camera's device key
   (`Enum\...\Device Parameters`) and each of its device-interface keys (`Control\DeviceClasses\...`).
3. Backs up each of those keys to `backup\*.reg`, then deletes `FSSensorGroupID` / `FSSensorGroupName`
   (and the `UVC-` versions) from them.
4. Restarts the cameras, the camera service and the biometric service.

After a reboot, Windows publishes each camera as its own group. The IR camera alone still has a face
sign-in stream, so Hello uses it. The colour camera alone is a normal webcam.
`undo.cmd` imports the `.reg` backups, which puts the values back.

## Notes

- **Security:** Microsoft added the colour-camera check to fix a face-spoofing issue (CVE-2025-26644).
  This turns that check off, like the common "disable the webcam in Device Manager" workaround does.
- A camera driver reinstall or a big Windows upgrade can bring the group back. Run `fix.cmd` again if that happens.
- Tested on an ASUS ZenBook Duo 14 (UX482EA) with a Realtek USB camera. Use at your own risk.
