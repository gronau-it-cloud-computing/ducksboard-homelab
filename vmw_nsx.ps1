#=======================================================================#
#	List of API destinations:
#
#	nsxcluster 		= NSX status, either online or offline
#	nsxcontroller 	= number of NSX controllers deployed
#	nsxswitch		= number of NSX switches deployed
#	nsxrouter 		= number of NSX routers deployed
#	nsxversion		= version of NSX deployed
#
#=======================================================================#

# Snapins
Add-PSSnapin VMware.VimAutomation.Core -ErrorAction:SilentlyContinue

# Creds
Invoke-Expression ($PSScriptRoot + "\creds.ps1")

# Connect to vCenter
Connect-VIServer $global:vc -Credential $global:vc_cred -ErrorAction:Stop

# Set body var
$body = @{}

# NSX basic auth header
$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($global:nsx_cred.GetNetworkCredential().UserName + ":" + $global:nsx_cred.GetNetworkCredential().Password))
$headnsx = @{"Authorization"="Basic $auth"}

# NSX Summary (custom_numeric_boxes4)

	# Controllers
	$Request = "https://"+$global:nsx+"/api/2.0/vdn/controller"
	[xml]$r1 = (Invoke-WebRequest -Uri $Request -Headers $headnsx -ContentType "application/xml" -ErrorAction:Stop).Content
	$body.Add("nsxcontroller",$r1.controllers.controller.Count)
	$body.Add("nsxversion",$r1.controllers.controller[0].version.Substring(0,3))

	# Switches
	$Request = "https://"+$global:nsx+"/api/2.0/vdn/virtualwires"
	[xml]$r1 = (Invoke-WebRequest -Uri $Request -Headers $headnsx -ContentType "application/xml" -ErrorAction:Stop).Content
	[xml]$r2 = $r1.virtualWires.InnerXml
	$body.Add("nsxswitch",$r2.dataPage.virtualWire.Count)

	# NSX Routers
	$Request = "https://"+$global:nsx+"/api/4.0/edges"
	[xml]$r1 = (Invoke-WebRequest -Uri $Request -Headers $headnsx -ContentType "application/xml" -ErrorAction:Stop).Content
	if (-not $r1.pagedEdgeList.edgePage.edgeSummary.Count) {$body.Add("nsxrouter",1)}
	else {$body.Add("nsxrouter",$r1.pagedEdgeList.edgePage.edgeSummary.Count)}

# NSX Cluster Status (custom-textual-status)
(Get-VM -Name '*NSX_CONTROLLER*' | Get-View).Runtime.PowerState | %{
	if ($_ -ne 'poweredOn') {$body.Add("nsxcluster",1)}
	else {$body.Add("nsxcluster",0)}
	}

# Push to API
$bodyjson = $body | ConvertTo-Json
$r = Invoke-WebRequest -Uri 'https://push.ducksboard.com/values/' -Headers $db_head -Body $bodyjson -Method:Post -ContentType "application/json"

# Disconnect from vCenter
Disconnect-VIServer -Confirm:$false