<#
.SYNOPSIS
    This script is intended to receive an ingest CSV from Fantrax Fantasy Baseball, find each player in Fangraphs, and output defined baseball statistics.

.DESCRIPTION
    Provide a more detailed description of the script.

.PARAMETER Param1
    Parameter 1 should be the player position of the input file; batter or pitcher

.PARAMETER Param2
    Parameter 2 is should be the CSV export from Fantrax.

.EXAMPLE
    .\player-projections.ps1 batter .\fantrax-export.csv
    .\player-projections.ps1 pitcher .\fantrax-export.csv


.NOTES
    Additional information about the script.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Provide the player position.")]
    [ValidateNotNullOrEmpty()]
    [string]$position,

    [Parameter(Mandatory = $true, HelpMessage = "Provide the path of the import file.")]
    [ValidateNotNullOrEmpty()]
    [string]$playerImportFileLocation
)

begin {
    # Start the log file as early as possible.
    $logFilePath = "$PSCommandPath.LastRun.csv"
    Add-Content -Path $logFilePath -Value "TimeStamp;ErrorType;ErrorMessage"

    function Write-Log {
        param (
            [string]$ErrorType,
            [string]$ErrorMessage
        )
        $timeStamp = (Get-Date).ToString('u')
        $logEntry = "$timeStamp;$ErrorType;$ErrorMessage"
        Add-Content -Path $logFilePath -Value $logEntry
    }

    function Log-Information {
        param (
            [string]$Message
        )
        Write-Log -ErrorType "Information" -ErrorMessage $Message
    }

    function Log-Warning {
        param (
            [string]$Message
        )
        Write-Log -ErrorType "Warning" -ErrorMessage $Message
    }

    function Log-Error {
        param (
            [string]$Message
        )
        Write-Log -ErrorType "Error" -ErrorMessage $Message
    }

    function Get-PlayerInfo {
        param (
            $player
        )
    
        $baseData = @{
            "Name"        = $player.Player
            "Position"    = $player.Position
            "MLBTeam"     = $player.Team
            "FantasyTeam" = $player.Status
            "Age"         = $player.Age
        }
    
        if ($position -eq "pitcher") {
            $fanGraphsPlayer = $pitchers | Where-Object { $_.PlayerName -eq $player.Player }
            
            $pitcherData = @{
                "K/BB%" = $fanGraphsPlayer."K-BB%"
                "IP"    = $fanGraphsPlayer.IP
                "ERA"   = $fanGraphsPlayer.ERA
                "WHIP"  = $fanGraphsPlayer.WHIP
            }
    
            $playerData = $baseData + $pitcherData
        }
        else {
            $fanGraphsPlayer = $batters | Where-Object { $_.PlayerName -eq $player.Player }

            $stolenBasePercentage = ([int]$fanGraphsPlayer.SB / ([int]$fanGraphsPlayer.SB + [int]$fanGraphsPlayer.CS)) * 100
    
            $batterData = @{
                "OPS"  = $fanGraphsPlayer.OPS
                "K%"   = $fanGraphsPlayer."K%"
                "BB%"  = $fanGraphsPlayer."BB%"
                "Runs" = $fanGraphsPlayer.R
                "RBIs" = $fanGraphsPlayer.RBI
                "SB%"  = $stolenBasePercentage
                "OBP"  = $fanGraphsPlayer.OBP
                "SLG"  = $fanGraphsPlayer.SLG
            }
            $playerData = $baseData + $batterData
        }
        return New-Object PSObject -Property $playerData

        $InformationPreference = 'Continue'

        # Display the time that this script started running.
        [DateTime] $startTime = Get-Date
        Log-Information -Message "Starting script at '$($startTime.ToString('u'))'."
    }
}

process {
    try {
        Log-Information -Message "Processing script code."

        Write-Host "Pulling data from Fangraphs"
        #fangraphs batters
        $battersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=bat&pos=all'
        $batters = Invoke-RestMethod -Uri $battersUrl -Method Get

        #fangraphs pitchers
        $pitchersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=pit&pos=all'
        $pitchers = Invoke-RestMethod -Uri $pitchersUrl -Method Get

        #imported file
        $playerImport = Import-Csv $playerImportFileLocation

        Write-Host "Processing $position file"
        $playerCollection = [System.Collections.Generic.List[object]]::new()
        foreach ($player in $playerImport) {
            $playerInfo = Get-PlayerInfo $player
            $playerCollection.Add($playerInfo)
        }

        if ($position -eq "pitcher") {
            $playerCollection | Select-Object Name, Position, MLBTeam, FantasyTeam, Age, "K/BB%", IP, ERA, WHIP | Export-Csv playerdata.csv -NoTypeInformation
        }
        else {
            $playerCollection | Select-Object Name, Position, MLBTeam, FantasyTeam, Age, OPS, "K%", "BB%", Runs, RBIs, "SB%", OBP, SLG | Export-Csv playerdata.csv -NoTypeInformation
        }
    }

    catch {
        Log-Error -Message $_.Exception.Message
    }
}

end {
    # Display the time that this script finished running, and how long it took to run.
    [DateTime] $finishTime = Get-Date
    [TimeSpan] $elapsedTime = $finishTime - $startTime
    Log-Information -Message "Finished script at '$($finishTime.ToString('u'))'. Took '$elapsedTime' to run."
}