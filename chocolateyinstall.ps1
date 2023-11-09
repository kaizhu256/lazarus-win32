# powershell -File chocolateyinstall.ps1

Import-Module 'C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1'
$ErrorActionPreference = 'Stop';

$packageName= 'Lazarus'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Windows%2032%20bits/Lazarus%202.2.2/lazarus-2.2.2-fpc-3.2.2-win32.exe/download'
$url64      = 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Windows%2064%20bits/Lazarus%202.2.2/lazarus-2.2.2-fpc-3.2.2-win64.exe/download'
$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url
  url64bit      = $url64
  softwareName  = 'Lazarus*'
  checksum      = 'E53494B706D0D8529CF7A97B781EA87BE87E3B654A639692C724031F1DD576AF'
  checksumType  = 'sha256'
  checksum64    = '3AECCE3F12F9C1824DCB149142ABFBAEE4E162A2624E62CB0ECD9B7C2142B7E3'
  checksumType64= 'sha256'

  silentArgs   = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes= @(0)
}
Install-ChocolateyPackage @packageArgs


$packageName= 'LazarusCrossI386'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Windows%2032%20bits/Lazarus%202.2.2/lazarus-2.2.2-fpc-3.2.2-cross-i386-win32-win64.exe/download'
$url64      = 'https://sourceforge.net/projects/lazarus/files/Lazarus%20Windows%2064%20bits/Lazarus%202.2.2/lazarus-2.2.2-fpc-3.2.2-cross-i386-win32-win64.exe/download'
$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url
  url64bit      = $url64
  softwareName  = 'LazarusCrossI386*'
  checksum      = '83E4C0D0AB1517D83C41879114CCCC797651B2ADF587204E69B6EA022154ACF4'
  checksumType  = 'sha256'
  checksum64    = '83E4C0D0AB1517D83C41879114CCCC797651B2ADF587204E69B6EA022154ACF4'
  checksumType64= 'sha256'

  silentArgs   = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-'
  validExitCodes= @(0)
}
Install-ChocolateyPackage @packageArgs
