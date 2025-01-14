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
    function Get-PlayerId {
        param (
            $player
        )
        ($playerMap | Where-Object { $_.FANTRAXID -eq $player.ID }).IDFANGRAPHS
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
    }
}

process {
    try {
        Write-Host "Pulling data from Fangraphs"
        #fangraphs batters
        $battersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=bat&pos=all'
        $batters = Invoke-RestMethod -Uri $battersUrl -Method Get

        #fangraphs pitchers
        $pitchersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=pit&pos=all&team=0&players=0&lg=all&z=1736762720'
        $pitchers = Invoke-RestMethod -Uri $pitchersUrl -Method Get

        #playerMap
        $playerMap = Import-Csv -Path playerMap.csv

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