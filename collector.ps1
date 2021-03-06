# Gather credentials from the Creds.ps1 file
Invoke-Expression ($PSScriptRoot + "\creds.ps1")

# Map the various jobs into a hashtable
# Code credit to cdituri
$jobMap = [Ordered]@{
  "VMware Host"     = "vmw_host.ps1";
  "VMware Cluster"  = "vmw_cluster.ps1";
  "VMware VM"       = "vmw_vm.ps1";
  "VMware NSX"      = "vmw_nsx.ps1";
  "PernixData FVP"  = "prnx_fvp.ps1"
}

# Collect data and send to dashboard
# Code credit to cdituri
$jobMap.Keys | % {
  $scriptPath = Join-Path $PSScriptRoot $jobMap[$_]
  Start-Job -Name "$($_)" -ScriptBlock { Invoke-Expression $args[0] } -ArgumentList $scriptPath
}

Get-Job | Wait-Job
Get-Job | Remove-Job