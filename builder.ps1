# ============================================================
# AdaSpace3D - Bulletproof Build & Flash Script
# ============================================================
# A self-contained build system that:
# 1. Downloads Arduino CLI if needed
# 2. Configures Board Manager URLs (CRITICAL FIX)
# 3. Installs required cores and libraries
# 4. Compiles with custom USB descriptors for 3DConnexion
# 5. Auto-flashes to RP2040 in bootloader mode
# ============================================================

# Get script root - use current location since FLASH.bat sets it
$ScriptRoot = Get-Location | Select-Object -ExpandProperty Path

# ============================================================
# Configuration
# ============================================================
$ARDUINO_CLI_VERSION = "1.1.1"
$ARDUINO_CLI_URL = "https://github.com/arduino/arduino-cli/releases/download/v$ARDUINO_CLI_VERSION/arduino-cli_${ARDUINO_CLI_VERSION}_Windows_64bit.zip"

$TOOLS_DIR = [System.IO.Path]::Combine($ScriptRoot, "tools")
$ARDUINO_CLI = [System.IO.Path]::Combine($TOOLS_DIR, "arduino-cli.exe")
$BUILD_TEMP = [System.IO.Path]::Combine($ScriptRoot, "Build_Temp")
$SKETCH_BUILD_DIR = [System.IO.Path]::Combine($BUILD_TEMP, "AdaSpace3D")

$BOARD_FQBN = "rp2040:rp2040:adafruit_qtpy"
$USB_STACK = "tinyusb"

# Custom USB descriptors for 3DConnexion SpaceMouse
$USB_VID = "0x256f"
$USB_PID = "0xc631"
$USB_PRODUCT = "SpaceMouse Pro Wireless"
$USB_MANUFACTURER = "3Dconnexion"

# Source files
$MAIN_SKETCH = "AdaSpace3D.ino"
$USER_CONFIG = "UserConfig.h"

# ============================================================
# Helper Functions
# ============================================================

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Step {
    param([string]$StepNum, [string]$Message)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor White
    Write-Host " STEP $StepNum : $Message" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor White
}

function Exit-WithError {
    param([string]$Message)
    Write-Host ""
    Write-Error-Custom $Message
    Write-Host ""
    Write-Host "Build failed. Please check the error messages above." -ForegroundColor Red
    exit 1
}

# ============================================================
# STEP 1: Portable Arduino CLI Check & Download
# ============================================================
function Ensure-ArduinoCLI {
    Write-Step "1" "Checking Arduino CLI"
    
    if ([System.IO.File]::Exists($ARDUINO_CLI)) {
        Write-Success "Arduino CLI found at: $ARDUINO_CLI"
        
        # Verify it works
        try {
            $version = & $ARDUINO_CLI version 2>&1
            Write-Info "Version: $version"
        }
        catch {
            Write-Warning-Custom "Arduino CLI exists but may be corrupted. Re-downloading..."
            [System.IO.File]::Delete($ARDUINO_CLI)
        }
    }
    
    if (-not [System.IO.File]::Exists($ARDUINO_CLI)) {
        Write-Info "Arduino CLI not found. Downloading portable version..."
        
        # Create tools directory
        if (-not [System.IO.Directory]::Exists($TOOLS_DIR)) {
            [System.IO.Directory]::CreateDirectory($TOOLS_DIR) | Out-Null
            Write-Info "Created tools directory: $TOOLS_DIR"
        }
        
        $zipPath = [System.IO.Path]::Combine($TOOLS_DIR, "arduino-cli.zip")
        
        Write-Info "Downloading from: $ARDUINO_CLI_URL"
        try {
            # Use TLS 1.2 for GitHub
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            
            $ProgressPreference = 'SilentlyContinue'  # Speeds up download significantly
            Invoke-WebRequest -Uri $ARDUINO_CLI_URL -OutFile $zipPath -UseBasicParsing
            $ProgressPreference = 'Continue'
            
            Write-Success "Download complete!"
        }
        catch {
            Exit-WithError "Failed to download Arduino CLI: $_"
        }
        
        Write-Info "Extracting Arduino CLI..."
        try {
            Expand-Archive -LiteralPath $zipPath -DestinationPath $TOOLS_DIR -Force
            Write-Success "Extraction complete!"
        }
        catch {
            Exit-WithError "Failed to extract Arduino CLI: $_"
        }
        
        # Clean up zip file
        if ([System.IO.File]::Exists($zipPath)) {
            [System.IO.File]::Delete($zipPath)
        }
        
        if (-not [System.IO.File]::Exists($ARDUINO_CLI)) {
            Exit-WithError "Arduino CLI extraction failed - executable not found!"
        }
        
        Write-Success "Arduino CLI installed successfully!"
    }
}

# ============================================================
# STEP 2: Install Dependencies (Core & Libraries)
# ============================================================
function Install-Dependencies {
    Write-Step "2" "Installing Dependencies"
    
    # --- CRITICAL FIX: Add Third-Party Board URL ---
    # We must tell Arduino CLI where to find the RP2040 core
    $EARLE_URL = "https://github.com/earlephilhower/arduino-pico/releases/download/global/package_rp2040_index.json"
    
    # Initialize config if missing
    if (-not (Test-Path "$TOOLS_DIR\arduino-cli.yaml")) {
        & $ARDUINO_CLI config init --dest-dir "$TOOLS_DIR" | Out-Null
    }
    
    Write-Info "Configuring Board Manager..."
    # We use 'set' to ensure it's there
    & $ARDUINO_CLI config set board_manager.additional_urls $EARLE_URL | Out-Null
    
    # Update core index
    Write-Info "Updating Arduino core index..."
    & $ARDUINO_CLI core update-index 2>&1 | Out-Null
    Write-Success "Core index updated!"
    
    # Install RP2040 core
    # Install RP2040 core
    Write-Info "Installing RP2040 core..."
    & $ARDUINO_CLI core install rp2040:rp2040
    if ($LASTEXITCODE -ne 0) {
        Exit-WithError "Failed to install RP2040 core. Please check your internet connection."
    }
    Write-Success "RP2040 core installed!"
    
    # List of required libraries
    $libs = @(
        "Adafruit TinyUSB Library",
        "XENSIV 3D Magnetic Sensor TLx493D",
        "Adafruit NeoPixel" 
    )

    foreach ($lib in $libs) {
        Write-Info "Checking $lib..."
        $installed = & $ARDUINO_CLI lib list 2>&1 | Select-String $lib
        if (-not $installed) {
            Write-Info "Installing $lib..."
            & $ARDUINO_CLI lib install $lib 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                 Exit-WithError "Failed to install $lib"
            }
        }
        Write-Success "$lib is ready."
    }
}

# ============================================================
# STEP 3: Shadow Build Setup
# ============================================================
function Setup-ShadowBuild {
    Write-Step "3" "Setting Up Shadow Build"
    
    $sourceSketch = [System.IO.Path]::Combine($ScriptRoot, $MAIN_SKETCH)
    $sourceConfig = [System.IO.Path]::Combine($ScriptRoot, $USER_CONFIG)
    
    # Validate source files exist
    if (-not [System.IO.File]::Exists($sourceSketch)) {
        Exit-WithError "Main sketch not found: $sourceSketch"
    }
    
    if (-not [System.IO.File]::Exists($sourceConfig)) {
        Exit-WithError "User config not found: $sourceConfig"
    }
    
    Write-Info "Source files validated!"
    
    # Clean and create build temp directory
    if ([System.IO.Directory]::Exists($BUILD_TEMP)) {
        Write-Info "Cleaning previous build directory..."
        
        # Try multiple methods to delete, with retries
        $maxRetries = 3
        $deleted = $false
        
        for ($i = 1; $i -le $maxRetries; $i++) {
            try {
                # Use PowerShell's Remove-Item which handles more cases
                Remove-Item -LiteralPath $BUILD_TEMP -Recurse -Force -ErrorAction Stop
                $deleted = $true
                break
            }
            catch {
                if ($i -lt $maxRetries) {
                    Write-Warning-Custom "Retry $i/$maxRetries - Waiting for files to unlock..."
                    Start-Sleep -Seconds 2
                }
                else {
                    Write-Warning-Custom "Could not fully clean build directory. Continuing anyway..."
                }
            }
        }
    }
    
    # Create the shadow build directory with correct name
    if (-not [System.IO.Directory]::Exists($SKETCH_BUILD_DIR)) {
        [System.IO.Directory]::CreateDirectory($SKETCH_BUILD_DIR) | Out-Null
    }
    Write-Info "Created shadow build directory: $SKETCH_BUILD_DIR"
    
    # Copy source files
    $destSketch = [System.IO.Path]::Combine($SKETCH_BUILD_DIR, $MAIN_SKETCH)
    $destConfig = [System.IO.Path]::Combine($SKETCH_BUILD_DIR, $USER_CONFIG)
    
    [System.IO.File]::Copy($sourceSketch, $destSketch, $true)
    [System.IO.File]::Copy($sourceConfig, $destConfig, $true)
    
    Write-Success "Source files copied to shadow build directory!"
    Write-Info "  - $MAIN_SKETCH"
    Write-Info "  - $USER_CONFIG"
}

# ============================================================
# STEP 4: Compile with Custom USB Descriptors
# ============================================================
function Compile-Firmware {
    Write-Step "4" "Compiling Firmware"
    
    $sketchPath = $SKETCH_BUILD_DIR
    $outputDir = [System.IO.Path]::Combine($BUILD_TEMP, "output")
    
    Write-Info "Board: $BOARD_FQBN" 
    Write-Info "Injecting USB ID: $USB_VID / $USB_PID"
    
    # Build a proper argument list
    $fqbn = "${BOARD_FQBN}:usbstack=$USB_STACK"
    
    # --- FIXED FLAGS FOR COMPILER ---
    # We now rely on standard build properties which the RP2040 core handles natively.
    
    $propVid       = "build.vid=$USB_VID"
    $propPid       = "build.pid=$USB_PID"
    $propUsbVid    = "build.usbvid=-DUSBD_VID=$USB_VID"
    $propUsbPid    = "build.usbpid=-DUSBD_PID=$USB_PID"
    
    # Careful quoting for properties with spaces
    $propProduct   = "build.usb_product=\`"$USB_PRODUCT\`""
    $propMfg       = "build.usb_manufacturer=\`"$USB_MANUFACTURER\`""
    
    # Build the argument string manually to handle paths with spaces correctly
    $argString = "compile --fqbn `"$fqbn`" " +
    "--build-property `"$propVid`" " +
    "--build-property `"$propPid`" " +
    "--build-property `"$propUsbVid`" " +
    "--build-property `"$propUsbPid`" " +
    "--build-property `"$propProduct`" " +
    "--build-property `"$propMfg`" " +
    "--output-dir `"$outputDir`" " +
    "`"$sketchPath`""
    
    # Start the compile process with async output capture
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $ARDUINO_CLI
    $pinfo.Arguments = $argString
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.WorkingDirectory = $ScriptRoot
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $pinfo
    
    # Use StringBuilder to collect output asynchronously
    $stdoutBuilder = New-Object System.Text.StringBuilder
    $stderrBuilder = New-Object System.Text.StringBuilder
    
    # Register event handlers for async reading
    $stdoutEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
        if ($EventArgs.Data) { $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null }
    } -MessageData $stdoutBuilder
    
    $stderrEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
        if ($EventArgs.Data) { $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null }
    } -MessageData $stderrBuilder
    
    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
    
    # Animated spinner while compiling
    $spinner = @('|', '/', '-', '\')
    $spinIdx = 0
    $startTime = Get-Date
    
    Write-Host ""
    while (-not $process.HasExited) {
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        $spinChar = $spinner[$spinIdx % 4]
        Write-Host "`r  [$spinChar] Compiling... $([math]::Floor($elapsed))s " -NoNewline -ForegroundColor Cyan
        $spinIdx++
        Start-Sleep -Milliseconds 150
    }
    
    # Wait for async reads to complete
    $process.WaitForExit()
    Start-Sleep -Milliseconds 100
    
    # Cleanup event handlers
    Unregister-Event -SourceIdentifier $stdoutEvent.Name
    Unregister-Event -SourceIdentifier $stderrEvent.Name
    
    # Clear the spinner line
    Write-Host "`r                                        `r" -NoNewline
    
    $stdout = $stdoutBuilder.ToString()
    $stderr = $stderrBuilder.ToString()
    
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    
    if ($process.ExitCode -ne 0) {
        Write-Host ""
        Write-Error-Custom "Compilation failed! (${elapsed}s)"
        Write-Host ""
        if ($stderr) { Write-Host $stderr -ForegroundColor Red }
        if ($stdout) { Write-Host $stdout -ForegroundColor Gray }
        exit 1
    }
    
    # Verify UF2 file was created
    if (-not [System.IO.Directory]::Exists($outputDir)) {
        Exit-WithError "Output directory not created - compilation may have failed!"
    }
    
    $uf2Files = [System.IO.Directory]::GetFiles($outputDir, "*.uf2")
    
    if ($uf2Files.Count -eq 0) {
        Exit-WithError "Compilation succeeded but UF2 file not found in output directory!"
    }
    
    $uf2File = Get-Item -LiteralPath $uf2Files[0]
    
    Write-Success "Compiled in ${elapsed}s ($([math]::Round($uf2File.Length / 1024, 2)) KB)"
    
    return $uf2File.FullName
}

# ============================================================
# STEP 5: Auto-Flash to RP2040
# ============================================================
function Flash-Firmware {
    param([string]$UF2Path)
    
    Write-Step "5" "Flashing Firmware"
    
    if (-not [System.IO.File]::Exists($UF2Path)) {
        Exit-WithError "UF2 file not found: $UF2Path"
    }
    
    function Find-BootloaderDrive {
        $drives = Get-WmiObject Win32_Volume | Where-Object { $_.Label -eq "RPI-RP2" }
        if ($drives) {
            return $drives.DriveLetter
        }
        return $null
    }
    
    function Copy-ToBootloader {
        param([string]$DriveLetter, [string]$SourceFile)
        
        $fileName = [System.IO.Path]::GetFileName($SourceFile)
        $destPath = [System.IO.Path]::Combine($DriveLetter, $fileName)
        
        Write-Info "Copying firmware to $DriveLetter..."
        try {
            [System.IO.File]::Copy($SourceFile, $destPath, $true)
            Write-Success "Firmware copied successfully!"
            return $true
        }
        catch {
            Write-Error-Custom "Failed to copy firmware: $_"
            return $false
        }
    }
    
    # First attempt to find the bootloader drive
    $bootDrive = Find-BootloaderDrive
    
    if ($bootDrive) {
        Write-Info "Found RP2040 bootloader at: $bootDrive"
        $success = Copy-ToBootloader -DriveLetter $bootDrive -SourceFile $UF2Path
        
        if ($success) {
            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host " FLASHING COMPLETE!" -ForegroundColor Green
            Write-Host "============================================================" -ForegroundColor Green
            Write-Host ""
            Write-Success "Your AdaSpace3D SpaceMouse firmware has been installed!"
            Write-Info "The device will automatically restart."
            return
        }
    }
    else {
        Write-Warning-Custom "Device not in bootloader mode."
        Write-Host ""
        Write-Host "  To enter bootloader mode:" -ForegroundColor Yellow
        Write-Host "    1. Hold the BOOT button" -ForegroundColor Yellow
        Write-Host "    2. Press and release the RESET button" -ForegroundColor Yellow
        Write-Host "    3. Release the BOOT button" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  A new drive called 'RPI-RP2' should appear." -ForegroundColor Yellow
        Write-Host ""
        
        Read-Host "Press Enter when ready to try again"
        
        # Second attempt
        $bootDrive = Find-BootloaderDrive
        
        if ($bootDrive) {
            Write-Info "Found RP2040 bootloader at: $bootDrive"
            $success = Copy-ToBootloader -DriveLetter $bootDrive -SourceFile $UF2Path
            
            if ($success) {
                Write-Host ""
                Write-Host "============================================================" -ForegroundColor Green
                Write-Host " FLASHING COMPLETE!" -ForegroundColor Green
                Write-Host "============================================================" -ForegroundColor Green
                Write-Host ""
                Write-Success "Your AdaSpace3D SpaceMouse firmware has been installed!"
                Write-Info "The device will automatically restart."
                return
            }
        }
        else {
            Write-Host ""
            Write-Warning-Custom "Still could not find bootloader drive."
            Write-Host ""
            Write-Info "The firmware has been compiled successfully and saved to:"
            Write-Host "  $UF2Path" -ForegroundColor Cyan
            Write-Host ""
            Write-Info "You can manually copy this .uf2 file to the RPI-RP2 drive."
        }
    }
}

# ============================================================
# Main Execution
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "    AdaSpace3D - One-Click Build & Flash System" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""
Write-Info "Script Root: $ScriptRoot"
Write-Host ""

try {
    # Step 1: Ensure Arduino CLI is available
    Ensure-ArduinoCLI
    
    # Step 2: Install dependencies
    Install-Dependencies
    
    # Step 3: Set up shadow build directory
    Setup-ShadowBuild
    
    # Step 4: Compile firmware
    $uf2Path = Compile-Firmware
    
    # Step 5: Flash to device
    Flash-Firmware -UF2Path $uf2Path
    
}
catch {
    Write-Host ""
    Write-Error-Custom "An unexpected error occurred: $_"
    Write-Error-Custom $_.ScriptStackTrace
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " BUILD PROCESS COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""


