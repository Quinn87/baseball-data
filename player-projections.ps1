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

#TODO:
# Choose Teams to compare
# Selection for free agents to compare

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "How many player files will be imported?")]
    [ValidateNotNullOrEmpty()]
    [Int]$fileImportCount,

    [Parameter(Mandatory = $true, HelpMessage = "Provide a name for the outputted CSV.")]
    [ValidateNotNullOrEmpty()]
    [string]$outputFileName
)

begin {
    $fantraxUrl = "https://www.fantrax.com/fxea/general/getTeamRosters?leagueId=aczg2kyzm32ycqh6"

    function Get-PlayerPosition {

        Write-Host "Select Player Position for Comparison"
        Write-Host "1. Pitchers"
        Write-Host "2. Hitters"

        do {
            [int]$userInput = Read-Host "Selection"
        } 
        while (
            ($userInput -gt 2) -or ($userInput -lt 0) -or ($userInput -eq "")
        )
    }

    function Join-Files {
        param (
            $fileImportCount
        )

        if ($fileImportCount -gt 0) {

            $filesToImport = [Collections.Generic.List[string]]::new()

            for ($i = 1; $i -le $fileImportCount; $i++) {
                do {
                    $fileToImport = Read-Host "Provide path to CSV to upload for file number $i"
                } while (
                    $fileToImport -notlike "*.csv"
                )
                $filesToImport.Add($fileToImport)
            }

            $playerList = foreach ($file in $filesToImport) { 
                Import-Csv $file
            }
        }
        return $playerList
    }
    function Get-PlayerId {
        param (
            $player
        )
        $fanGraphsPlayerID = ($playerMap | Where-Object { $_.FANTRAXID -eq $player.ID }).IDFANGRAPHS
        return $fanGraphsPlayerID
    }
    function Get-PlayerInfo {
        param (
            $player,
            $playerId
        )
    
        $baseData = @{
            "Name"        = $player.Player
            "Position"    = $player.Position
            "MLBTeam"     = $player.Team
            "FantasyTeam" = $player.Status
            "Age"         = $player.Age
        }
    
        if ($position -eq "pitcher") {
            $fanGraphsPlayer = $pitchers | Where-Object { $_.playerid -eq $playerId }
            
            $pitcherData = @{
                "K/BB%" = $fanGraphsPlayer."K-BB%"
                "IP"    = $fanGraphsPlayer.IP
                "ERA"   = $fanGraphsPlayer.ERA
                "WHIP"  = $fanGraphsPlayer.WHIP
                "Win" = $fanGraphsPlayer.W
                "Loss" = $fanGraphsPlayer.L
                "Saves" = $fanGraphsPlayer.SV
                "Holds" = $fanGraphsPlayer.HLD
            }
    
            $playerData = $baseData + $pitcherData
        }
        else {
            $fanGraphsPlayer = $batters | Where-Object { $_.playerid -eq $playerId }

            $batterData = @{
                "OPS"   = $fanGraphsPlayer.OPS
                "PA"    = $fanGraphsPlayer.PA
                "Games" = $fanGraphsPlayer.G
                "K%"    = $fanGraphsPlayer."K%"
                "BB%"   = $fanGraphsPlayer."BB%"
                "Runs"  = $fanGraphsPlayer.R
                "RBIs"  = $fanGraphsPlayer.RBI
                "SB"    = $fanGraphsPlayer.SB
                "CS"    = $fanGraphsPlayer.CS
                "OBP"   = $fanGraphsPlayer.OBP
                "SLG"   = $fanGraphsPlayer.SLG
            }
            $playerData = $baseData + $batterData
        }
        return New-Object PSObject -Property $playerData
    }
}

process {
    try {

        $fxData = (Invoke-RestMethod -Uri $fantraxUrl -Method Get -ContentType 'application/json').rosters
        [array]$fxTeams = $fxData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    
        $playerImport = Join-Files $fileImportCount

        Write-Host "Pulling data from Fangraphs"
        #fangraphs batters
        $battersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=bat&pos=all'
        $global:batters = Invoke-RestMethod -Uri $battersUrl -Method Get

        #fangraphs pitchers
        $pitchersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=pit&pos=all'
        $global:pitchers = Invoke-RestMethod -Uri $pitchersUrl -Method Get

        #playerMap
        $playerMap = Import-Csv -Path playerMap.csv

        Write-Host "Processing $position file"
        $playerCollection = [System.Collections.Generic.List[object]]::new()
        foreach ($player in $playerImport) {
            $playerId = Get-PlayerId $player
            $playerInfo = Get-PlayerInfo $player $playerId
            $playerCollection.Add($playerInfo)
        }

        if ($position -eq "pitcher") {
            $playerCollection | Select-Object Name, Position, MLBTeam, FantasyTeam, Age, "K/BB%", IP, ERA, WHIP, Win, Loss, Saves, Holds | Sort-Object "K/BB%" -Descending | Export-Csv ./output/$outputFileName.csv -NoTypeInformation
        }
        else {
            $playerCollection | Select-Object Name, Position, MLBTeam, FantasyTeam, Age, OPS, PA, Games, "K%", "BB%", Runs, RBIs, SB, CS, OBP, SLG | Sort-Object OBP -Descending | Export-Csv ./output/$outputFileName.csv -NoTypeInformation
        }
    }
    catch {
        $_.Exception.Message
    }
}