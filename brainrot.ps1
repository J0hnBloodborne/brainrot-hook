# brainrot: opens Instagram Reels while an AI agent works.
#   brainrot on      arm it
#   brainrot off     disarm it
#   brainrot status  show state
#   brainrot hook    prompt-submit hook; if armed, switches to the open Reels tab or opens one
#   brainrot back    stop hook; refocuses the window that was in front before `hook`
param([string]$Action = 'status')

$flag = Join-Path $env:USERPROFILE '.brainrot-on'
$saved = Join-Path $env:USERPROFILE '.brainrot-return'
$url = 'https://www.instagram.com/reels/'

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type -Namespace Brainrot -Name Win -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
[DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
'@
$ua = [System.Windows.Automation.AutomationElement]
# Class "Tab" keeps only Chrome's own tab strip; web pages expose their own TabItems too.
$tabItem = New-Object System.Windows.Automation.AndCondition(
    (New-Object System.Windows.Automation.PropertyCondition($ua::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)),
    (New-Object System.Windows.Automation.PropertyCondition($ua::ClassNameProperty, 'Tab')))
$selPattern = [System.Windows.Automation.SelectionItemPattern]::Pattern

function Get-ChromeWindows {
    # Window titles only show each window's front tab, so read Chrome's tab strips through UI Automation instead.
    foreach ($p in Get-Process chrome -ErrorAction SilentlyContinue) {
        $byPid = New-Object System.Windows.Automation.PropertyCondition($ua::ProcessIdProperty, $p.Id)
        $ua::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, $byPid)
    }
}

function Get-Tabs($win) { $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $tabItem) }

function Find-ReelsTab {
    # Returns @(window, tab) for the first Instagram tab, or $null.
    foreach ($win in Get-ChromeWindows) {
        foreach ($tab in Get-Tabs $win) {
            if ($tab.Current.Name -like '*Instagram*') { return @($win, $tab) }
        }
    }
    return $null
}

function Focus-Window([IntPtr]$h) {
    if ([Brainrot.Win]::IsIconic($h)) { [void][Brainrot.Win]::ShowWindow($h, 9) }
    # Windows refuses focus changes from background processes; a synthetic Alt tap lifts that lock.
    [Brainrot.Win]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)
    [Brainrot.Win]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
    [void][Brainrot.Win]::SetForegroundWindow($h)
}

function Save-Return { [int64][Brainrot.Win]::GetForegroundWindow() | Set-Content $saved }

function Restore-Return {
    if (-not (Test-Path $saved)) { return }
    $h = [int64](Get-Content $saved -Raw)
    Remove-Item $saved
    Focus-Window ([IntPtr]$h)
}

function Open-Reels {
    $chrome = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction SilentlyContinue).'(default)'
    if ($chrome) { Start-Process $chrome $url } else { Start-Process $url }
}

switch ($Action) {
    'on'     { New-Item -ItemType File -Force $flag | Out-Null; 'brainrot: on' }
    'off'    { Remove-Item $flag -ErrorAction SilentlyContinue; 'brainrot: off' }
    'status' { if (Test-Path $flag) { 'brainrot: on' } else { 'brainrot: off' } }
    'hook'   {
        if (-not (Test-Path $flag)) { break }
        Save-Return
        $found = Find-ReelsTab
        if ($found) {
            $found[1].GetCurrentPattern($selPattern).Select()
            Focus-Window ([IntPtr]$found[0].Current.NativeWindowHandle)
        } else { Open-Reels }
    }
    'back'   { Restore-Return }
    default  { "usage: brainrot on|off|status"; exit 1 }
}
