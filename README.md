# Windows Hello IR-only

Makes Windows Hello face sign-in work in the dark again, without disabling your webcam.

Since the April 2025 Windows update, Hello also needs the **colour** camera to see your face
whenever the colour and IR cameras are in the same camera "sensor group". Some drivers do that
(for example Realtek's `Rts-DMFT-Group`). In a dim room the colour camera can't see you, so Hello fails.
This script removes that group, so Hello uses the IR camera on its own. The webcam keeps working in other apps.

## Use

1. Double-click **`fix.cmd`** and accept the admin prompt.
2. Reboot.
3. Settings → Accounts → Sign-in options → Facial recognition: **Remove**, then set it up again.
   The setup preview should now be black-and-white.

To go back: double-click **`undo.cmd`**, reboot, set up face recognition again.
Undo uses the `backup` folder that `fix.cmd` creates next to the script, so keep that folder.

## Notes

- **Security:** Microsoft added the colour-camera check to fix a face-spoofing issue (CVE-2025-26644).
  This turns that check off, like the common "disable the webcam in Device Manager" workaround does.
- A camera driver reinstall or a big Windows upgrade can bring the group back. Run `fix.cmd` again if that happens.
- Tested on an ASUS ZenBook Duo 14 (UX482EA) with a Realtek USB camera. Use at your own risk.
