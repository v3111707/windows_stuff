$domain = "contoso.loc"
$netbios = "CONTOSO"

Install-WindowsFeature –Name AD-Domain-Services -IncludeManagementTools

Install-ADDSForest -DomainName $domain `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "7" `
    -DomainNetbiosName $netbios `
    -ForestMode "7" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$True `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true

Get-Service adws,kdc,netlogon,dns
Restart-Computer
