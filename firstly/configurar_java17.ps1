# Script PowerShell para configurar Java 17 permanentemente
# Execute como Administrador

Write-Host "Configurando Java 17 como padrão do sistema..." -ForegroundColor Green

# Definir JAVA_HOME
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-17.0.15.6-hotspot", "Machine")

# Obter PATH atual
$path = [Environment]::GetEnvironmentVariable("PATH", "Machine")

# Remover entradas antigas do Java
$pathEntries = $path -split ";"
$cleanPath = $pathEntries | Where-Object { $_ -notlike "*java*" -and $_ -notlike "*jdk*" -and $_ -notlike "*jre*" }

# Adicionar Java 17 no início
$newPath = "%JAVA_HOME%\bin;" + ($cleanPath -join ";")

# Configurar novo PATH
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")

Write-Host "Configuração concluída!" -ForegroundColor Green
Write-Host "Reinicie o terminal e o VS Code para aplicar as mudanças." -ForegroundColor Yellow
