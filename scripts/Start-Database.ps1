param([string]$MySqlHome = 'C:\Program Files\MySQL\MySQL Server 8.0')

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$runtime = Join-Path $project '.runtime'
$dbData = Join-Path $runtime 'mysql'
$mysql = Join-Path $MySqlHome 'bin\mysql.exe'
$mysqld = Join-Path $MySqlHome 'bin\mysqld.exe'
$dbArgs = @('--no-defaults', '--protocol=tcp', '--host=127.0.0.1', '--port=33319')
$adminFile = Join-Path $runtime 'db-admin.txt'
$readyFile = Join-Path $runtime 'db-ready'
$null = New-Item -ItemType Directory -Path $runtime -Force

function Test-Port {
    $client = [Net.Sockets.TcpClient]::new()
    try { $client.Connect('127.0.0.1', 33319); return $true }
    catch [Net.Sockets.SocketException] { return $false }
    finally { $client.Dispose() }
}
function Invoke-Admin([string]$Sql, [string]$Password) {
    $previous = $env:MYSQL_PWD
    try {
        $env:MYSQL_PWD = $Password
        & $mysql @dbArgs --user=root --connect-timeout=3 --default-character-set=utf8mb4 --batch --skip-column-names --execute $Sql
        if ($LASTEXITCODE -ne 0) { throw 'Lệnh MySQL thất bại.' }
    } finally { $env:MYSQL_PWD = $previous }
}

if (!(Test-Path -LiteralPath $mysqld)) { throw "Không tìm thấy MySQL Server tại $MySqlHome. Dùng -MySqlHome để chỉ định." }
$serverArgs = @('--no-defaults', "--basedir=""$MySqlHome""", "--datadir=""$dbData""")
if (!(Test-Path -LiteralPath (Join-Path $dbData 'mysql'))) {
    if (Test-Port) { throw 'Cổng 33319 đang được dùng.' }
    $null = New-Item -ItemType Directory -Path $dbData -Force
    $init = Start-Process -FilePath $mysqld -ArgumentList ($serverArgs + @('--initialize-insecure', "--log-error=""$runtime\mysql-init.log""")) -PassThru -Wait -WindowStyle Hidden
    if ($init.ExitCode -ne 0) { throw "Khởi tạo MySQL thất bại. Xem $runtime\mysql-init.log." }
}
if (!(Test-Port)) {
    $startArgs = $serverArgs + @('--bind-address=127.0.0.1', '--port=33319', '--mysqlx=OFF', "--log-error=""$runtime\mysql.log""", "--pid-file=""$runtime\mysql.pid""")
    $db = Start-Process -FilePath $mysqld -ArgumentList $startArgs -WindowStyle Hidden -PassThru
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if (Test-Port) { break }
        if ($db.HasExited) { throw "MySQL đã dừng. Xem $runtime\mysql.log." }
        Start-Sleep -Milliseconds 500
    }
    if (!(Test-Port)) { throw 'MySQL chưa lắng nghe trên cổng 33319.' }
}

$adminPassword = if (Test-Path -LiteralPath $adminFile) { Get-Content -Raw -LiteralPath $adminFile } else { '' }
$serverData = Invoke-Admin 'SELECT @@datadir' $adminPassword
if ([IO.Path]::GetFullPath($serverData).TrimEnd('\') -ne [IO.Path]::GetFullPath($dbData).TrimEnd('\')) {
    throw 'Máy chủ tại cổng 33319 đang sử dụng thư mục dữ liệu khác.'
}
if (!$adminPassword) {
    $adminPassword = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
    Invoke-Admin "ALTER USER 'root'@'localhost' IDENTIFIED BY '$adminPassword';" ''
    Set-Content -LiteralPath $adminFile -Value $adminPassword -NoNewline
}
if (!(Test-Path -LiteralPath $readyFile)) {
    foreach ($file in '01-schema.sql','02-demo.sql') {
        $sql = Get-Content -LiteralPath (Join-Path $project "database\$file") -Raw -Encoding utf8
        Invoke-Admin $sql $adminPassword
    }
    Invoke-Admin @"
CREATE USER IF NOT EXISTS 'supermarket3'@'localhost' IDENTIFIED BY 'Supermarket3Local!2026';
GRANT SELECT, INSERT, UPDATE, DELETE ON OnlineSupermarketDB3.* TO 'supermarket3'@'localhost';
"@ $adminPassword
    Set-Content -LiteralPath $readyFile -Value 'ready'
}
Write-Output 'MySQL Workbench: Standard TCP/IP | 127.0.0.1:33319 | supermarket3 | OnlineSupermarketDB3'
