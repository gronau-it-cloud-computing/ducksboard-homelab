# Gather credentials from the Creds.ps1 file
Invoke-Expression ($PSScriptRoot + "\creds.ps1")

# Collect data and send to dashboard
$j1 = Start-Job -Name "VMware Host" -ScriptBlock {
	$global:scriptpath = 'W:\code\ducksboard-homelab'
	Invoke-Expression ($global:scriptpath + "\vmw_host.ps1")
	}

$j2 = Start-Job -Name "VMware Cluster" -ScriptBlock {
	$global:scriptpath = 'W:\code\ducksboard-homelab'
	Invoke-Expression ($global:scriptpath + "\vmw_cluster.ps1")
	}

$j3 = Start-Job -Name "VMware VM" -ScriptBlock {
	$global:scriptpath = 'W:\code\ducksboard-homelab'
	Invoke-Expression ($global:scriptpath + "\vmw_vm.ps1")
	}