#Go Daddy Dynamic DNS Update
#version 0.1 
# by Ansar Mohammed
# ansarm@gmail.com
# you need to get a GoDaddy Key and Secret from https://developer.godaddy.com/keys/ to use this script

$GoDaddyKey = "GODaddyKey"
$GoDaddySecret = "GoDaddyKey"
 
$GoDaddyAuthHeader = "sso-key " + $GOdaddyKey + ":" + $GoDaddySecret

$DNSNameToUpdate = "ras"
$DNSDomainName = "contoso.org"

$headers = @{}
$headers.Add("Authorization",$GoDaddyAuthHeader)
$headers.Add("Content-Type","application/json; charset=utf-8")
$headers.Add("Accept","application/json; charset=utf-8")

function Get-GoDaddyDomain {
Param (
[Parameter(Position=0,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$Domain)


         $domainRecord = Invoke-WebRequest -Headers $headers -Uri "https://api.godaddy.com/v1/domains/$domain"
         $domainRecord | ConvertFrom-Json
}

function Get-GoDaddyRecordsByDomain {
Param (
[Parameter(Position=0,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$Domain)

         $domainRecord = Invoke-WebRequest -Headers $headers -Uri "https://api.godaddy.com/v1/domains/$domain/records"
         $domainRecord | ConvertFrom-Json

}

function Get-GoDaddyRecordsByName {
Param (
[Parameter(Position=0,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$Domain,
[Parameter(Position=1,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$RecordType,
[Parameter(Position=2,
         Mandatory=$false,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$recordName)

         $domainRecord = Invoke-WebRequest -Headers $headers -Uri "https://api.godaddy.com/v1/domains/$domain/records/$recordType/$recordName"
         $domainRecord | ConvertFrom-Json

}


function Update-GoDaddyARecordByName {
Param (
[Parameter(Position=0,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$Domain,
[Parameter(Position=1,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$RecordName,
[Parameter(Position=2,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$RecordValue,
[Parameter(Position=3,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [int]$recordTTL)


         $newRecord = @{data=$RecordValue;ttl=$recordTTL } | ConvertTo-Json 
         $newRecord = " [ " +  $newRecord + " ] "

         $URI =  "https://api.godaddy.com/v1/domains/$domain/records/A/$recordName"
         Write-host "Calling :" $URI
         $domainRecord = Invoke-WebRequest -Method Put -Body $newRecord -Headers $headers -Uri $URI
         $domainRecord.StatusDescription

}

function New-GoDaddyARecordByName {
Param (
[Parameter(Position=0,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$Domain,
[Parameter(Position=1,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$RecordName,
[Parameter(Position=2,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [string]$RecordValue,
[Parameter(Position=3,
         Mandatory=$true,
         ValueFromPipeline=$True,
         ValueFromPipelineByPropertyName=$True)]
         [int]$recordTTL)


         $newRecord = @{type="A";name=$RecordName;data=$RecordValue} | ConvertTo-Json 
         $newRecord = " [ " + $newRecord + "]" 

         $URI =  "https://api.godaddy.com/v1/domains/$domain/records/"
         Write-host "Calling :" $URI
         $domainRecord = Invoke-WebRequest -Method Patch -Body $newRecord -Headers $headers -Uri $URI
         $domainRecord.StatusDescription
         
}


$myIP=  (Invoke-WebRequest -URI https://api.ipify.org).Content

$records = Get-GoDaddyRecordsByName -Domain $DNSDomainName -recordName $DNSNameToUpdate -RecordType "A"

if  ($records.Count -eq 0)
{
    Write-Host "Host $DNSNameToUpdate.$DNSDomainName does not exist... creating"
    New-GoDaddyARecordByName -Domain $DNSDomainName -RecordName $DNSNameToUpdate -RecordValue $myIP -recordTTL 600
}
else
{
    if ($records.data -ne $myIP)
    {
        Write-Host "Host $DNSNameToUpdate.$DNSDomainName IP does not match.. updating to $myIP"
        Update-GoDaddyARecordByName -Domain $DNSDomainName -RecordName $DNSNameToUpdate -RecordValue $myIP -recordTTL 600
    }
    else
    {
            Write-Host "Host $DNSNameToUpdate.$DNSDomainName IP matches.. "
            $records
    }
}

