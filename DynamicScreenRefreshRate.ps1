<#
This script is changes screen refresh rate according the type of
power source (i.e. AC or battery power). It is to be invoked by
Task Scheduler on power source change event
(i.e. Event ID 105, Kernel Power, Power source change.).
#>


$SystemPowerClass = @'
using System;
using System.Runtime.InteropServices;

public class SystemPower
{
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern Boolean GetSystemPowerStatus(out SystemPowerStatus sps);

    private enum ACLineStatus : byte
    {
        Offline = 0,
        Online = 1,
        Unknown = 255
    }

    private enum BatteryFlag : byte
    {
        High = 1,
        Low = 2,
        Critical = 4,
        Charging = 8,
        NoSystemBattery = 128,
        Unknown = 255
    }

    private struct SystemPowerStatus
    {
        public ACLineStatus LineStatus;
        public BatteryFlag flgBattery;
        public Byte BatteryLifePercent;
        public Byte Reserved1;
        public Int32 BatteryLifeTime;
        public Int32 BatteryFullLifeTime;
    }

    public static Boolean IsACPowerPluggedIn()
    {
        SystemPowerStatus SPS = new SystemPowerStatus();
        GetSystemPowerStatus(out SPS);

        return (SPS.LineStatus == ACLineStatus.Online);
    }
}
'@

$DisplaySettingsClass = @'
using System;
using System.Runtime.InteropServices;

public class DisplaySettings
{
    [DllImport("user32.dll")]
    private static extern bool EnumDisplaySettingsEx(string lpszDeviceName,
                                                     int iModeNum,
                                                     ref DEVMODE lpDevMode,
                                                     uint dwFlags);

    [DllImport("user32.dll")]
    private static extern DISP_CHANGE ChangeDisplaySettingsEx(string lpszDeviceName,
                                                              ref DEVMODE lpDevMode,
                                                              IntPtr hwnd,
                                                              ChangeDisplaySettingsFlags dwflags,
                                                              IntPtr lParam);
    
    private enum DISP_CHANGE : int
    {
        Successful = 0,
        Restart = 1,
        Failed = -1,
        BadMode = -2,
        NotUpdated = -3,
        BadFlags = -4,
        BadParam = -5,
        BadDualView = -6
    }

    private const int ENUM_CURRENT_SETTINGS = -1;
    private const int ENUM_REGISTRY_SETTINGS = -2;

    private const int DM_DISPLAYFREQUENCY = 0x00400000;

    private enum ScreenOrientation : short
    {
        Angle0 = 0,
        Angle90 = 1,
        Angle180 = 2,
        Angle270 = 3,
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct DEVMODE
    {
        private const int CCHDEVICENAME = 32;
        private const int CCHFORMNAME = 32;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHDEVICENAME)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public ScreenOrientation dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = CCHFORMNAME)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }

    [Flags()]
    private enum ChangeDisplaySettingsFlags : uint
    {
        CDS_NONE = 0,
        CDS_UPDATEREGISTRY = 0x00000001,
        CDS_TEST = 0x00000002,
        CDS_FULLSCREEN = 0x00000004,
        CDS_GLOBAL = 0x00000008,
        CDS_SET_PRIMARY = 0x00000010,
        CDS_VIDEOPARAMETERS = 0x00000020,
        CDS_ENABLE_UNSAFE_MODES = 0x00000100,
        CDS_DISABLE_UNSAFE_MODES = 0x00000200,
        CDS_RESET = 0x40000000,
        CDS_RESET_EX = 0x20000000,
        CDS_NORESET = 0x10000000
    }

    public static void SetRefreshRate(int refreshrate)
    {
        // First, check if the given refresh rate is already set
        DEVMODE devMode = new DEVMODE();
        devMode.dmSize = (short)Marshal.SizeOf(devMode);
        devMode.dmDriverExtra = 0;
        EnumDisplaySettingsEx(null, ENUM_CURRENT_SETTINGS, ref devMode, 0);

        if (devMode.dmDisplayFrequency != refreshrate)
        {
            devMode.dmFields = DM_DISPLAYFREQUENCY;
            devMode.dmDisplayFrequency = refreshrate;
            ChangeDisplaySettingsEx(null, ref devMode, IntPtr.Zero, ChangeDisplaySettingsFlags.CDS_UPDATEREGISTRY, IntPtr.Zero);
        }
    }
}
'@

Add-Type -TypeDefinition $SystemPowerClass -Language CSharp
Add-Type -TypeDefinition $DisplaySettingsClass -Language CSharp

####### SETTINGS
$REFRESHRATE_ONBATTERY = 60
$REFRESHRATE_ONAC = 90

####### START
if ( iex '[SystemPower]::IsACPowerPluggedIn()' )
{
    iex ('[DisplaySettings]::SetRefreshRate({0})' -f $REFRESHRATE_ONAC)
}
else
{
    iex ('[DisplaySettings]::SetRefreshRate({0})' -f $REFRESHRATE_ONBATTERY)
}