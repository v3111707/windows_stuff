$dnsroot = (Get-ADDomain).DNSRoot
$FederationServiceDisplayName = "Contoso Corp"
$domain = (Get-ADDomain).Name
$fqdn = [System.Net.Dns]::GetHostByName(($env:computerName)) | FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
$FederationServiceName = "adfs.$dnsroot"

Add-KdsRootKey –EffectiveTime ((get-date).addhours(-10))

Write-Host "Installing nuget package provider"
Install-PackageProvider nuget -force

Write-Host "Installing PSPKI module"
Install-Module -Name PSPKI -Force

Write-Host "Importing PSPKI into current environment"
Import-Module -Name PSPKI

Write-Host "Generating Certificate"
$selfSignedCert = New-SelfSignedCertificateEx `
    -Subject "CN=*.$dnsroot" `
    -ProviderName "Microsoft Enhanced RSA and AES Cryptographic Provider" `
    -KeyLength 2048 -FriendlyName 'OAFED SelfSigned' -SignatureAlgorithm sha256 `
    -EKU "Server Authentication", "Client authentication" `
    -KeyUsage "KeyEncipherment, DigitalSignature" `
    -Exportable -StoreLocation "LocalMachine" `
    -SubjectAlternativeName ("dns:*.$dnsroot", "dns:certauth.$FederationServiceName" ,"dns:$FederationServiceName")

$certThumbprint = $selfSignedCert.Thumbprint

Write-Host "Installing ADFS"
Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation

Write-Host "Configuring ADFS"
Import-Module ADFS
Install-AdfsFarm -CertificateThumbprint $certThumbprint -FederationServiceName $FederationServiceName -FederationServiceDisplayName $FederationServiceDisplayName -GroupServiceAccountIdentifier "$domain\ADFSgmsa$" -OverwriteConfiguration

Set-AdfsProperties -EnableIdPInitiatedSignonPage $true
Add-DnsServerResourceRecordCName -Name "adfs" -HostNameAlias $fqdn -ZoneName $dnsroot


$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green


'''
https://adfs.contoso.loc/adfs/fs/federationserverservice.asmx

https://adfs.contoso.loc/adfs/ls/idpinitiatedsignon.htm

'''
