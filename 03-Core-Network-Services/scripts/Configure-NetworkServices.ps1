<#
.SYNOPSIS
    Configures Core Network Services on Windows Server 2022 DC:
    Static IP, DNS Reverse Lookup Zone, Forwarders, and AD-Authorized DHCP.
.DESCRIPTION
    Automates the networking foundation for corp.homelab.local:
    - Disables DHCP and binds static IP configuration
    - Provisions 192.168.4.0/24 Reverse Lookup Zone and PTR record
    - Configures public DNS forwarders (1.1.1.1, 8.8.8.8)
    - Deploys DHCP Server feature and authorizes it in Active Directory
    - Configures dynamic scope 192.168.4.50-150 with Scope Options 3, 6, and 15
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "[1/5] Hardening Static Network Configuration..." -ForegroundColor Cyan
Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Disabled
New-NetRoute -InterfaceAlias "Ethernet" -DestinationPrefix "0.0.0.0/0" -NextHop 192.168.4.1 -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("127.0.0.1")

Write-Host "[2/5] Provisioning DNS Reverse Lookup Zone & Forwarders..." -ForegroundColor Cyan
if (-not (Get-DnsServerZone -Name "4.168.192.in-addr.arpa" -ErrorAction SilentlyContinue)) {
    Add-DnsServerPrimaryZone -NetworkId "192.168.4.0/24" -ReplicationScope "Domain"
}

Add-DnsServerResourceRecordPtr -ZoneName "4.168.192.in-addr.arpa" -Name "200" `
    -PtrDomainName "WIN-8JMVMMCVFJU.corp.homelab.local" -AllowUpdateAny -ErrorAction SilentlyContinue

Set-DnsServerForwarder -IPAddress @("1.1.1.1", "8.8.8.8")

Write-Host "[3/5] Installing DHCP Server Feature..." -ForegroundColor Cyan
Install-WindowsFeature -Name DHCP -IncludeManagementTools

Write-Host "[4/5] Authorizing DHCP in Active Directory..." -ForegroundColor Cyan
Add-DhcpServerInDC -DnsName "WIN-8JMVMMCVFJU.corp.homelab.local" -IPAddress 192.168.4.200 -ErrorAction SilentlyContinue

Write-Host "[5/5] Deploying DHCP Scope & Options..." -ForegroundColor Cyan
if (-not (Get-DhcpServerv4Scope -ScopeId 192.168.4.0 -ErrorAction SilentlyContinue)) {
    Add-DhcpServerv4Scope -Name "Corp-Client-Subnet" `
        -StartRange 192.168.4.50 `
        -EndRange 192.168.4.150 `
        -SubnetMask 255.255.255.0 `
        -State Active
}

Set-DhcpServerv4OptionValue -ScopeId 192.168.4.0 `
    -Router 192.168.4.1 `
    -DnsServer 192.168.4.200 `
    -DnsDomain "corp.homelab.local"

Write-Host "Core Network Services successfully configured." -ForegroundColor Green