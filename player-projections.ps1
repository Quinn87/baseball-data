function Get-PlayerInfo {
    param (
        $player
    )
    switch -Wildcard ($player.Position) {
        "*P*" { $position = "pitcher" }
        Default { $position = "batter" }
    }

    $baseData = @{
        "Name"        = $player.Player
        "Position"    = $player.Position
        "MLBTeam"     = $player.Team
        "fantasyTeam" = $player.Status
        "Age"         = $player.Age
    }

    if ($position -eq "pitcher") {
        Write-Host "$($player.player) is a pitcher"
        $fanGraphsPlayer = $pitchers | Where-Object { $_.PlayerName -eq $player.Player }
        
        $pitcherData = @{
            "K-BB%"     = $fanGraphsPlayer."K-BB%"
            "IP"          = $fanGraphsPlayer.IP
            "ERA"         = $fanGraphsPlayer.ERA
            "WHIP"        = $fanGraphsPlayer.WHIP
        }

        $playerData = $baseData + $pitcherData
    }
    else {
        Write-Host "$($player.player) is a batter"
        $fanGraphsPlayer = $batters | Where-Object { $_.PlayerName -eq $player.Player }

        $stolenBasePercentage = ($fanGraphsPlayer.SB/($fanGraphsPlayer.SB + $fanGraphsPlayer.CS)) * 100

        $batterData = @{
            "OPS" = $fanGraphsPlayer.OPS
            "K%" = $fanGraphsPlayer."K%"
            "BB%"= $fanGraphsPlayer."BB%"
            "Runs" = $fanGraphsPlayer.Runs
            "RBI" = $fanGraphsPlayer.RBI
            "SB%" = $stolenBasePercentage
            "OBP" = $fanGraphsPlayer.OBP
            "SLG" = $fanGraphsPlayer.SLG
        }
        $playerData = $baseData + $batterData
    }
    return New-Object PSObject -Property $playerData
}

#imported file
$playerImport = Import-Csv -Path '.\import\Fantrax-Players-Dynasty Year 3.csv'

#fantrax batters
$battersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=bat&pos=all'
$batters = Invoke-RestMethod -Uri $battersUrl -Method Get

#fantrax pitchers
$pitchersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=pit&pos=all'
$pitchers = Invoke-RestMethod -Uri $pitchersUrl -Method Get

$mlbPlayers = [System.Collections.Generic.List[object]]::new()

foreach ($player in $playerImport) {
    $fgPlayer = Get-PlayerInfo $player
    $mlbPlayers.Add($fgPlayer)
}

$mlbPlayers | Select-Object Name,Position,MLBTeam,fantasyTeam,Age | ft