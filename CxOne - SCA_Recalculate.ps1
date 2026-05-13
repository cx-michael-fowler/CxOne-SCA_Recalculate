Using Module .\CxOneAPIModule
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#region Help

<#
.Synopsis
Script to find all scan where the SCA Recalculate is needed and kick off the process

.Description
Loops through all projects, retrieves the last scan and where the 

Usage
Help
    .\CxOne - SCA_Recalculate.ps1 -help [<CommonParameters>]

Recalculate
    .\CxOne - SCA_Recalculate.ps1 [-all] [-silentLogin -apiKey <string>] [<CommonParameters>]
    

.Notes
Version:     1.0
Date:        13/05/2026
Written by:  Michael Fowler
Contact:     michael.fowler@checkmarx.com

Change Log
Version    Detail
-----------------
1.0        Original version

  
.PARAMETER help
Display help

.PARAMETER silentLogin
Log into Checkmarx One using the provided API Key. Is optional and if not used a prompt will appear for the key

.PARAMETER apiKey
The API Key used to log into Checkamrx One. Is mandatory with silentLogin

.PARAMETER all
Forces the recalculate to run on the last scan for every project and not just those listed as requiring recalculation


#>

#endregion
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#region Parameters

[CmdletBinding(DefaultParametersetName='Help')] 
Param (

    [Parameter(ParameterSetName='Help',Mandatory=$false, HelpMessage="Display help")]
    [switch]$help,

    [Parameter(ParameterSetName='CxOne',Mandatory=$false,HelpMessage="Logon silently using provided API Key")]
    [switch]$silentLogin,

    [Parameter(ParameterSetName='CxOne',Mandatory=$false,HelpMessage="Run recalculation on all scans")]
    [switch]$all

)

#endregion
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#region Dynamic Parameters

DynamicParam {
    if ($silentLogin) {
        # Define parameter attributes
        $paramAttributes = New-Object -Type System.Management.Automation.ParameterAttribute
        $paramAttributes.Mandatory = $true
        $paramAttributes.HelpMessage = "The API Key used to login"

        # Create collection of the attributes
        $paramAttributesCollect = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $paramAttributesCollect.Add($paramAttributes)

        # Create parameter with name, type, and attributes
        $dynParam = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("apiKey", [string], $paramAttributesCollect)

        # Add parameter to parameter dictionary and return the object
        $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("apiKey", $dynParam)
        return $paramDictionary
    }
}

#endregion
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#region Begin

Begin {
    
    Import-Module $PSScriptRoot\CxOneAPIModule
    $apiKey = $PSBoundParameters['apiKey']
}

#endregion
#--------------------------------------------------------------------------------------------------------------------------------------------------------------
#region Process

Process {

    #Display help if called
    if ($help -OR -NOT($logPath -XOR $scanId)) {
        Get-Help $MyInvocation.InvocationName -Full | Out-String
        exit
    }

    Write-Host "=========="
    $start = Get-Date
    Write-Host "Processing Started at $(Get-Date -Format "HH:mm:ss")"

    Write-Host "Logging onto Checkmarx One"
    if ($silentLogin) { $conn = New-SilentConnection $apiKey }
    else { $conn = New-Connection }
    Write-Host "Login completed"

    Write-Host "Retrieving Projects"
    $projects = Get-AllProjects $conn
    Write-Host "Projects Retrived"

    Write-Host "Retrieving Scans"
    $scans = Get-LastScans $conn $projects   
    # Filter results if not all flag set
    if (-Not $all) { $scans = $scans.values | Where-Object { if ($_) { $_.RecalcStatus.Contains("needRecalc_sca")} }}
    else { $scans = $scans.values }
    Write-Host "Scans Retrived"

    $count = 0
    if ($scans) { $count = $scans.Count }
    Write-Host "Running recalculation on $count scans"
    $uri = "$($conn.BaseURI)/api/scans/recalculate"
    Foreach ($s in $scans) {
        if (($null -eq $s) -Or (-Not $s.EnginesString.Contains("sca"))) { continue }
        $body = @{
            project_id = $s.ProjectId 
            branch = $s.Branch
            engines = @("sca")
        } | ConvertTo-Json
        ApiCall { Invoke-RestMethod -Uri $uri -Method POST -Headers $conn.Headers -Body $body -UseBasicParsing } $conn | Out-Null
    }
    Write-Host "SCA recalculation completed. Please check Scans under Resource Management for status"
        
    $end = Get-Date
    $runtime = (New-TimeSpan –Start $start –End $end).ToString("hh\:mm\:ss")
    Write-Host "Processing Completed at $(Get-Date -Format "HH:mm:ss") with a runtime of $runtime"
    Write-Host "=========="
}

#endregion
#--------------------------------------------------------------------------------------------------------------------------------------------------------------