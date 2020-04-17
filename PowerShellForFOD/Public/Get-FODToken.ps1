function Get-FODToken
{
    <#
    .SYNOPSIS
        Create a new FOD authentication token.

    .DESCRIPTION
        Connects to FOD using User or Client Credentials and saves the resultant authentication token in the
        PowerShell for FOD module configuration.

    .PARAMETER GrantType
        The method of authentication: UsernamePassword (Resource Owner Password Credentials) or ClientCredentials.

        Defaults to "UsernamePassword".

    .PARAMETER Scope
        The API scope to use, required if UsernamePassword Credentials is used.

        Defaults to "api-tenant".

    .PARAMETER Credential
        The Credential object to be used, if empty you will be prompted for User and Password.
        If UsernamePassword credentials are used enter "tenant\username" for User and your "password" for Password.
        If ClientCredentials are used enter your API Key and API Secret.

    .PARAMETR ApiUri
        FOD API Uri to use, e.g. https://api.emea.fortify.com

    .PARAMETER Proxy
        Proxy server to use

    .PARAMETER ForceVerbose
        If specified, don't explicitly remove verbose output from Invoke-RestMethod

        *** WARNING ***
        This will expose your data in verbose output

    .FUNCTIONALITY
        Fortify on Demand.
    #>
    [OutputType([String])]
    [cmdletbinding()]
    param (
        [Parameter()]
        [ValidateSet('UsernamePassword', 'ClientCredentials')]
        [string[]]$GrantType = "UsernamePassword",

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Scope = 'api-tenant',

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not$_ -and -not$Script:PS4FOD.ApiUri)
            {
                throw 'Please supply a FOD Api Uri with Set-FODConfig.'
            }
            else
            {
                $true
            }
        })]
        [string]$ApiUri = $Script:PS4FOD.ApiUri,

        [string]$Proxy = $Script:PS4FOD.Proxy,

        [switch]$ForceVerbose = $Script:PS4FOD.ForceVerbose
    )
    $Params = @{
        ErrorAction = 'Stop'
    }
    if ($Proxy)
    {
        $Params['Proxy'] = $Proxy
    }
    if (-not$ForceVerbose)
    {
        $Params.Add('Verbose', $False)
    }
    if ($ForceVerbose)
    {
        $Params.Add('Verbose', $true)
    }
    $Body = @{
        scope = $Scope
    }
    if ($GrantType -eq 'UsernamePassword')
    {
        $Body.Add('grant_type', 'password')
        $Body.Add('username', $Credential.UserName)
        $Body.Add('password',[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)))
    }
    elseif ($GrantType -eq 'ClientCredentials')
    {
        $Body.Add('grant_type', 'client_credentials')
        $Body.Add('client_id', $Credential.UserName)
        $Body.Add('client_secret',[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)))
    }
    else
    {
        # We shouldn't get here...
        Write-Error "Unknown GrantType $GrantType"
        return
    }

    $Uri = "$ApiUri/oauth/token"
    try
    {
        $Response = $null
        $Response = Invoke-RestMethod -Uri $Uri @Params -Method Post -Body $Body
    }
    catch
    {
        if ($_.ErrorDetails.Message -ne $null)
        {
            Write-Host $_.ErrorDetails
            # Convert the error-message to an object. (Invoke-RestMethod will not return data by-default if a 4xx/5xx status code is generated.)
            $_.ErrorDetails.Message | ConvertFrom-Json | Parse-FODError -Exception $_.Exception -ErrorAction Stop

        }
        else
        {
            Write-Error -Exception $_.Exception -Message "FOD API call failed: $_"
        }
    }
    # Check to see if we have confirmation that our API call failed.
    # (Responses with exception-generating status codes are handled in the "catch" block above - this one is for errors that don't generate exceptions)
    if ($Response -ne $null -and $Response.ok -eq $False)
    {
        $Response | Parse-FODError
    }
    elseif ($Response)
    {
        $Token = $Response.access_token
        Write-Verbose "Setting Token to: $Token"
        Set-FODConfig -Token $Token
    }
    else
    {
        Write-Verbose "Something went wrong.  `$Response is `$null"
    }
}
