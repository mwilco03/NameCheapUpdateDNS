
function Set-NameCheapDNSEnvironmentVariables {
    <#
    .SYNOPSIS
    Sets environment variables for NameCheap DNS credentials.
    .DESCRIPTION
    This function saves the NameCheap DNS credentials as environment variables on the user's system.
    It is intended for initial setup and reduces the need to repeatedly enter credentials.
    .PARAMETER NameCheapHost
    Specifies the NameCheap hostname to be stored as an environment variable.
    .PARAMETER NameCheapDomain
    Specifies the NameCheap domain to be stored as an environment variable.
    .PARAMETER Password
    Specifies the secure string password for the NameCheap DNS account.
    .EXAMPLE
    # If you do not provide a password you will be prompted for it
    $credential = Get-Credential -UserName "host" -Message "Enter Dynamic DNS Password"
    Set-NameCheapDNSEnvironmentVariables -NameCheapHost "host" -NameCheapDomain "example.com" -Password $credential.getnetworkCredential().Password -IP "192.0.2.1"
    # This example sets the environment variables for the NameCheap DNS credentials.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$NameCheapHost,
        [Parameter(Mandatory = $true)]
        [string]$NameCheapDomain,
        [string]$NameCheapPassword
    )
    [Environment]::SetEnvironmentVariable("NameCheapHost", $NameCheapHost, "User")
    [Environment]::SetEnvironmentVariable("NameCheapDomain", $NameCheapDomain, "User")
    if(-not($NameCheapPassword)){
    $NameCheapPassword = $(Get-Credential -UserName $NameCheapHost -Message "Enter Dynamic DNS Password").getNetworkCredential().Password
    }
    [Environment]::SetEnvironmentVariable("NameCheapPassword", $NameCheapPassword, "User")
    Write-Host "Environment variables set for NameCheap DNS."
}

function Get-NameCheapDNSCredential {
    <#
    .SYNOPSIS
    Retrieves credentials for NameCheap Dynamic DNS update.
    .DESCRIPTION
    Prompts the user to enter the Dynamic DNS password and returns a hashtable containing the
    necessary information for a DNS update request.
    .PARAMETER NameCheapHost
    The subdomain or hostname for which you are updating the DNS record.
    .PARAMETER Domain
    The domain within which the host resides.
    .EXAMPLE
    $creds = Get-NameCheapDNSCredential -NameCheapHost "host" -Domain "example.com"
    This example retrieves credentials for the host "host.example.com".
    #>
    param(
        [Parameter(Mandatory = $true)]
        [Alias("Subdomain","Host")]
        [string]$NameCheapHost,
        [Parameter(Mandatory = $true)]
        [string]$NameCheapDomain
    )
    $credential = Get-Credential -UserName $NameCheapHost -Message "Enter Dynamic DNS Password"
    $NameCheapDNSCredential = @{
        NameCheapHost = $NameCheapHost
        domain = $NameCheapDomain
        password = $credential.getnetworkcredential().Password
        ip = $(Invoke-RestMethod "https://dynamicdns.park-your-domain.com/getip")
    }
    return $NameCheapDNSCredential
}

function Update-NameCheapDNS {
    <#
    .SYNOPSIS
    Constructs the URL for updating NameCheap DNS records based on provided credentials and IP address.
    .DESCRIPTION
    Takes credentials and an IP address to form a URI for updating DNS records via NameCheap's Dynamic DNS service.
    .PARAMETER NameCheapHost
    The subdomain or hostname for which the DNS record is updated.
    .PARAMETER Domain
    The domain within which the subdomain resides.
    .PARAMETER Password
    The secure password for the DNS update, as a SecureString.
    .PARAMETER IP
    The IP address to which the DNS record should be updated.
    .EXAMPLE
    Get-NameCheapDNSCredential | Update-NameCheapDNS 
    Constructs and prints the URL required to update the DNS record for the specified host and domain to the IP "192.0.2.1".
    #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Subdomain","Host")]
        [string]$NameCheapHost = $env:NameCheapHost,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$NameCheapDomain = $env:NameCheapDomain,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Password = $env:NameCheapPassword,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$IP = $(Invoke-RestMethod "https://dynamicdns.park-your-domain.com/getip")
    )
    $NameCheapParams = @{
        host     = $NameCheapHost
        domain   = $NameCheapDomain
        password = $Password
        ip       = $IP
    }
    $NameCheapQueryString = $($NameCheapParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    $NameCheapUpdateUrl = "https://dynamicdns.park-your-domain.com/update?$NameCheapQueryString"
    $Result = invoke-RestMethod $NameCheapUpdateUrl
    if($Result.'interface-response'.ErrCount -gt 0){
        Write-error "Failed to update"
    }
    else{
        write-deebug "Update Successful"
    }
}
