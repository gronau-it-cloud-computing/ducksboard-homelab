#=======================================================================#
#	List of API destinations:
#
#	fvphits 	= % of hits to the FVP cluster
#	fvpevicts 	= % of evictions from the FVP cluster
#	fvp 		= simple health metric to validate that FVP is online
#	fvpiops 	= number of IOPS saved from hitting the storage array
#	fvpused		= FVP cache usage in GB
#
#=======================================================================#

# Snapins
Import-Module PrnxCli -ErrorAction:SilentlyContinue

# Creds
Invoke-Expression ($PSScriptRoot + "\creds.ps1")

# Connect to FVP Server
Connect-PrnxServer -NameOrIPAddress $global:prnx -Credentials $global:prnx_cred -ErrorAction:Stop

# Set body var
$body = @{}

# FVP Cache Usage GB (custom_numeric_completion_gauge)
$hits = 0
$evicts = 0
$usedcap = 0
$totcap = 0
Get-PrnxObject -Cluster Lab -Type FlashProvider | %{
	$hits += $_.stats.get_Item("numReadCommandsHit")
	$evicts += $_.stats.get_Item("numEvictions")
	$usedcap += ($_.stats.get_Item("usedCapacity") / 1024 / 1024 / 1024)
	$totcap += [Math]::Round(($_.capacity / 1024 / 1024 / 1024), 2)
	}
$bodyjson = '{"value":{"current": '+$usedcap+',"min": 0,"max": '+$totcap+'}}'
$r = Invoke-WebRequest -Uri 'https://push.ducksboard.com/values/fvpused' -Headers $db_head -Body $bodyjson -Method:Post -ContentType "application/json"

# FVP FlashCluster Stats (custom_numeric_gauges)
$body.Add("fvphits",$hits)
$body.Add("fvpevicts",$evicts)

# FVP Flash Cluster Status (custom-textual-status)
if ($totcap) {$body.Add("fvp",0)}
else {$body.Add("fvp",1)}

# Push to API
$bodyjson = $body | ConvertTo-Json
$r = Invoke-WebRequest -Uri 'https://push.ducksboard.com/values/' -Headers $db_head -Body $bodyjson -Method:Post -ContentType "application/json"

# Disconnect from vCenter
Disconnect-PrnxServer