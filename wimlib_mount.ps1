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

    $wim_images = @{}
    $wimarchive_full_path = $FileBrowser.FileName
    $info_output = &$wimlib_exe_full_path info $wimarchive_full_path
    $info_output | % {
        if ($_ -match '^Index:\s*(\d+)'){
            $temp_match = $Matches[1]
        }
        if ($_ -match '^Creation Time:\s+(.+)'){
            $wim_images[$temp_match] = $Matches[1]
        }
    }
    # sort hashtable from the latest
    $wim_images = $wim_images.getenumerator() | sort-object -property Name -Descending
    $wim_images

}

else {
    Write-Host "Cancelled by user"
}
