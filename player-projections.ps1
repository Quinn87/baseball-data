function Get-PlayerInfo {
    param (
        [array]$players
    )
    foreach ($player in $players) {
        $batters | Where-Object {$_.PlayerName -eq $player.Player}
    }
}

$availableBattersPlusMe = Import-Csv -Path 'C:\users\shatt\Downloads\fantrax\Batters-Available+Me.csv'
$availableStartersPlusMe = Import-Csv -Path 'C:\users\shatt\Downloads\fantrax\Starters-Available+Me.csv'
$availableRelieversPlusMe = Import-Csv -Path 'C:\users\shatt\Downloads\fantrax\Relievers-Available+Me.csv'

#all players
$allPlayers

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