# MySQLルートユーザのパスワードを変更するPowerShellスクリプト

function LogInfo([String]$Message)
{
    $Message = (Get-Date -format s) + ": " + $Message
    Write-Host $Message -ForegroundColor Green
}
function LogError([String]$Message)
{
    $Message = (Get-Date -format s) + ": " + $Message
    Write-Host $Message -ForegroundColor Red
}
function LogWarn([String]$Message)
{
    $Message = (Get-Date -format s) + ": " + $Message
    Write-Host $Message -ForegroundColor Yellow
}
function LogTrace([String]$Message)
{
    if ($null -eq $env:VERBOSE -or $env:VERBOSE -eq "true") {
        $Message = (Get-Date -format s) + ": " + $Message
        Write-Host $Message -ForegroundColor Blue
    }
}

function LaunchProcess([string]$module, [String[]]$arg, [String]$working_dir)
{
    $pinfo = New-Object System.Diagnostics.Process
    $pinfo.StartInfo.FileName = $module
    $pinfo.StartInfo.Arguments = $arg
    $pinfo.StartInfo.UseShellExecute = $false
    $pinfo.StartInfo.CreateNoWindow = $true
    $pinfo.StartInfo.UseShellExecute = $false
    $pinfo.StartInfo.WorkingDirectory = $working_dir
    $pinfo.StartInfo.RedirectStandardOutput = $true
    $pinfo.StartInfo.RedirectStandardError = $true

    # Adding event handers for stdout and stderr.
    $sScripBlock = {
        if (! [String]::IsNullOrEmpty($EventArgs.Data))
        {
            $Event.MessageData.AppendLine($EventArgs.Data)
        }
    }

    $stdOutBuilder = New-Object -TypeName System.Text.StringBuilder
    $stdErrBuilder = New-Object -TypeName System.Text.StringBuilder

    $stdOutEvent = Register-ObjectEvent -InputObject $pinfo -Action $sScripBlock -EventName 'OutputDataReceived' -MessageData $stdOutBuilder
    $stdErrEvent = Register-ObjectEvent -InputObject $pinfo -Action $sScripBlock -EventName 'ErrorDataReceived'  -MessageData $stdErrBuilder

    LogTrace "Working direcotry: $($pinfo.StartInfo.WorkingDirectory)"
    LogTrace "$($pinfo.StartInfo.FileName) $($pinfo.StartInfo.Arguments)"

    # Starting process.
    [Void]$pinfo.Start()
    $pinfo.BeginOutputReadLine()
    $pinfo.BeginErrorReadLine()

    $process = New-Object -TypeName PSObject -Property (
        [Ordered]@{
            "ProcessInfo"     = $pinfo;
            "StdOutBuilder"   = $stdOutBuilder;
            "StdErrBuilder"   = $stdErrBuilder;
            "StdOutEvent"     = $stdOutEvent;
            "StdErrEvent"     = $stdErrEvent;
        })

    return $process
}

function JoinProcess($process, [Ref][Int32]$code)
{
    try {
        if (($process.ProcessInfo.WaitForExit()) -eq $False)
        {
            LogError "<Fatal Error> Process is dead somehow."
        }

        Unregister-Event -SourceIdentifier $process.StdOutEvent.Name
        Unregister-Event -SourceIdentifier $process.StdErrEvent.Name

        $code.Value = [Int32]($process.ProcessInfo.ExitCode)

        LogTrace "$($process.StdOutBuilder.ToString().Trim())"
        LogTrace "$($process.StdErrBuilder.ToString().Trim())"
        LogTrace "synchronized.($($process.ProcessInfo.ExitCode)) [$($process.ProcessInfo.ExitTime - $process.ProcessInfo.StartTime)] [$($process.ProcessInfo.StartInfo.FileName) $($process.ProcessInfo.StartInfo.Arguments)]"

      } finally {
        $process.ProcessInfo.Dispose()
      }
}

function JoinProcessWithStdOut($process, [Ref][Int32]$code, [Ref][String]$stdout)
{
    try {
        if (($process.ProcessInfo.WaitForExit()) -eq $False)
        {
            LogError "<Fatal Error> Process is dead somehow."
        }

        Unregister-Event -SourceIdentifier $process.StdOutEvent.Name
        Unregister-Event -SourceIdentifier $process.StdErrEvent.Name

        $code.Value = [Int32]($process.ProcessInfo.ExitCode)

        $stdout.Value = $process.StdOutBuilder.ToString().Trim()
        LogTrace "$($process.StdOutBuilder.ToString().Trim())"
        LogTrace "$($process.StdErrBuilder.ToString().Trim())"
        LogTrace "synchronized.($($process.ProcessInfo.ExitCode)) [$($process.ProcessInfo.ExitTime - $process.ProcessInfo.StartTime)] [$($process.ProcessInfo.StartInfo.FileName) $($process.ProcessInfo.StartInfo.Arguments)]"

      } finally {
        $process.ProcessInfo.Dispose()
      }
}

function ChangePassword {
    param (
        [ref]$ret
    )
    $arguments=@("-u", "root", "-e", "`"SELECT 'Connected';`"")
    $process = LaunchProcess -module "mysql" -arg $arguments -working_dir (Get-Location)
    $code=0
    $stdout=""
    JoinProcessWithStdOut $process ([ref]$code) ([ref]$stdout)
    if ($code -ne 0) {
        LogError "Failed to mysql connected check. exit code:$($code)"
        $ret.Value = $code
        return
    }
    if ($stdout -match "Connected") {
        $arguments=@("-u", "root", "password", "$($env:MYSQL_ROOT_PASSWORD)")
        $process = LaunchProcess -module "mysqladmin" -arg $arguments -working_dir (Get-Location)
        $code=0
        JoinProcess $process ([ref]$code)
        if ($code -ne 0) {
            LogError "Failed to mysqladmin password change. exit code:$($code)"
            $ret.Value = $code
            return
        }
        LogInfo "MySQL root user password changed successfully."
    } else {
        LogError "Failed to connect to MySQL with the provided password."
        $ret.Value = 1
        return
    }
}

function ChangePriviles {
    param (
        [ref]$ret
    )
    $arguments=@("-u", "root", "-p$($env:MYSQL_ROOT_PASSWORD)", "-e" , "`"CREATE USER 'root'@'%' IDENTIFIED BY '$($env:MYSQL_ROOT_PASSWORD)';GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;FLUSH PRIVILEGES;`"")
    $process = LaunchProcess -module "mysql" -arg $arguments -working_dir (Get-Location)
    $code=0
    JoinProcess $process ([ref]$code)
    if ($code -ne 0) {
        LogError "Failed to mysql privileges change. exit code:$($code)"
        $ret.Value = $code
        return
    }
    LogInfo "MySQL root user privileges changed successfully."
}

function Main([ref] $ret) {
    $ret.Value = 0

    # check if this is a first time installation
    $first_time = $false
    if ($null -eq $env:MYSQL_FIRST_TIME_INSTALLATION -or $env:MYSQL_FIRST_TIME_INSTALLATION -eq "true") {
        $first_time = $true
    }

    if ($first_time) {
        # stop MySQL Service
        $service = Get-Service -Name "MySQL" -ErrorAction SilentlyContinue
        if ($null -ne $service) {
            Stop-Service -Name "MySQL"
            LogInfo "MySQL Service stopped."
        }

        # wait for MySQL Service stop
        $service = Get-Service -Name "MySQL" -ErrorAction SilentlyContinue
        while ($service.Status -eq "Running") {
            Start-Sleep -Seconds 1
            $service = Get-Service -Name "MySQL" -ErrorAction SilentlyContinue
        }

        # stop mysqld process
        $process = Get-Process -Name "mysqld" -ErrorAction SilentlyContinue
        if ($null -ne $process) {
            Stop-Process -Name "mysqld" -Force
            LogInfo "mysqld process stopped."
        }

        # wait for mysqld process stop
        $process = Get-Process -Name "mysqld" -ErrorAction SilentlyContinue
        while ($null -ne $process) {
            Start-Sleep -Seconds 1
            $process = Get-Process -Name "mysqld" -ErrorAction SilentlyContinue
        }

        # delete files in C:\ProgramData\MySQL\data
        $data_dir = "C:ProgramData\MySQL\data"
        if (Test-Path $data_dir) {
            Get-ChildItem $data_dir -Recurse | Remove-Item -Force -Recurse
            LogInfo "Deleted files in $data_dir"
        }

        # mysql initialize
        $arguments=@("--initialize-insecure", "--console")
        $process = LaunchProcess -module "mysqld" -arg $arguments -working_dir (Get-Location)
        $code=0
        JoinProcess $process ([ref]$code)
        if ($code -ne 0) {
            LogError "Failed to mysql initialize. exit code:$($code)"
            $ret.Value = $code
            return
        }
        LogInfo "MySQL initialized successfully."

        # start MySQL Service
        Start-Service -Name "MySQL"
        LogInfo "MySQL Service started."

        if ($env:MYSQL_ROOT_PASSWORD) {
            ChangePassword ([ref]$ret)
            if ($ret.Value -ne 0) {
                LogError "Failed to ChangePassword.($($ret.Value))"
                return
            }
            ChangePriviles ([ref]$ret)
            if ($ret.Value -ne 0) {
                LogError "Failed to ChangePriviles.($($ret.Value))"
                return
            }
        }
        # set environment variable
        [Environment]::SetEnvironmentVariable("MYSQL_FIRST_TIME_INSTALLATION", "false", "User")
    }

    LogInfo "MySQL is running."
    while ($true) {
        Start-Sleep -Seconds 2147483
    }
}

LogInfo "===start==="
$ret = 0
try {
    Main ([ref]$ret)
}
catch [Exception] {
    $ret=1
    LogError "Exception occurs. msg=$($_.Exception.Message)"
}
LogInfo "End with result code: $($ret)"
LogInfo "===end==="
exit $ret
