# ================================
# CONFIG
# ================================
$drive    = "C:"
$logPath  = "C:\Windows\Temp\bitlocker_cbc_enforce.log"
$flagFile = "C:\ProgramData\BitLockerMigration\reencrypt.flag"

function Log {
    param([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $msg" | Tee-Object -FilePath $logPath -Append
}

function Get-BdeStatus {
    manage-bde -status $drive | Out-String
}

Log "==== START BitLocker CBC Enforcement ===="

# ================================
# CHECAR STATUS
# ================================
$status = Get-BdeStatus

Log "Status atual:"
Log $status

# ================================
# IDEMPOTÊNCIA
# ================================
$isOn      = $status -match "Protection Status:\s+Protection On"
$isAes256  = $status -match "AES 256" -and $status -notmatch "XTS"
$isFullyDecrypted = $status -match "Percentage Encrypted:\s+0\.?0*%"

if ($isOn -and $isAes256) {
    Log "Já está em AES-256 CBC com proteção ativa. Nenhuma ação necessária."
    exit 0
}

# ================================
# SE ESTIVER (PARCIALMENTE) CRIPTOGRAFADO
# ================================
$encryptedMatch = [regex]::Match($status, "Percentage Encrypted:\s+([\d\.]+)%")
$encryptedPct   = if ($encryptedMatch.Success) { [double]$encryptedMatch.Groups[1].Value } else { 0 }

if ($encryptedPct -gt 0) {
    Log "Disco com $encryptedPct% criptografado. Iniciando descriptografia..."

    manage-bde -off $drive | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Log "ERRO ao iniciar descriptografia (exit $LASTEXITCODE). Abortando."
        exit 1
    }

    $timeout  = 120
    $attempts = 0
    do {
        Start-Sleep -Seconds 30
        $attempts++
        $progressLine = (manage-bde -status $drive | Select-String "Percentage Encrypted").ToString()
        Log $progressLine

        $done = $progressLine -match "Percentage Encrypted:\s+0\.?0*%"

        if ($attempts -ge $timeout) {
            Log "ERRO: Timeout aguardando descriptografia após $($attempts * 30 / 60) minutos. Abortando."
            exit 1
        }
    } while (-not $done)

    Log "Descriptografia concluída."
}

# ================================
# APLICAR REGISTRY
# ================================
Log "Aplicando política CBC AES-256..."

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Force | Out-Null

$xtsKeys = @(
    "EncryptionMethodWithXtsOs",
    "EncryptionMethodWithXtsFdv",
    "EncryptionMethodWithXtsRdv"
)
foreach ($key in $xtsKeys) {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name $key -ErrorAction SilentlyContinue
}

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "EncryptionMethodWithOs"  -Value 4 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "EncryptionMethodWithFdv" -Value 4 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "EncryptionMethodWithRdv" -Value 4 -Type DWord

gpupdate /force | Out-Null

Log "Política de registro aplicada com sucesso."

# ================================
# REBOOT CONTROLADO
# ================================
if (!(Test-Path $flagFile)) {
    $flagDir = Split-Path $flagFile
    if (!(Test-Path $flagDir)) { New-Item -ItemType Directory -Path $flagDir -Force | Out-Null }

    Log "Criando flag de reentrada pós-reboot."
    New-Item $flagFile -ItemType File -Force | Out-Null

    Log "Reiniciando em 60 segundos..."
    shutdown /r /t 3
    exit 0
}

# ================================
# PÓS-REBOOT: ATIVAR BITLOCKER
# ================================
Log "Pós-reboot detectado. Ativando BitLocker com TPM + RecoveryPassword..."

manage-bde -protectors -add $drive -tpm | Out-Null
if ($LASTEXITCODE -ne 0) {
    Log "AVISO: Não foi possível adicionar protetor TPM (exit $LASTEXITCODE). Continuando apenas com RecoveryPassword."
}

manage-bde -on $drive -RecoveryPassword -SkipHardwareTest | Out-Null
if ($LASTEXITCODE -ne 0) {
    Log "ERRO ao ativar BitLocker (exit $LASTEXITCODE). Abortando."
    exit 1
}

Start-Sleep -Seconds 15

$statusFinal = Get-BdeStatus

Log "Status final:"
Log $statusFinal

# ================================
# VALIDAÇÃO FINAL
# ================================
if ($statusFinal -match "AES 256" -and $statusFinal -notmatch "XTS") {
    Log "SUCESSO: AES-256 CBC aplicado corretamente."
    Remove-Item $flagFile -Force
    exit 0
} else {
    Log "ERRO: Não foi possível confirmar AES-256 CBC no status final."
    exit 1
}