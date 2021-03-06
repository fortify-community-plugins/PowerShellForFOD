function Get-FODRelease {
    <#
    .SYNOPSIS
        Get information about a specific FOD release.
    .DESCRIPTION
        Get information about a specific FOD release.
    .PARAMETER Id
        The id of the release.
    .PARAMETER Raw
        If specified, provide raw output and do not parse any responses.
    .PARAMETER Token
        FOD token to use.
        If empty, the value from PS4FOD will be used.
    .PARAMETER Proxy
        Proxy server to use.
        Default value is the value set by Set-FODConfig
    .EXAMPLE
        # Get the release with id 100
        Get-FODRelease -Id 100
    .EXAMPLE
        # Get the release with name "1.0" in application "FOD-TEST" using "Get-FODReleaseId" in pipeline
        Get-FODReleaseId -ApplicationName IWA -ReleaseName master | Get-FODRelease
    .LINK
        https://api.ams.fortify.com/swagger/ui/index#!/Releases/ReleasesV3_GetRelease
    .FUNCTIONALITY
        Fortify on Demand
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [int]$Id,

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
        Write-Verbose "Get-FODRelease Bound Parameters: $( $PSBoundParameters | Remove-SensitiveData | Out-String )"
        $RawRelease = $null
    }
    process
    {
            Write-Verbose "Send-FODApi -Method Get -Operation '/api/v3/releases/$Id'" #$Params
            $RawRelease = Send-FODApi -Method Get -Operation "/api/v3/releases/$Id" @Params
    }
    end {
        if ($Raw) {
            $RawRelease
        } else {
            Parse-FODRelease -InputObject $RawRelease
        }
    }
}
