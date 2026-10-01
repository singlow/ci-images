Write-Host "Run CodeSigner"

$CODE_SIGN_TOOL_PATH="C:/CodeSignTool"
$env:CODE_SIGN_TOOL_PATH = "C:/CodeSignTool"

# Exec the specified command or fall back on bash
if ($args.Length -eq 0) {
    $CMD = "powershell"
} else {
    $CMD = $args
}

$CURRENT_ENV = "Production"
$ENVIRONMENT_NAME = $env:ENVIRONMENT_NAME.Replace('"', "")
if ($ENVIRONMENT_NAME -ne "PROD") {
    Copy-Item -Path "C:/CodeSignTool/conf/code_sign_tool.properties" -Destination "C:/CodeSignTool/conf/code_sign_tool.properties.production" -Force
    Copy-Item -Path "C:/CodeSignTool/conf/code_sign_tool_demo.properties" -Destination "C:/CodeSignTool/conf/code_sign_tool.properties" -Force
    $CURRENT_ENV = "Sandbox"
}
Write-Host "Running ESigner.com CodeSign Action on $CURRENT_ENV [$env:JVM_OPTS]"
Write-Host ""

# Arguments, not a script. Passwords and paths must reach java unchanged.
$javaArgs = @()
if ($env:JVM_OPTS) {
    $javaArgs += ($env:JVM_OPTS -split '\s+' | Where-Object { $_ -ne '' })
}
$javaArgs += '-jar'
$javaArgs += 'C:/CodeSignTool/jar/code_sign_tool-1.3.1.jar'
foreach ($param in $args) {
    $javaArgs += [string]$param
}

# Authentication Info
if ($CMD -notcontains "--help") {
    if ($env:USERNAME) { $javaArgs += "-username=$($env:USERNAME)" }
    if ($env:PASSWORD) { $javaArgs += "-password=$($env:PASSWORD)" }

    if ($CMD -notcontains "get_credential_ids") {
        if ($env:CREDENTIAL_ID) { $javaArgs += "-credential_id=$($env:CREDENTIAL_ID)" }
        if ($CMD -notcontains "credential_info") {
            if ($env:TOTP_SECRET) { $javaArgs += "-totp_secret=$($env:TOTP_SECRET)" }
            if ($env:PROGRAM_NAME) { $javaArgs += "-program_name=$($env:PROGRAM_NAME)" }
            if ($env:FILE_PATH) { $javaArgs += "-input_file_path=$($env:FILE_PATH)" }
            if ($env:OUTPUT_PATH) { $javaArgs += "-output_dir_path=$($env:OUTPUT_PATH)" }
        }
    }
}

# Temurin installed by the Windows Dockerfiles at C:\openjdk-11.
$java = 'C:/openjdk-11/bin/java.exe'
Write-Host "Running CodeSignTool"
# CodeSignTool can print an error and still exit 0.
$RESULT = & $java @javaArgs 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $RESULT -match "Error" -OR $RESULT -match "Exception" -OR $RESULT -match "Missing required option" -OR $RESULT -match "Unmatched arguments from" -OR $RESULT -match "Unmatched argument" -OR $RESULT -match "Not a valid output directory") {
    Write-Host "Something Went Wrong. Please try again."
    Write-Host "$RESULT"
    exit 1
} else {
    if ($CMD -contains "sign")
    {
        $LOG_USERNAME = $env:USERNAME.Replace('"', "")
        $LOG_CREDENTIAL_ID = $env:CREDENTIAL_ID.Replace('"', "")
        Write-Host "Code signed successfully by ${LOG_USERNAME} using ${LOG_CREDENTIAL_ID} credential id"
    }
    Write-Host "$RESULT"
}

exit 0
