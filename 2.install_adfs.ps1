$dnsroot = (Get-ADDomain).DNSRoot
$FederationServiceDisplayName = "Contoso Corp"
$domain = (Get-ADDomain).Name
$fqdn = [System.Net.Dns]::GetHostByName(($env:computerName)) | FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
$FederationServiceName = "adfs.$dnsroot"

Add-KdsRootKey –EffectiveTime ((get-date).addhours(-10))

Write-Host "Generating Certificate"

$params = @{
  DnsName = "$FederationServiceDisplayName Root Cert"
  KeyLength = 2048
  KeyAlgorithm = 'RSA'
  HashAlgorithm = 'SHA256'
  KeyExportPolicy = 'Exportable'
  NotAfter = (Get-Date).AddYears(5)
  CertStoreLocation = 'Cert:\LocalMachine\My'
  KeyUsage = 'CertSign','CRLSign'
  Subject = "CN=Contoso Corp Root CA, OU=Sandbox"
}
$rootCA = New-SelfSignedCertificate @params

$params = @{
  Subject="CN=*.$dnsroot"
  Signer = $rootCA
  KeyLength = 2048
  KeyAlgorithm = 'RSA'
  HashAlgorithm = 'SHA256'
  KeyExportPolicy = 'Exportable'
  NotAfter = (Get-date).AddYears(2)
  CertStoreLocation = 'Cert:\LocalMachine\My'
  DnsName = "*.$dnsroot", "certauth.$FederationServiceName" ,"$FederationServiceName"
}
$adfs_cert = New-SelfSignedCertificate @params

New-Item "C:\certs" -ItemType Directory
Export-Certificate -Cert $rootCA -FilePath "C:\certs\rootCA.crt"
Import-Certificate -CertStoreLocation 'Cert:\LocalMachine\Root' -FilePath "C:\certs\rootCA.crt"

$certThumbprint =  $adfs_cert.Thumbprint

Write-Host "Installing ADFS"
Install-WindowsFeature -IncludeManagementTools -Name ADFS-Federation

Write-Host "Configuring ADFS"
Import-Module ADFS
Install-AdfsFarm -CertificateThumbprint $certThumbprint -FederationServiceName $FederationServiceName -FederationServiceDisplayName $FederationServiceDisplayName -GroupServiceAccountIdentifier "$domain\ADFSgmsa$" -OverwriteConfiguration

Set-AdfsProperties -EnableIdPInitiatedSignonPage $true
Set-ADFSProperties –ExtendedProtectionTokenCheck None

Add-DnsServerResourceRecordCName -Name "adfs" -HostNameAlias $fqdn -ZoneName $dnsroot

$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green

Restart-Computer

'''
https://adfs.contoso.loc/adfs/fs/federationserverservice.asmx

https://adfs.contoso.loc/adfs/ls/idpinitiatedsignon.htm


https://adfs.contoso.loc/adfs/oauth2/authorize

https://adfs.contoso.loc/adfs/oauth2/token

'''
