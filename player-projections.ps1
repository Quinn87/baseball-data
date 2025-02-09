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

function Get-PlayerPosition {

    Write-Host "Select Player Position for Comparison"
    Write-Host "1. Pitchers"
    Write-Host "2. Hitters"
    Write-Host "3. Both"

    do {
        [int]$userInput = Read-Host "Selection"
    } 
    while (
            ($userInput -gt 3) -or ($userInput -lt 0) -or ($userInput -eq "")
    )
    return $userInput
}
function Select-fxTeam {
    param (
        $teamList
    )

    foreach ($team in $teamList) {
        Write-Host "$($team.optionNumber). $($Team.teamName)"
    }
    do {
        Write-Host ""
        [int]$userInput = Read-Host "Selection"
    } while (
        ($userInput -gt $teamList.count) -or ($userInput -le 0) -or ($userInput -eq "") 
    )
    $teamId = $teamList[($userInput - 1)].teamId 
    return $teamId
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
            "Win"   = $fanGraphsPlayer.W
            "Loss"  = $fanGraphsPlayer.L
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

function Get-PlayerInfo {
    param (
        $mlbId
    )

    $mlbUrl = "https://statsapi.mlb.com/api/v1/people/$mlbId"

    $mlbResponse = (Invoke-RestMethod -Uri $mlbUrl -Method Get).people
    
    [PSCustomObject]$playerInfo = @{
        Name     = $mlbResponse.fullName
        Position = $mlbResponse.primaryPosition.abbreviation
        Age      = $mlbResponse.currentAge
    }

    return $playerInfo
}

function Get-PitcherData {
    param (
        $player
    )
    
    $fanGraphsPlayer = $pitchers | Where-Object { $_.playerid -eq $player.id }
            
    $pitcherData = @{
        "K/BB%" = $fanGraphsPlayer."K-BB%"
        "IP"    = $fanGraphsPlayer.IP
        "ERA"   = $fanGraphsPlayer.ERA
        "WHIP"  = $fanGraphsPlayer.WHIP
        "Win"   = $fanGraphsPlayer.W
        "Loss"  = $fanGraphsPlayer.L
        "Saves" = $fanGraphsPlayer.SV
        "Holds" = $fanGraphsPlayer.HLD
    }

    return $pitcherData
}
function Get-HitterData {
    param (
        $playerId
    )
    
}
try {

    #Add League Id
    $leagueId = Read-Host "Enter Fantrax League ID"
    $fantraxUrl = "https://www.fantrax.com/fxea/general/getTeamRosters?leagueId=$leagueId"

    #Gather Fantrax data from API
    $fxData = (Invoke-RestMethod -Uri $fantraxUrl -Method Get -ContentType 'application/json').rosters

    if ($fxData) {
        [array]$fxTeamIds = $fxData | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

        Write-Host "Pulling data from Fangraphs"
        #fangraphs batters
        $battersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=bat&pos=all'
        $global:batters = Invoke-RestMethod -Uri $battersUrl -Method Get
    
        #fangraphs pitchers
        $pitchersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=pit&pos=all'
        $global:pitchers = Invoke-RestMethod -Uri $pitchersUrl -Method Get
    
        #playerMap
        $playerMap = Import-Csv -Path playerMap.csv    
    }
    else {
        Write-Host "League not found"
        exit
    }

    $i = 1
    $teamList = foreach ($fxTeamId in $fxTeamIds) {
        [PSCustomObject]@{
            optionNumber = $i
            teamId       = $fxTeamId
            teamName     = $fxData.$fxTeamId.teamName
        }
        $i++
    }

    #Ask user to select teams for comparison
    $fxTeamsSelection = [System.Collections.Generic.List[string]]::new()
    $i = 1
    do {
        Write-Host "Select Team $i" -ForegroundColor Red
        $teamId = Select-fxTeam $teamList
        $fxTeamsSelection.Add($teamId)
        $i++
        Write-host ""
        $userInput = Read-Host "Would you like to add another team?"
        Write-host ""
    } while (
           ( $userInput -eq "yes") -or ($userInput -eq "y")
    )

    $pitcherList = [System.Collections.Generic.List[string]]::new()
    $hitterList = [System.Collections.Generic.List[string]]::new()

    foreach ($fxTeam in $fxTeamsSelection) {
        #Get team roster by player ID
        $fxRoster = $fxData.$fxTeam.rosterItems

        foreach ($fxPlayer in $fxRoster) {
            $playerId = $playerMap | Where-Object { $_.FANTRAXID -eq "*$($fxPlayer.id)*" } | Select-Object IDFANGRAPHS, MLBID

            $baseData = Get-PlayerInfo $playerId.MLBID

            if (($fxPlayer.position -eq "SP") -or ($fxPlayer.position -eq "RP")) {
                $pitcherData = Get-PitcherData $playerId.IDFANGRAPHS
                $playerInfo = $baseData + $playerInfo
            }
            else {
                $hitterData = Get-HitterData $playerId.IDFANGRAPHS
                $playerInfo = $baseData + $hitterData
            }

            $playerCollection.Add($playerInfo)
        }
    }

    Write-Host "Processing $position file"
    $playerCollection = [System.Collections.Generic.List[object]]::new()
    foreach ($player in $playerImport) {
        $playerId = Get-PlayerId $player.id
        $playerInfo = Get-PlayerInfo $playerId
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