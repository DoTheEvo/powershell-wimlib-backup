$wimlib_exe_full_path = "C:\ProgramData\wimlib_backup\wimlib-1.12.0-windows-x86_64-bin\wimlib-imagex.exe"

Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Multiselect = $false # Multiple files can be chosen
    Filter = 'wim archives (*.wim)|*.wim' # Specified file types
    InitialDirectory = 'C:\'
}

[void]$FileBrowser.ShowDialog()

$file = $FileBrowser.FileName;
If($FileBrowser.FileNames -like "*\*") {


    cleaner_wimlib_info $FileBrowser.FileName

}

else {
    Write-Host "Cancelled by user"
}

function cleaner_wimlib_info([string]$wim_file_full_path) {
    &$wimlib_exe_full_path info, $wim_file_full_path | ?{ $_ -notmatch`
    '(Architecture|Attributes|Boot Index|Build|Chunk Size|Compression|Default Language|Description|Display (Description|Name)|Directory Count|Edition ID|File Count|Flags|GUID|HAL|Hard Link Bytes|Installation Type|Languages|Modification Time|Part Number|Product (Suite|Type)|Service Pack Level|System Root|Version|WIMBoot compatible):' } | `
    %{ if ($_ -match '(Total Bytes:\s*)(\d+)' -or $_ -match '(Size:\s*)(\d+)' )  {
          if ([int64]$Matches[2] -ge 1GB) { $divider = 1GB ; $unit = " GB" } else { $divider = 1MB ; $unit = " MB" }
          $Matches[1] + [Math]::Ceiling($Matches[2] / $divider).ToString("N0") + $unit
       } else { $_ }}
}
