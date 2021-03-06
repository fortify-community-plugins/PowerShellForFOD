function Get-FODDynamicScanSetup {
    <#
    .SYNOPSIS
        Get the setup of dynamic scans for a FOD release.
    .DESCRIPTION
        Gets the setup of dynamic scans for a specific Fortify on Demand release.
    .PARAMETER ReleaseId
        The Id of the release.
    .PARAMETER OutFile
        If specified, write the setup (as JSON) to the file specified.
    .PARAMETER Raw
        If specified, provide raw output and do not parse any responses.
    .PARAMETER Token
        FOD token to use.
        If empty, the value from PS4FOD will be used.
    .PARAMETER Proxy
        Proxy server to use.
        Default value is the value set by Set-FODConfig
    .EXAMPLE
        # Get the dynamic scan setup for release with id 100
        Get-FODDynamicScanSetup -Id 100 -OutFile setup.json
    .LINK
        https://api.ams.fortify.com/swagger/ui/index#!/DynamicScans/DynamicScansV3_GetDynamicScanSetup
    .FUNCTIONALITY
        Fortify on Demand
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [int]$ReleaseId,

        [Parameter()]
        [String]$OutFile,

        [switch]$Raw,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Token = $Script:PS4FOD.Token,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ApiUri = $Script:PS4FOD.ApiUri,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Proxy = $Script:PS4FOD.Proxy,

        [switch]$ForceVerbose = $Script:PS4FOD.ForceVerbose
    )
    begin
    {
        $Params = @{}
        if ($Proxy) {
            $Params['Proxy'] = $Proxy
        }
        if ($ForceVerbose) {
            $Params.Add('ForceVerbose', $True)
            $VerbosePreference = "Continue"
        }
        Write-Verbose "Get-FODDynamicScanSetup Bound Parameters: $( $PSBoundParameters | Remove-SensitiveData | Out-String )"
        $RawDynamicScanSetup = $null
    }
    process
    {
            Write-Verbose "Send-FODApi -Method Get -Operation 'GET /api/v3/releases/$ReleaseId/dynamic-scans/scan-setup'" #$Params
            $RawDynamicScanSetup = Send-FODApi -Method Get -Operation "/api/v3/releases/$ReleaseId/dynamic-scans/scan-setup" @Params
    }
    end {
        if ($Raw) {
            $RawDynamicScanSetup
        } elseif ($OutFile) {
            Set-Content -Path $OutFile -Value ($RawDynamicScanSetup | ConvertTo-Json)
        } else {
            Parse-FODDynamicScanSetup -InputObject $RawDynamicScanSetup
        }
    }
}
