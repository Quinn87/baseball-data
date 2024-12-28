#batters
$battersUrl = 'https://www.fangraphs.com/api/projections?type=atc&stats=bat&pos=all'
$batters = Invoke-RestMethod -Uri $battersUrl -Method Get
$batters | Select-Object PlayerName, minpos, WAR, sb, RBI, R, OBP | Select-Object -First 3

#starters
$startersUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=sta&pos=all'
$starters = Invoke-RestMethod -Uri $startersUrl -Method Get

#relievers
$relieversUrl = 'https://www.fangraphs.com/api/projections?type=steamer&stats=rel&pos=all'
$relievers = Invoke-RestMethod -Uri $relieversUrl -Method Get
