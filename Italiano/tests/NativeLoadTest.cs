using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
internal static class NativeLoadTest {
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] private static extern IntPtr LoadLibraryEx(string path,IntPtr reserved,uint flags);
    [DllImport("kernel32.dll",CharSet=CharSet.Ansi)] private static extern IntPtr GetProcAddress(IntPtr module,string name);
    [DllImport("kernel32.dll")] private static extern bool FreeLibrary(IntPtr module);
    private static int Main(string[] args) {
        IntPtr module=IntPtr.Zero;
        try {
            module=LoadLibraryEx(Path.GetFullPath(args[0]),IntPtr.Zero,0x00000100|0x00000800);
            if(module==IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
            foreach(string export in new[]{"Initialize","Dispose","InitShellBrowserHook"})
                if(GetProcAddress(module,export)==IntPtr.Zero) throw new Exception("Missing native export: "+export);
            Console.WriteLine("PASS: native DLL loads in isolated "+(IntPtr.Size*8)+"-bit process and exposes its ABI; hooks not initialized");
            return 0;
        } catch(Exception ex){Console.Error.WriteLine(ex);return 1;}
        finally {if(module!=IntPtr.Zero) FreeLibrary(module);}
    }
}
