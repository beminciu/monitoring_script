# ====================================================================

# DTOC MONITORING MADE EASIER
 
# ====================================================================
 
  # Created by: Benjaminas Bilevicius
  # Date: 2019-02-15
  #
  #

<#

        .Synopsis
            Script for easier monitoring.
        .DESCRIPTION
            Script contains multiple functions which when invoked returns data from servers.
        .PARAMETER Computername
    #>


    Write-Host "Available functions" -ForegroundColor Yellow
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "Push-CCM-Actions"
    Write-Host "Find-Unexpected-Shutdown"
    Write-Host "Get-Service-Status"
    Write-Host "Get-Disk-UID"
    Write-Host "Show-Timestamps"
    Write-Host "Get-Cluster-Status"
    Write-Host "Start-Cluster-Resource"
    Write-Host "Get-LoggedIn-Users"
    Write-Host "Show-IIS-Pools-Sites"
    Write-Host "Start-IIS-Pool-Or-Site"
    Write-Host "Restart-Monitoring-Service"
    Write-Host "Get-Uptime"
    Write-Host ""
    Write-Host ""
    Write-Host ""
        

function Push-CCMActions # Triggers CCM actions in configuration manager on server side.
{

        PARAM(
            [Parameter(Mandatory=$true)]
            [string]$computer
            
        )    

            {
            Write-Host "Copying file to remote server..." -ForegroundColor DarkCyan
                robocopy C:\temp "\\$computer\c$\temp" Trigger-CCMActions.ps1 /tee
                    Invoke-Command -ComputerName $computer -ScriptBlock {powershell c:\temp\Trigger-CCMActions.ps1}
            write-host "Done." -ForegroundColor Green
            }
}

function Find-UnexpectedShutdown # Looks at system logs for event related to shutdown / restart.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
        )

            {
            write-host "Looking for reason why unexpected system shutdown occured" -ForegroundColor DarkCyan
                Invoke-Command -ComputerName $computer -ScriptBlock {Get-EventLog -LogName system -Source user32 -Newest 3 | Format-Table -wrap}
            write-host "Done." -ForegroundColor Green
            }

}

function Get-ServiceStatus # Provides state of the service on server.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )

        {
        $ser = Read-Host $service
        write-host "Checking service status..." -ForegroundColor DarkCyan
            Invoke-command -ComputerName $computer  -ArgumentList $ser -ScriptBlock {$r = Get-Service; $r | Select-Object Name,DisplayName, Status | where-object name -like "*$args*" | format-table}
        write-host "Done." -ForegroundColor Green
        }

}

function Get-DiskUID # Provides information about disks on the server and shows their Unique ID number and size in GB.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )

        {
        write-host "Getting Disks information" -ForegroundColor DarkCyan
        Invoke-Command -ComputerName $computer -ScriptBlock {
            get-disk | Select-Object Number, FriendlyName, Model,Manufacturer,SerialNumber, UniqueId,@{name="Size (GB)";e={$_.Size/1073741824}}| Sort-Object -Property Number | Format-Table }
        write-host "Done." -ForegroundColor Green
        }
}

function Show-Timestamps # Looks in the registries of the server for SCCM and CHEF timestamps.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )
        {
        write-host "Checking timestamp dates in registry..." -ForegroundColor DarkCyan
        Invoke-Command -ComputerName $computer -ScriptBlock{
            REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\DanskeBank\Agent Status" /v "*SCCM*"
            REG QUERY "HKEY_LOCAL_MACHINE\SOFTWARE\DanskeBank\Agent Status" /v "*Chef*"}
        write-host "Done." -ForegroundColor Green

        }
}

function Get-ClusterStatus # Provides information about overall cluster health state and states of cluster resources.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )

            {
		
        write-host "Checking cluster status..." -ForegroundColor DarkCyan
        Invoke-Command -ComputerName $computer -ScriptBlock{
        
            $r = Get-ClusterResource | format-table | out-string
            foreach ($line in $($r -split "`r`n"))
            {
                foreach($col in $($line -split " ")){
                    if($col -like "*online*") {
                        write-host "$col " -ForegroundColor Green -nonewline
                    } elseif($col -like "*offline*"){
                        write-host "$col " -ForegroundColor Red -nonewline
                    }else {
                        write-host "$col " -ForegroundColor White -nonewline
                    }
                }
                write-host
            } 
            
            $r = Get-ClusterNode | format-table | out-string
            foreach ($line in $($r -split "`r`n"))
            {
                foreach($col in $($line -split " ")){
                    if($col -like "*Up*") {
                        write-host "$col " -ForegroundColor Green -nonewline
                    } elseif($col -like "*Down*"){
                        write-host "$col " -ForegroundColor Red -nonewline
                    }else {
                        write-host "$col " -ForegroundColor White -nonewline
                    }
                    
                    
                }
                write-host
            } 
            
            $r = Get-ClusterGroup | format-table | out-string
            foreach ($line in $($r -split "`r`n"))
            {
                foreach($col in $($line -split " ")){
                    if($col -like "*online*") {
                        write-host "$col " -ForegroundColor Green -nonewline
                    } elseif($col -like "*offline*"){
                        write-host "$col " -ForegroundColor Red -nonewline
                    }else {
                        write-host "$col " -ForegroundColor White -nonewline
                    }
                }
                write-host
            } 
            
        write-host "Done." -ForegroundColor Green
        }
            }
}

function Get-LoggedInUsers # Provides a list of users ID's who are connected or have a session left in the server.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )
        {
        write-host "Checking for logged in users..." -ForegroundColor DarkCyan
        $processinfo = @(Get-WmiObject -class win32_process -ComputerName $computer -EA "Stop")
            if ($processinfo)
                {
                $processinfo | Foreach-Object {$_.GetOwner().User} | 
                Where-Object {$_ -ne "NETWORK SERVICE" -and $_ -ne "LOCAL SERVICE" -and $_ -ne "SYSTEM" -and $_ -notlike "Default*" -and $_ -notlike "DWM*"} |
                Sort-Object -Unique
                write-host "Done." -ForegroundColor Green
                }
        }

}

function Show-IIS-PoolsSites # Shows all Application Pools and Web Sites with their current states on IIS in the server.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )
        {
        write-host "Checking IIS Pools and WebSites..." -ForegroundColor DarkCyan
        Invoke-Command -ComputerName $computer -ScriptBlock{
            Import-Module -Name WebAdministration
                write-host ""
                write-host ""
                write-host ""
                write-host "IIS Pools" -ForegroundColor Yellow
                            Get-ChildItem -Path IIS:\AppPools | format-table
                Write-Host "IIS WebSites" -ForegroundColor Yellow
                            Get-ChildItem -Path IIS:\Sites | format-table
                write-host ""
                write-host "Done." -ForegroundColor Green

                }
        }

            {
            write-host "Checking IIS Pools and WebSites..." -ForegroundColor DarkCyan
            Invoke-Command -ComputerName $computer -ScriptBlock{
                Import-Module -Name WebAdministration
                    write-host ""
                    write-host ""
                    write-host ""
                    write-host "IIS Pools" -ForegroundColor Yellow
                            Get-ChildItem �Path IIS:\AppPools | format-table
                    Write-Host "IIS WebSites" -ForegroundColor Yellow
                            Get-ChildItem �Path IIS:\Sites | format-table
                    write-host ""
                    write-host "Done." -ForegroundColor Green

                }
            }

}

function Restart-MonitoringService # Restarts Microsoft Monitoring Agent service.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )
        {
            
        Write-Host "Restarting healthservice..." -ForegroundColor DarkCyan
            Invoke-command -ComputerName $computer -ScriptBlock{
            Restart-Service -DisplayName *healthservice*
        Write-Host "Done." -ForegroundColor Green

            }

        }
}

function Start-ClusterResource # Tries to bring your entered cluster resource online.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )
        {
        $res = Read-Host "Full exact name of Cluster Resource"
        Write-Host "Starting chosen resource..." -ForegroundColor DarkCyan
            Invoke-command -ComputerName $computer -ArgumentList $res -ScriptBlock{
            Start-ClusterResource $args[0] | Format-Table
        Write-Host "Done." -ForegroundColor Green

            }
        }
}

function Start-IISPoolOrSite # Starts your provided Application Pool or Website on the server.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )
    
    {
        write-host "Start selected pool or website..." -ForegroundColor DarkCyan
        Invoke-Command -ComputerName $computer -ScriptBlock{
        Import-Module -Name WebAdministration
            write-host ""
            write-host ""
            write-host "IIS Pool to be started?" -ForegroundColor Yellow
            write-host ""
        $selection = Read-Host "Pool"
            Start-WebAppPool -name $selection
            write-host ""
            write-host "Done." -ForegroundColor Green
            write-host ""
            write-host "Do you want to start IIS Website also?" -ForegroundColor Yellow
            write-host ""
        $userinput = Read-Host "Yes / No" 
        If($userinput -match "yes") {
            $selection2 = Read-Host "Site"
            Start-Website -name $selection2
            write-host ""
            write-host "Done." -ForegroundColor Green
                }
        else {
            write-host ""
            write-host ""
            write-host "You chose not to start the site, returning to main menu..." -ForegroundColor Yellow
            }
        }
    }
}

function Get-Uptime # Shows last boot up time of the server.
{
    PARAM(
        [Parameter(Mandatory=$true)]
        [string]$computer
    )
        {
            
        Write-Host "Checking Uptime..." -ForegroundColor DarkCyan
            Invoke-command -ComputerName $computer -ScriptBlock{
            Get-WmiObject win32_operatingsystem | Select-Object @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-table
        Write-Host "Done." -ForegroundColor Green

            }
        }  
}