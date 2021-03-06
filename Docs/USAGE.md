# Power Shell For Fortify On Demand (FOD) Module

## Usage

#### Table of Contents
*   [Configuration](#configuration)
*   [Applications](#applications)
    * [Adding Applications](#adding-applications)
    * [Retrieving Applications](#retrieving-applications)
    * [Updating Applications](#updating-applications)
    * [Deleting Application](#deleting-applications)
*   [Releases](#releases)
    * [Adding Releases](#adding-releases)
    * [Retrieving Releases](#retrieving-releases)
    * [Updating Releases](#updating-releases)
    * [Deleting Releases](#deleting-releases)
*   [Users](#users)
    * [Adding Users](#adding-users)
    * [Retrieving Users](#retrieving-users)
    * [Updating Users](#updating-users)
    * [Deleting Users](#deleting-users)
*   [Attributes](#attributes)
    * [Retrieving Attributes](#retrieving-attributes)
*   [Troubleshooting](#troubleshooting)    

----------

## Configuration

To access the [Fortify On Demand](https://www.microfocus.com/en-us/products/application-security-testing) API you need 
to create an **"authentication"** token. This module allows the creation and persistence of this token so that it does
not need to be passed with each command. To create the token, first set your API endpoint and then request then request
the token with the following commands:

```PowerShell
Set-FODConfig -ApiUri https://api.ams.fortify.com
Get-FODToken
```

Note: the value for `ApiUri` will depend on which region you are using Fortify on Demand in. The current values are:

|Data Center|API Root Uri|
|-----------|------------|
|US|https://api.ams.fortify.com|
|EMEA|https://api.emea.fortify.com|
|APAC|https://api.apac.fortify.com|
|FedRAMP|https://api.fed.fortify.com|

After running `Get-FODToken` you will be prompted for a username and password. Both *"client credentials"* and 
*"username/password"* authentication is supported. For example, to login with your Fortify On Demand username/password 
enter your `tenant\username` values in the *"username"* field and your `password` value in the *"password"* field. For 
*"client credentials"* you should enter an API Key and API Secret that has been created in the Fortify On Demand portal 
at `Administration -> Settings -> API`.

Note: the token is not permanent; Fortify on Demand will "timeout" the token after a period of inactivity,
after which you will need to re-create it with `Get-FODToken`. The configuration is encrypted and stored on disk for 
use in subsequent commands.

To retrieve the current configuration execute the following:

```PowerShell
Get-FODConfig
```

There are currently four configuration settings available:

- `Proxy` - A proxy server configuration to use
- `ApiUri` - The API endpoint of the Fortify On Demand server you are using
- `Token` - An authentication token retrieved using `Get-FODToken`
- `ForceVerbose` - Force Verbose output for all commands and subcommands 

Each of these options can be set via `Set-FODConfig`, for example `Set-FODConfig -ForceVerbose` to force
verbose output in commands and sub-commands.

----------

## Applications

### Adding applications

To create a new application, you need to create a `FODApplicationObject` and `FODAttributeObjects` for any 
attributes you want to set for the application. Note: some attributes are mandatory and values will need to provided - 
you can check which attributes are mandatory using `Get-FODAttributes -Filter 'isRequired:True'`. 

An example of creating attributes and an application is shown in the following: 

```Powershell
# Create any AttributeObjects first - some might be mandatory
$attributes = @(
    New-FODAttributeObject -Id 22 -Value "2751"
    New-FODAttributeObject -Id 1388 -Value "some value"
)

# Create the ApplicationObject
$appObject = New-FODApplicationObject -Name "apitest1" -Description "its description" `
    -Type "Web_Thick_Client" -BusinessCriticality "Low" `
    -ReleaseName 1.0 -ReleaseDescription "its description" -SDLCStatus "Development" `
    -OwnerId 9444 -Attributes $attributes

# Add the new Application
$appResponse = Add-FODApplication -Application $appObject
if ($appResponse) {
    Write-Host "Created application with id:" $appResponse.applicationId
}
$applicationId = $appResponse.applicationId
```

In the above, you will need to know the *id* of the user who is the owner of the application. You can find out a user's
*id* by running `Get-FODUsers -Filter 'userName:xxx'` where *xxx* is the username of the user to find the *id* for.

### Retrieving applications

To get (retrieve) an individual application, use the following:

```Powershell
# Get the new Application created above
Get-FODApplication -Id $applicationId
```

To get (retrieve) one or more applications, use the following:

```Powershell
# Get any applications with "test" or "demo" in their name
Get-FODApplications -Paging -Filters "applicationName:test|demo"
```

### Updating applications

To update an existing application, you will first need to create an `FODApplicationObject` with any updated values,
you will also need to supply any `AttributeObjects` (if they are mandatory). An example is shown in the following:

```Powershell 
# Create update AttributeObjects first - mandatory attributes will still need to be sent
$updateAttributes = @(
    New-FODAttributeObject -Id 22 -Value "2751"
    New-FODAttributeObject -Id 1388 -Value "some other value"
)

# Create the update ApplicationObject
$appUpdateObject = New-FODApplicationObject -Name "apitest1-new" -Description "its updated description" `
    -BusinessCriticality "Medium" -EmailList "testuser@mydomain.com" -Attributes $updateAttributes

# Update the Application
Update-FODApplication -Id $applicationId -Application $appUpdateObject
```

### Deleting applications

To delete (remove) an application, use the following:

```Powershell
Write-Host "Deleting application with id: $applicationId"
Remove-FODApplication -Id $applicationId
```

----------

## Releases

### Adding releases

To create a release, you need to create an `FODReleaseObject` and then call `Add-FODRelease` as shown in the following:

```Powershell
# Create the ReleaseObject
$relObject = New-FODReleaseObject -Name "1.0" -Description "its description" -ApplicationId $applicationId `
    -SDLCStatus 'Development'

# Add the new release
$relResponse = Add-FODRelease -Release $relObject
if ($relResponse) {
    Write-Host "Created release with id:" $relResponse.releaseId
}
$releaseId = $relResponse.releaseId
```

### Retrieving releases

To get (retrieve) an individual release, use the following:

```Powershell
# Get the new Release created above
Get-FODRelease -Id $releaseId
```

To get (retrieve) one or more releases, use the following:

```Powershell
# Get any releases that are in 'Production' and have not 'Passed'
Get-FODReleases -Paging -Filters 'sdlcStatusType:Production+isPassed:False'
```

### Updating releases

To update an existing release, you will first need to create an `FODReleaseObject` with any updated values. An example
is shown in the following:

```Powershell
# Create the update ReleaseObject
$relUpdateObject = New-FODReleaseObject -Name "1.0.1" -Description "updated description" `
    -SDLCStatus 'QA' -OwnerId 9444

# Update the release
Update-FODRelease -Id $releaseId -Release $relUpdateObject
```

Note: the API requires that the *OwnerId* is specified on an update operation.

### Deleting releases

To delete (remove) a release, use the following:

```Powershell
Remove-FODRelease -Id $releaseId
```

----------

## Users

### Adding users

To create a user, you need to create an `FODUserObject` and then call `Add-FODUser` as shown in the following:

```Powershell
# Create the ReleaseObject
$userObject = New-FODUserObject -Username "user1" -FirstName "Test" -LastName "User" `
    -Email "user1@mydomain.com" -PhoneNumber "0123456789" -RoleId 0

# Add the new user
$usrResponse = Add-FODUser -User $usrObject
if ($usrResponse) {
    Write-Host "Created user with id:" $usrResponse.userId
}
$userId = $usrResponse.userId
```

Note: there is no function to retrieve the *RoleId* - to find the *RoleId* for a specific role, e.g. "Security Lead"
execute `Get-FODUser` on a user who you know has the role and examine the `roleId` field in the response.

### Retrieving users

To get (retrieve) an individual user, use the following:

```Powershell
# Get the new user created above
Get-FODUser -Id $userId
```

To get (retrieve) one or more users, use the following:

```Powershell
# Get any users that have the role 'Security Lead'
Get-FODUsers -Paging -Filters 'roleName:Security Lead'
```

### Updating users

To update an existing user, you will first need to create an `FODUserObject` with any updated values. An example
is shown in the following:

```Powershell
# Create the update UserObject
$usrUpdateObject = New-FODUserObject -Email "updated@mydomain.com" -PhoneNumber "01234777666" `
    -Password 'password' -MustChange

# Update the user
Update-FODUser -Id $userId -User $usrUpdateObject
```

### Deleting users

To delete (remove) a user, use the following:

```Powershell
Remove-FODRelease -Id $userId
```

----------

## Attributes

### Retrieving attributes

To get (retrieve) one or more attributes, use the following:

```Powershell
# Get all atributes
Get-FODAttributes

# Get a specific attribute called 'Regions'
Get-FODAttributes -Filter 'name:Regions'
```

----------

## Troubleshooting

TBD
