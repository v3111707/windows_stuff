$interface_data = Get-NetIPAddress | where IPAddress -like "172*"

if ( $interface_data -is [System.Array]) {
    Write-Host "Found more than one interface"
    Exit
}

$default_gateway = Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select-Object -ExpandProperty NextHop
$dns_servers =  Get-DnsClientServerAddress | where ServerAddresses -like "172.*" | Select-Object -ExpandProperty ServerAddresses

Write-Host "Set $($interface_data.IPAddress)/$($interface_data.PrefixLength) gateway $default_gateway to interface $($interface_data.InterfaceIndex)"
Remove-NetIPAddress -InterfaceIndex $interface_data.InterfaceIndex -Confirm:$false
New-NetIPAddress -InterfaceIndex $interface_data.InterfaceIndex -IPAddress $interface_data.IPAddress -PrefixLength $interface_data.PrefixLength -DefaultGateway $default_gateway

Write-Host "Set DNS: $dns_servers"
Set-DnsClientServerAddress -InterfaceIndex $interface_data.InterfaceIndex -ServerAddresses $dns_servers

Rename-Computer -NewName "dc"
Restart-Computer