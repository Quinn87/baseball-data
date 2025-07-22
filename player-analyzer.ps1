#function definitions
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

    $mlbPlayer = $savantResponse | Where-Object { $_.player_id -eq $playerId }
    
    if ($position -eq "pitcher") {
            
        $pitcherData = @{
            "PA"       = $mlbPlayer.pa
            "K%"       = $mlbPlayer.k_percent
            "Whiffs"   = $mlbPlayer.whiffs
            "BB%"      = $mlbPlayer.bb_percent
            "obp"      = $mlbPlayer.obp
            "xobp"     = $mlbPlayer.xobp
            "xobpdiff" = $mlbPlayer.xobpdiff
            "ERA"      = $player.ERA
            "WHIP"     = $player.WHIP
            "SPC"      = $player.SPC
            "RPC"      = $player.RPC
        }
    
        $playerData = $baseData + $pitcherData
    }
    else {
        $batterData = @{
            "OPS"   = $mlbPlayer.OPS
            "PA"    = $mlbPlayer.PA
            "Games" = $mlbPlayer.G
            "K%"    = $mlbPlayer."K%"
            "BB%"   = $mlbPlayer."BB%"
            "Runs"  = $mlbPlayer.R
            "RBIs"  = $mlbPlayer.RBI
            "SB"    = $mlbPlayer.SB
            "CS"    = $mlbPlayer.CS
            "OBP"   = $mlbPlayer.OBP
            "SLG"   = $mlbPlayer.SLG
        }
        $playerData = $baseData + $batterData
    }

    return New-Object PSObject -Property $playerData
}

do {
    $csvUpload = Read-Host "Enter the path to the CSV file to upload"
} while ($csvUpload -notlike "*.csv")

if (-not (Test-Path -Path $csvUpload)) {
    Write-Host "File not found: $csvUpload"
    exit
}

$csvUpload = Import-Csv -Path $csvUpload
$playerMap = Import-Csv -Path ".\PlayerMap.csv"

$startDate = Read-Host "Enter start date (YYYY-MM-DD): "
$endDate = Read-Host "Enter end date (YYYY-MM-DD): "

do {
    $position = Read-Host "Position (pitcher or batter): "
} while (
    $position -ne "pitcher" -and $position -ne "batter"
)

$savantUrl = "https://baseballsavant.mlb.com/statcast_search/csv?hfPT=&hfAB=&hfGT=R%7C&hfPR=&hfZ=&hfStadium=&hfBBL=&hfNewZones=&hfPull=&hfC=&hfSea=2025%7C&hfSit=&player_type=$position&hfOuts=&hfOpponent=&pitcher_throws=&batter_stands=&hfSA=&game_date_gt=$startDate&game_date_lt=$endDate&hfMo=&hfTeam=&home_road=&hfRO=&position=&hfInfield=&hfOutfield=&hfInn=&hfBBT=&hfFlag=&metric_1=&group_by=name&min_pitches=0&min_results=0&min_pas=0&sort_col=pitches&player_event_sort=api_p_release_speed&sort_order=desc"

$savantResponse = Invoke-RestMethod -Uri $savantUrl -Method Get | ConvertFrom-Csv

foreach ($player in $csvUpload) {
    $playerId = ($playerMap | Where-Object { $_.FANTRAXID -eq "$($player.id)" }).MLBID

    if ($playerId) {
        $playerInfo = Get-PlayerInfo -player $player -playerId $playerId
        $playerInfo | Export-Csv -Path ".\PlayerData.csv" -Append -NoTypeInformation
    }
    else {
        Write-Host "Player ID not found for $($player.Player)"
    }
}