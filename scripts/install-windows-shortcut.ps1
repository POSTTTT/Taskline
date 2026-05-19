# Creates a Start Menu shortcut for Taskline with the correct AppUserModelID.
# Required for Windows toast notifications when the app is not packaged as MSIX.
# Run once after `flutter build windows`. Re-running is safe (idempotent).

$ErrorActionPreference = 'Stop'

$repoRoot     = Split-Path -Parent $PSScriptRoot
$exePath      = Join-Path $repoRoot 'taskline\build\windows\x64\runner\Release\taskline.exe'
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Taskline.lnk'
$aumid        = 'com.taskline.taskline'

if (-not (Test-Path $exePath)) {
    Write-Error "taskline.exe not found at $exePath. Run 'flutter build windows' first."
    exit 1
}

# Step 1: create the .lnk via WScript.Shell
$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath       = $exePath
$shortcut.WorkingDirectory = Split-Path $exePath
$shortcut.IconLocation     = "$exePath,0"
$shortcut.Save()

# Step 2: stamp the AppUserModelID onto the .lnk via IPropertyStore.
# WScript.Shell can't set this property, so we inline the COM interop in C#.
$source = @'
using System;
using System.Runtime.InteropServices;

namespace TasklineShortcut {
    [StructLayout(LayoutKind.Sequential)]
    public struct PropertyKey {
        public Guid fmtid;
        public uint pid;
        public PropertyKey(Guid fmtid, uint pid) { this.fmtid = fmtid; this.pid = pid; }
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PropVariant {
        public ushort vt;
        public ushort r1, r2, r3;
        public IntPtr ptr;
        public IntPtr unused;
    }

    [ComImport, Guid("00021401-0000-0000-C000-000000000046")]
    public class CShellLink {}

    [ComImport, Guid("0000010B-0000-0000-C000-000000000046"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPersistFile {
        void GetClassID(out Guid pClassID);
        [PreserveSig] int IsDirty();
        void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, uint dwMode);
        void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName,
                  [MarshalAs(UnmanagedType.Bool)] bool fRemember);
        void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
        void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPropertyStore {
        void GetCount(out uint cProps);
        void GetAt(uint iProp, out PropertyKey pkey);
        void GetValue(ref PropertyKey key, out PropVariant pv);
        void SetValue(ref PropertyKey key, ref PropVariant pv);
        void Commit();
    }

    public static class Native {
        [DllImport("ole32.dll")]
        public static extern int PropVariantClear(ref PropVariant pvar);

        [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
        public static extern void SHStrDupW(
            [MarshalAs(UnmanagedType.LPWStr)] string psz, out IntPtr ppwsz);

        public static void Apply(string lnkPath, string aumid) {
            var link = (IPersistFile)new CShellLink();
            link.Load(lnkPath, 2 /* STGM_READWRITE */);
            var store = (IPropertyStore)link;

            // System.AppUserModel.ID
            var pk = new PropertyKey(
                new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), 5);

            var pv = new PropVariant();
            pv.vt = 31; // VT_LPWSTR
            IntPtr str;
            SHStrDupW(aumid, out str);
            pv.ptr = str;

            store.SetValue(ref pk, ref pv);
            store.Commit();
            PropVariantClear(ref pv);

            link.Save(lnkPath, true);
            Marshal.ReleaseComObject(link);
        }
    }
}
'@

Add-Type -TypeDefinition $source -Language CSharp

[TasklineShortcut.Native]::Apply($shortcutPath, $aumid)

Write-Output "Created shortcut: $shortcutPath"
Write-Output "AppUserModelID:   $aumid"
Write-Output "Target:           $exePath"
Write-Output ""
Write-Output "You may need to sign out and back in (or restart explorer.exe) for"
Write-Output "Windows to pick up the new shortcut. After that, toast notifications"
Write-Output "from Taskline will work."
