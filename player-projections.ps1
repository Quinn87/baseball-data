function Get-PlayerInfo {
    param (
        [array]$players
    )
    foreach ($player in $players) {
        $batters | Where-Object {$_.PlayerName -eq $player.Player}
    }
}

function Build-Database {
    param (
        $fantraxPlayerDatabase,
        $batters,
        $pitchers
    )
    foreach ($player in $fantraxPlayerDatabase) {
        switch -Wildcard ($player.Position) {
            "*P*" { $position = "pitcher" }
            Default { $position = "batter" }
        }

        if ($position -eq "pitcher"){

        }
        else {
            <# Action when all if and elseif conditions are false #>
        }

        $fanGraphsPlayer = $position | Where-Object {$_.PlayerName -eq $player.Player}
        
        [PSCustomObject]$PSplayerData = @{
            Name = $player.Player
        }
    }
}

#all players
$fantraxPlayerDatabase = Import-Csv -Path '.\import\Fantrax-Players-Dynasty Year 3.csv'
$myTeam = $fantraxPlayerDatabase | Where-Object { $_.Status -eq "BQ" }

#batters
$battersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=bat&pos=all'
$batters = Invoke-RestMethod -Uri $battersUrl -Method Get

#starters
$startersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=sta&pos=all'
$starters = Invoke-RestMethod -Uri $startersUrl -Method Get

#relievers
$relieversUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=pit&pos=all'
$relievers = Invoke-RestMethod -Uri $relieversUrl -Method Get

foreach ($player in $players) {
    $batters | Where-Object {$_.PlayerName -eq $player} | Select-Object PlayerName
}