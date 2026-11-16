param(
    [string]$JavaHome,
    [string]$TomcatHome,
    [string]$MavenCommand,
    [string]$MySqlHome = 'C:\Program Files\MySQL\MySQL Server 8.0',
    [switch]$Stop
)

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$bundled = Join-Path (Split-Path -Parent $project) 'tmp\supermarket-runtime'
$runtime = Join-Path $project '.runtime'
$webBase = Join-Path $runtime 'tomcat'
$pidFile = Join-Path $runtime 'tomcat.pid'
$webPort = 18087

function Test-Port {
    $client = [Net.Sockets.TcpClient]::new()
    try { $client.Connect('127.0.0.1', $webPort); return $true }
    catch [Net.Sockets.SocketException] { return $false }
    finally { $client.Dispose() }
}

if ($Stop) {
    $tomcatProcess = $null
    if (Test-Path -LiteralPath $pidFile) {
        $tomcatPid = 0
        if ([int]::TryParse((Get-Content -LiteralPath $pidFile -Raw), [ref]$tomcatPid) -and $tomcatPid -gt 0) {
            $candidate = Get-Process -Id $tomcatPid -ErrorAction SilentlyContinue
            if ($candidate -and $candidate.ProcessName -eq 'java') {
                $info = Get-CimInstance Win32_Process -Filter "ProcessId = $tomcatPid"
                $baseArgument = [regex]::Escape("-Dcatalina.base=$webBase")
                if ($info.CommandLine -match "(?:^|\s)`"?$baseArgument`"?(?:\s|$)" -and
                    $info.CommandLine -match '\sorg\.apache\.catalina\.startup\.Bootstrap\s+start(?:\s|$)') {
                    $tomcatProcess = $candidate
                }
            }
        }
    }
    if ($tomcatProcess) {
        Stop-Process -InputObject $tomcatProcess
        if (!$tomcatProcess.WaitForExit(10000)) { throw 'Tomcat chưa thoát sau 10 giây.' }
    }
    if (Test-Port) { throw "Cổng $webPort vẫn mở. Không tìm được tiến trình Tomcat của dự án đang giữ cổng." }
    if (Test-Path -LiteralPath $pidFile) { Remove-Item -LiteralPath $pidFile }
    Write-Output "Web đã dừng. Cổng $webPort đã đóng."
    return
}

& (Join-Path $PSScriptRoot 'Start-Database.ps1') -MySqlHome $MySqlHome
if (Test-Port) {
    Write-Output "Cổng web đã mở. Kiểm tra ứng dụng tại http://127.0.0.1:$webPort/OnlineSupermarket3/"
    return
}
if (!$JavaHome) { $JavaHome = $env:JAVA_HOME }
if (!$TomcatHome) { $TomcatHome = $env:CATALINA_HOME }
$mvnOptions = @()
if (Test-Path -LiteralPath $bundled) {
    if (!$JavaHome) { $JavaHome = (Get-ChildItem $bundled -Directory -Filter 'jdk-*' | Select-Object -First 1).FullName }
    if (!$TomcatHome) { $TomcatHome = (Get-ChildItem $bundled -Directory -Filter 'apache-tomcat-*' | Select-Object -First 1).FullName }
    if (!$MavenCommand) {
        $mavenHome = (Get-ChildItem $bundled -Directory -Filter 'apache-maven-*' | Select-Object -First 1).FullName
        if ($mavenHome) { $MavenCommand = Join-Path $mavenHome 'bin\mvn.cmd' }
        if ($mavenHome -and (Test-Path -LiteralPath (Join-Path $bundled 'm2'))) {
            $mvnOptions = @('-o', "-Dmaven.repo.local=$bundled\m2")
        }
    }
}
if (!$JavaHome -or !$TomcatHome) {
    throw 'Cần Java 17 và Tomcat 9. Dùng -JavaHome và -TomcatHome hoặc đặt JAVA_HOME và CATALINA_HOME.'
}
if (!$MavenCommand) { $MavenCommand = 'mvn' }
$env:JAVA_HOME = $JavaHome
& $MavenCommand @mvnOptions -f (Join-Path $project 'pom.xml') package
if ($LASTEXITCODE -ne 0) { throw 'Không build được WAR.' }

if (!(Test-Path -LiteralPath (Join-Path $webBase 'conf\server.xml'))) {
    $null = New-Item -ItemType Directory -Path $webBase -Force
    Copy-Item -LiteralPath (Join-Path $TomcatHome 'conf') -Destination (Join-Path $webBase 'conf') -Recurse
    foreach ($name in 'logs','temp','webapps','work') {
        $null = New-Item -ItemType Directory -Path (Join-Path $webBase $name) -Force
    }
    $conf = Join-Path $webBase 'conf\server.xml'
    $config = [xml](Get-Content -LiteralPath $conf -Raw)
    $config.Server.SetAttribute('port','-1')
    $http = $config.SelectSingleNode('//Connector[@port="8080"]')
    $http.SetAttribute('port', "$webPort")
    $http.SetAttribute('address','127.0.0.1')
    $config.Save($conf)
}
Copy-Item -LiteralPath (Join-Path $project 'target\OnlineSupermarket3.war') -Destination (Join-Path $webBase 'webapps') -Force
$env:SUPERMARKET_DB_URL = 'jdbc:mysql://127.0.0.1:33319/OnlineSupermarketDB3?connectionTimeZone=Asia/Bangkok'
$env:SUPERMARKET_DB_USER = 'supermarket3'
$env:SUPERMARKET_DB_PASSWORD = 'Supermarket3Local!2026'
$jarPath = (Join-Path $TomcatHome 'bin\bootstrap.jar') + ';' + (Join-Path $TomcatHome 'bin\tomcat-juli.jar')
$java = Join-Path $JavaHome 'bin\java.exe'
$javaArgs = @("""-Dcatalina.home=$TomcatHome""", """-Dcatalina.base=$webBase""",
    '-cp', """$jarPath""", 'org.apache.catalina.startup.Bootstrap', 'start')
$tomcat = Start-Process -FilePath $java -ArgumentList $javaArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $webBase 'stdout.log') -RedirectStandardError (Join-Path $webBase 'stderr.log')
Set-Content -LiteralPath $pidFile -Value $tomcat.Id
for ($attempt = 0; $attempt -lt 40; $attempt++) {
    if (Test-Port) { break }
    if ($tomcat.HasExited) { throw "Tomcat đã dừng. Xem $webBase\stderr.log." }
    Start-Sleep -Milliseconds 500
}
if (!(Test-Port)) { throw "Tomcat chưa lắng nghe trên cổng $webPort." }
Write-Output "Web: http://127.0.0.1:$webPort/OnlineSupermarket3/"
