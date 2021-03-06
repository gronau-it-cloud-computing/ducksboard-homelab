#=======================================================================#
#	List of API destinations:
#
#	vmon	 	= number of powered on VMs
#	vmoff		= number of powered off VMs
#	vmother		= number of VMs that are not on or off (suspended, etc)
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

# VM Status (custom_numeric_stacked_graph3)
$item = (Get-VM | Get-View).Runtime.PowerState | Group | %{
	if ($_.Name -eq 'poweredOn') {$body.Add("vmon",$_.Count)}
	elseif ($_.Name -eq 'poweredOff') {$body.Add("vmoff",$_.Count)}
	else {$body.Add("vmother",$_.Count)}
	}	

# Push to API
$bodyjson = $body | ConvertTo-Json
$r = Invoke-WebRequest -Uri 'https://push.ducksboard.com/values/' -Headers $db_head -Body $bodyjson -Method:Post -ContentType "application/json"

# Disconnect from vCenter
Disconnect-VIServer -Confirm:$false