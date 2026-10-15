param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ZabbixServer,

    [string]$ZabbixServerActive = "",

    [string]$ZabbixHostname = $env:COMPUTERNAME
)

$ErrorActionPreference = "Stop"

# ===== Approved installation version =====

$ZabbixVersion = "7.0.31"
$MsiUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.31/zabbix_agent2-7.0.31-windows-amd64-openssl.msi"
$MsiPath = "C:\Windows\Temp\zabbix-agent2-7.0.31.msi"
$InstallLog = "C:\Windows\Temp\zabbix_agent2_install.log"

# ===== Paths =====

$InstallDir = "C:\Program Files\Zabbix Agent 2"
$ConfigPath = Join-Path $InstallDir "zabbix_agent2.conf"
$AgentExe = Join-Path $InstallDir "zabbix_agent2.exe"
$MetricDir = Join-Path $InstallDir "scripts"
$MetricScript = Join-Path $MetricDir "Get-OSVersion.ps1"
$ServiceName = "Zabbix Agent 2"

if ([string]::IsNullOrWhiteSpace($ZabbixServerActive)) {
    $ZabbixServerActive = $ZabbixServer
}

if ([string]::IsNullOrWhiteSpace($ZabbixHostname)) {
    throw "ZabbixHostname must not be empty."
}

foreach ($value in @($ZabbixServer, $ZabbixServerActive, $ZabbixHostname)) {
    if ($value.Contains("'") -or $value.Contains("`r") -or $value.Contains("`n")) {
        throw "Input values must not contain apostrophes or line breaks."
    }
}

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($CurrentIdentity)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell session."
}

try {
    Write-Output "=== ZABBIX AGENT 2 DEPLOYMENT ==="
    Write-Output "Hostname: $ZabbixHostname"
    Write-Output "Agent version target: $ZabbixVersion"
    Write-Output "Server: $ZabbixServer"
    Write-Output "ServerActive: $ZabbixServerActive"

    New-Item -Path "C:\Windows\Temp" -ItemType Directory -Force |
        Out-Null

    # 1. Install or upgrade when the approved version is not present.
    $CurrentVersion = ""
    $InstallChanged = $false

    if (Test-Path -LiteralPath $AgentExe) {
        $CurrentVersion = (Get-Item -LiteralPath $AgentExe).VersionInfo.ProductVersion
    }

    if ($CurrentVersion -notmatch [regex]::Escape($ZabbixVersion)) {
        Write-Output "`n[1/6] Downloading installer..."

        Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath -UseBasicParsing

        if ((Get-Item -LiteralPath $MsiPath).Length -lt 1MB) {
            throw "Downloaded MSI is unexpectedly small: $MsiPath"
        }

        Write-Output "[2/6] Installing/upgrading Agent 2..."

        $Arguments = @(
            "/i"
            "`"$MsiPath`""
            "/qn"
            "/norestart"
            "/l*v"
            "`"$InstallLog`""
        )

        $Process = Start-Process -FilePath "msiexec.exe" `
            -ArgumentList $Arguments -Wait -PassThru

        if ($Process.ExitCode -notin @(0, 3010)) {
            throw "MSI failed with exit code $($Process.ExitCode). See $InstallLog"
        }

        $InstallChanged = $true
    }
    else {
        Write-Output "`n[1/6] Approved agent version already installed."
        Write-Output "[2/6] Skipping unnecessary reinstall."
    }

    if (-not (Test-Path -LiteralPath $AgentExe) -or
        -not (Test-Path -LiteralPath $ConfigPath)) {
        throw "Agent executable or configuration is missing after installation."
    }

    # 2. Create or update the OS version metric script.
    Write-Output "`n[3/6] Creating OS version metric script..."

    New-Item -Path $MetricDir -ItemType Directory -Force |
        Out-Null

    $MetricContent = @'
$ErrorActionPreference = "Stop"
$os = Get-ItemProperty -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
Write-Output "$($os.CurrentBuild).$($os.UBR)"
'@

    $ScriptChanged = $true

    if (Test-Path -LiteralPath $MetricScript) {
        $Existing = [System.IO.File]::ReadAllText($MetricScript).Trim()

        if ($Existing -ceq $MetricContent.Trim()) {
            $ScriptChanged = $false
        }
    }

    if ($ScriptChanged) {
        Set-Content -LiteralPath $MetricScript `
            -Value $MetricContent -Encoding ASCII
        Write-Output "OS metric script created or updated."
    }
    else {
        Write-Output "OS metric script already matches."
    }

    # 3. Back up config once, then update required settings.
    Write-Output "[4/6] Configuring agent..."

    $BackupPath = "$ConfigPath.unityone-backup"

    if (-not (Test-Path -LiteralPath $BackupPath)) {
        Copy-Item -LiteralPath $ConfigPath -Destination $BackupPath
    }

    $Original = [System.IO.File]::ReadAllText($ConfigPath)
    $Lines = [System.Collections.Generic.List[string]]::new()

    Get-Content -LiteralPath $ConfigPath | ForEach-Object {
        $Lines.Add($_)
    }

    $Settings = [ordered]@{
        "Server"       = $ZabbixServer
        "ServerActive" = $ZabbixServerActive
        "Hostname"     = $ZabbixHostname
    }

    foreach ($Key in $Settings.Keys) {
        $Pattern = "^\s*#?\s*" + [regex]::Escape($Key) + "\s*="
        $Indexes = @(
            for ($i = 0; $i -lt $Lines.Count; $i++) {
                if ($Lines[$i] -match $Pattern) {
                    $i
                }
            }
        )

        $NewLine = "$Key=$($Settings[$Key])"

        if ($Indexes.Count -eq 0) {
            $Lines.Add($NewLine)
        }
        else {
            $Lines[$Indexes[0]] = $NewLine

            for ($j = $Indexes.Count - 1; $j -ge 1; $j--) {
                $Lines.RemoveAt($Indexes[$j])
            }
        }
    }

    $UserParameter = 'UserParameter=uladmin.OSVersion,C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent 2\scripts\Get-OSVersion.ps1"'
    $UPPattern = "^\s*#?\s*UserParameter\s*=\s*uladmin\.OSVersion\s*,"
    $UPIndexes = @(
        for ($i = 0; $i -lt $Lines.Count; $i++) {
            if ($Lines[$i] -match $UPPattern) {
                $i
            }
        }
    )

    if ($UPIndexes.Count -eq 0) {
        $Lines.Add($UserParameter)
    }
    else {
        $Lines[$UPIndexes[0]] = $UserParameter

        for ($j = $UPIndexes.Count - 1; $j -ge 1; $j--) {
            $Lines.RemoveAt($UPIndexes[$j])
        }
    }

    $NewContent = ($Lines -join "`r`n") + "`r`n"
    $ConfigChanged = $NewContent -cne $Original

    if ($ConfigChanged) {
        [System.IO.File]::WriteAllText(
            $ConfigPath,
            $NewContent,
            [System.Text.Encoding]::ASCII
        )
        Write-Output "Agent configuration updated."
    }
    else {
        Write-Output "Agent configuration already matches."
    }

    # 4. Start or restart the service.
    Write-Output "[5/6] Starting and validating service..."

    Set-Service -Name $ServiceName -StartupType Automatic

    if ($ConfigChanged -or $ScriptChanged) {
        Restart-Service -Name $ServiceName -Force
    }
    else {
        $Service = Get-Service -Name $ServiceName

        if ($Service.Status -ne "Running") {
            Start-Service -Name $ServiceName
        }
    }

    $Service = Get-Service -Name $ServiceName

    if ($Service.Status -ne "Running") {
        throw "Zabbix Agent 2 service is not running."
    }

    # 5. Validate installed version and local metric.
    Write-Output "[6/6] Testing agent version and OS metric..."

    $VersionOutput = (& $AgentExe --version 2>&1 | Out-String).Trim()
    $MetricOutput = (& $AgentExe -c $ConfigPath -t uladmin.OSVersion 2>&1 |
        Out-String).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw "OS metric test failed: $MetricOutput"
    }

    if ($MetricOutput -notmatch "uladmin\.OSVersion\s+\[s\|\d+\.\d+\]") {
        throw "OS metric returned an unexpected result: $MetricOutput"
    }

    Write-Output ""
    Write-Output "=== DEPLOYMENT SUCCESSFUL ==="
    Write-Output "Hostname: $ZabbixHostname"
    Write-Output "Agent version output: $VersionOutput"
    Write-Output "OS metric: $MetricOutput"
    Write-Output "Service state: $($Service.Status)"
    Write-Output "Installation changed: $InstallChanged"
    Write-Output "Configuration changed: $ConfigChanged"
    Write-Output "Metric script changed: $ScriptChanged"
}
catch {
    Write-Error "Zabbix Agent 2 deployment failed: $($_.Exception.Message)"
    exit 1
}
