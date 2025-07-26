# Definir as variáveis para a entrada no hosts
$HostName = "host.novochat.internal"
$IPAddress = "192.168.5.40"
$HostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"

Write-Host "Verificando se a entrada '$IPAddress $HostName' já existe no arquivo hosts..." -ForegroundColor Yellow

# Ler o conteúdo atual do arquivo hosts
$HostsFileContent = Get-Content $HostsFilePath -Raw

# Construir a entrada que queremos adicionar
$NewEntry = "$IPAddress`t$HostName" # `t é para tab, que é comum em arquivos hosts

# Verificar se a entrada já existe no conteúdo (ignorando espaços em branco e diferenciação de maiúsculas/minúsculas)
if ($HostsFileContent -match "(?mi)^[\s]*$($IPAddress)[\s]+$($HostName)[\s]*$") {
    Write-Host "A entrada '$IPAddress $HostName' já existe no arquivo hosts. Nenhuma alteração necessária." -ForegroundColor Green
}
else {
    Write-Host "A entrada '$IPAddress $HostName' NÃO foi encontrada." -ForegroundColor Yellow
    Write-Host "Adicionando a entrada ao arquivo hosts..." -ForegroundColor Yellow

    # Adicionar a nova entrada ao final do arquivo
    try {
        Add-Content -Path $HostsFilePath -Value "`n# Adicionado por script PowerShell para NovoChat`n$NewEntry"
        Write-Host "Entrada '$IPAddress $HostName' adicionada com sucesso ao arquivo hosts." -ForegroundColor Green
    }
    catch {
        Write-Host "Erro ao adicionar a entrada ao arquivo hosts. Certifique-se de que o PowerShell foi executado como Administrador." -ForegroundColor Red
        Write-Host "Detalhes do Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Processo concluído." -ForegroundColor Green

# Opcional: Para ver o conteúdo atualizado do arquivo hosts no console
# Get-Content $HostsFilePath
