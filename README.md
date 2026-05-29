Powershell Script to run recalculate on SCA scans marked for Recalculation. 
Includes the option to run on all SCA scans with an optional filter to limit by days since the last scan

Usage

Help

    .\CxOne - SCA_Recalculate.ps1 -help [<CommonParameters>]

Recalculate

    .\CxOne - SCA_Recalculate.ps1 [-all [daysSinceScan <int>]] [-silentLogin -apiKey <string>] [<CommonParameters>]
