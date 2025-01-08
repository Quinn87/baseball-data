function Get-PlayerInfo {
    param (
        [array]$players
    )
    foreach ($player in $players) {
        $batters | Where-Object { $_.PlayerName -eq $player.Player }
    }
}

function Build-Database {
    param (
        $fantraxPlayerDatabase,
        $batters,
        $pitchers
    )
    foreach ($player in $fantraxPlayerDatabase) {
        [PSCustomObject]$playerData = @{
            Name        = $player.Player
            Position    = $player.Position
            MLBTeam     = $player.Team
            fantasyTeam = $player.Status
            Age         = $player.Age
        }

        switch -Wildcard ($player.Position) {
            "*P*" { $position = "pitcher" }
            Default { $position = "batter" }
        }

        if ($position -eq "pitcher") {
            $fanGraphsPlayer = $pitchers | Where-Object { $_.PlayerName -eq $player.Player }
            
        }
        else {
            $fanGraphsPlayer = $batters | Where-Object { $_.PlayerName -eq $player.Player }
        }

        $fanGraphsPlayer = $position | Where-Object { $_.PlayerName -eq $player.Player }
    }
}

#all players
$fantraxPlayerDatabase = Import-Csv -Path '.\import\Fantrax-Players-Dynasty Year 3.csv'
$myTeam = $fantraxPlayerDatabase | Where-Object { $_.Status -eq "BQ" }

#batters
$battersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=bat&pos=all'
$batters = Invoke-RestMethod -Uri $battersUrl -Method Get

#pitchers
$pitchersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=pit&pos=all'
$pitchers = Invoke-RestMethod -Uri $pitchersUrl -Method Get