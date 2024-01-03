function Get-PlatformInfo {
    $arch = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
    
    switch ($arch) {
        "AMD64" { return "X64" }
        "IA64" { return "X64" }
        "ARM64" { return "X64" }
        "EM64T" { return "X64" }
        "x86" { return "X86" }
        default { throw "Unknown architecture: $arch." }
    }
}

function Get-Arg($arguments, $argName) {
    $argIndex = [Array]::IndexOf($arguments, $argName)
    if ($argIndex -eq -1) {
        throw "Argument $argName not found"
    }
    return $arguments[$argIndex + 1]
}

function Request-String($url) {
    $webClient = New-Object System.Net.WebClient
    return $webClient.DownloadString($url)
}

function Get-Filename($url) {
    $response = Request-String $url
    $jsonObject = ConvertFrom-Json $response
    return $jsonObject.data.fileName
}

function Download-JarFile($url, $outputPath) {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $outputPath)
    
    Write-Host "Downloaded Sucessful."
    Write-Host "File saved to: $outputPath"
}

function Install ($arguments) {
    $platform = Get-PlatformInfo
    if ($platform -ne "x64") {
        throw "Incompatible architecture: $platform"
    }

    $modpackName = "Another Quality Modpack 3 - AQM3"
    $curseforgePath = Join-Path $env:USERPROFILE "curseforge\minecraft\Instances"

    if (-not (Test-Path -Path $curseforgePath -PathType Container)) {
        throw "Curseforge doesn't exist!"
    }

    $modpackPath = Join-Path $curseforgePath "$modpackName\mods"
    if (-not (Test-Path -Path $modpackPath -PathType Container)) {
        throw "Couldnt find modpack directory!"
    }

    $targetMods = Get-Arg $arguments "-targetmods"
    foreach ($data in $targetMods) {
        $modId = $data[0]
        $fileId = $data[1]

        $assetUrl = "https://www.curseforge.com/api/v1/mods/$modId/files/$fileId"
        $modName = Get-Filename $assetUrl
        Write-Host "Mod Name: $modName"

        $downloadUrl = "$assetUrl/download"
        $outputPath = Join-Path $modpackPath $modName 

        Write-Host "Downloading $modName"
        Download-JarFile $downloadUrl $outputPath
        Write-Host ""
    }
}

try {
    Install $args
    Write-Host "Patching successful"
} catch {
    Write-Host "Patching failed: $_"
}

Read-Host Press ENTER to exit...
