param(
    [switch]$Local,
    [switch]$SkipPublishing
)

$Org = "fortify-community-plugins"
$Author = 'Kevin Lee'
$PowerShellForFOD = 'PowerShellForFOD'

# Line break for readability in AppVeyor console
Write-Host -Object ''

# Make sure we're using the Master branch and that it's not a pull request
# Environmental Variables Guide: https://www.appveyor.com/docs/environment-variables/
if ($env:APPVEYOR_REPO_BRANCH -ne 'master' -and $Local -eq $false) {
    Write-Warning -Message "Skipping version increment and publish for branch $env:APPVEYOR_REPO_BRANCH"
}
elseif ($env:APPVEYOR_PULL_REQUEST_NUMBER -gt 0) {
    Write-Warning -Message "Skipping version increment and publish for pull request #$env:APPVEYOR_PULL_REQUEST_NUMBER"
}
else {
    # We're going to add 1 to the revision value since a new commit has been merged to Master
    # This means that the major / minor / build values will be consistent across GitHub and the Gallery
    Try {
        # Remove any left over build files
        Get-ChildItem * -Include *.nuspec -Recurse | Remove-Item

        # This is where the module manifest lives
        $manifestPath = ".\$PowerShellForFOD\$PowerShellForFOD.psd1"

        # Start by importing the manifest to determine the version, then add 1 to the revision
        $manifest = Test-ModuleManifest -Path $manifestPath
        [System.Version]$version = $manifest.Version
        Write-Output "Old Version: $version"
        [String]$newVersion = New-Object -TypeName System.Version -ArgumentList ($version.Major, $version.Minor, $version.Build, $env:APPVEYOR_BUILD_NUMBER)
        Write-Output "New Version: $newVersion"

        # Update the manifest with the new version value and fix the weird string replace bug
        $functionList = ((Get-ChildItem -Path .\$PowerShellForFOD\Public).BaseName)
        $splat = @{
            'Path'              = $manifestPath
            'ModuleVersion'     = $newVersion
            'FunctionsToExport' = $functionList
            'Copyright'         = "(c) $( (Get-Date).Year ) $Author. All rights reserved."
        }
        Update-ModuleManifest @splat
        (Get-Content -Path $manifestPath) -replace "PSGet_$PowerShellForFOD", "$PowerShellForFOD" | Set-Content -Path $manifestPath
        (Get-Content -Path $manifestPath) -replace 'NewManifest', $PowerShellForFOD | Set-Content -Path $manifestPath
        (Get-Content -Path $manifestPath) -replace 'FunctionsToExport = ', 'FunctionsToExport = @(' | Set-Content -Path $manifestPath -Force
        (Get-Content -Path $manifestPath) -replace "$($functionList[-1])'", "$($functionList[-1])')" | Set-Content -Path $manifestPath -Force
    }
    catch {
        throw $_
    }

    # Create new markdown and XML help files
    Write-Host "Building new function documentation" -ForegroundColor Yellow
    Import-Module -Name "$PSScriptRoot\..\$PowerShellForFOD" -Force
    New-MarkdownHelp -Module $PowerShellForFOD -OutputFolder '..\docs\' -Force
    New-ExternalHelp -Path '..\docs\' -OutputPath "..\$PowerShellForFOD\en-US\" -Force
    . .\Build\docs.ps1
    Write-Host -Object ''

    if ($SkipPublishing) {
        Write-Host "Skipping Publishing to Powershell Gallery"
    } else  {
        # Publish the new version to the PowerShell Gallery
        Try
        {
            # Build a splat containing the required details and make sure to Stop for errors which will trigger the catch
            $PM = @{
                Path = ".\$PowerShellForFOD"
                NuGetApiKey = $env:NuGetApiKey
                ErrorAction = 'Stop'
            }

            Publish-Module @PM
            Write-Host "$PowerShellForFOD PowerShell Module version $newVersion published to the PowerShell Gallery." -ForegroundColor Cyan
        }
        Catch
        {
            # Sad panda; it broke
            Write-Warning "Publishing update $newVersion to the PowerShell Gallery failed."
            throw $_
        }

        # Publish the new version back to Master on GitHub
        Try {
            # Set up a path to the git.exe cmd, import posh-git to give us control over git, and then push changes to GitHub
            # Note that "update version" is included in the appveyor.yml file's "skip a build" regex to avoid a loop
            $env:Path += ";$env:ProgramFiles\Git\cmd"
            Import-Module posh-git -ErrorAction Stop
            git checkout master
            git add --all
            git status
            git commit -s -m "Update version to $newVersion"
            git push origin master
            Write-Host "$PowerShellForFOD PowerShell Module version $newVersion published to GitHub." -ForegroundColor Cyan
        }
        Catch {
            # Sad panda; it broke
            Write-Warning "Publishing update $newVersion to GitHub failed."
            throw $_
        }
    }
}
