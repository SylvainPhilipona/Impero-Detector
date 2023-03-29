Function Configs {return [PSCustomObject]@{
    Conf = @{
        Name = "notepad"
        MinDelta = 5
        Unit = "MB"
        IterationDuration = 300
    }

    Trigger = @{
        Browser = "msedge"
        Website = "www.joca.ch"
    }
}}Function Get-ProcessRamUsage {<#
.NOTES
    *****************************************************************************
    Name:	Get-ProcessRamUsage
    Author:	Sylvain Philipona
    Date:	29.03.2023
 	*****************************************************************************
    Modifications
 	Date  : 
 	Author: 
 	Reason: 
 	*****************************************************************************
.SYNOPSIS
    Get the ram usage of a process
 	
.DESCRIPTION
    Get and return the ram usage of all iterations of the process defined in parameters.
    The value is returned according to unit defined in parameters
  	
.PARAMETER ProcessName
    The name of the process to look for the ram usage

.PARAMETER Unit
    The unit that the value will be returned
 	
.OUTPUTS
	The output are the ram usage of all iterations of the process

.EXAMPLE
    Get-ProcessRamUsage -ProcessName notepad -Unit KB
 	
    15480
#>

# Script parameters
param(
    [Parameter(Position=0)]
    [string]$ProcessName = "ImperoClient",

    [Parameter(Position=1)]
    [ValidateSet("Byte","KB","MB", "GB")]
    [string]$Unit = "MB"
)

# Table to convert differents units
$convertTable = @{
    "Byte" = [math]::Pow(1024,0)
    "KB" = [math]::Pow(1024,1)
    "MB" = [math]::Pow(1024,2)
    "GB" = [math]::Pow(1024,3)
}

# Get all processes by the name defined in params
$processes = (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)

# Check if the process defined in params exists
if($processes.Count -eq 0){
    return 0
}

# Return an array of all processes RAM consumption
return ($processes | ForEach-Object -process {$_.WorkingSet64 / $convertTable[$Unit]})}Function Start-FakeWebPage {<#
.NOTES
    *****************************************************************************
    Name:	Start-FakeWebPage
    Author:	Sylvain Philipona
    Date:	29.03.2023
 	*****************************************************************************
    Modifications
 	Date  : 
 	Author: 
 	Reason: 
 	*****************************************************************************
.SYNOPSIS
    Open a webpage on eachs monitors
 	
.DESCRIPTION
    Open a webpage on all monitors of the user. 
    The web browser and the website are defined in parameters
  	
.PARAMETER Website
    The website that will be open

.PARAMETER Browser
    The web browser that will be use to open the website
 	
.OUTPUTS
	- Create 1 web browser window on fullscreen and on each monitors

.EXAMPLE
    Start-FakeWebPage -Website "gesteleves.etmlnet.local" -Browser msedge
 	
.LINK
    https://www.reddit.com/r/PowerShell/comments/6qqagj/get_relative_positioning_of_monitors/
    https://stackoverflow.com/questions/70973523/powershell-launch-window-on-second-screen

#>

# Script parameters
param(
    [Parameter(Position=0)]
    [string]$Website = "www.etml.ch",

    [Parameter(Position=1)]
    [ValidateSet("chrome","msedge")]
    [string]$Browser = "chrome"
)

# Load the windows form assembly and obtains all monitors connected to the computer
Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens | Select-Object primary, workingarea

# Open a web browser on each monitor
$screens | ForEach-Object{

    # Obtains X and Y position of the monitor
    $x = $_.workingarea.X
    $y = $_.workingarea.Y
    $i = $screens.IndexOf($_)+1

    # The arguments ensure that the browser is opened in a new window, in full-screen mode, in a separate user data directory for each monitor.
    # At the correct X and Y positions on the screen. 
    # The website to be opened is specified by the $Website variable
    Start-Process $Browser ("--new-window",  "--start-fullscreen", "--user-data-dir=c:/screen$i","--window-position=$x,$y", $Website)
}
}Function Test-Augmentation {<#
.NOTES
    *****************************************************************************
    Name:	Test-Augmentation
    Author:	Sylvain Philipona
    Date:	29.03.2023
 	*****************************************************************************
    Modifications
 	Date  : 
 	Author: 
 	Reason: 
 	*****************************************************************************
.SYNOPSIS
    Test the value augmentation
 	
.DESCRIPTION
    Test if the augmentation between 2 values defined in parameters has augmented of minimum the delta which is also defined in parameters
  	
.PARAMETER OldValue
    The old value to compare with the new

.PARAMETER NewValue
    The new value to compare with the old

.PARAMETER MinDelta
    The minumum augmentation to detect
 	
.OUTPUTS
	A boolean value according to the values in parameters

.EXAMPLE
    Test-Augmentation -OldValue 15.68 -NewValue 23.59 -MinDelta 6.2

    True

.EXAMPLE
    Test-Augmentation -OldValue 15.68 -NewValue 23.59 -MinDelta 11 

    False

.EXAMPLE
    Test-Augmentation -OldValue 23.59 -NewValue 15.68 -MinDelta 3

    False

#>

# Script parameters
param(
    [Parameter(Position=0)]
    [float]$OldValue,

    [Parameter(Position=1)]
    [float]$NewValue,

    [Parameter(Position=2)]
    [float]$MinDelta
)

# Check if the new value minus the old value is less than the minimum delta
# Eg.
#   New Value : 25
#   Old Value : 8
#   Min Delta : 3
#   (25 - 8 < 3) = False. 
#   The augmentation was greater than the delta. The value 'True' will be returned
if(($NewValue - $OldValue) -lt $MinDelta){
    return $false
}

return $true}# Configs
$Config = Configs

# Variables
[float]$OldValue = 0
[bool]$FirstIteration = $true
[bool]$global:stop = $false

# Load the windows form assembly
# Create a notify icon that is display at bottom right
# This notification allow the user to stop the script when the console is hidden
Add-Type -AssemblyName System.Windows.Forms
$notification = New-Object System.Windows.Forms.NotifyIcon
$notification.Icon = "C:\Users\sylphilipona\Downloads\Sebastien.ico"
$notification.add_Click{
    $notification.Dispose()
    $global:stop = $true
}
$notification.Visible = $true



while(!($global:stop)){

    # Get the ram usage of the parameters defined process
    $RamUsage = [float](Get-ProcessRamUsage -ProcessName $Config.Conf.Name -Unit $Config.Conf.Unit)[0]

    # On the first iteration do nothing
    # Otherrise the augentation from 0 to the ram usage will be instant detected
    if($FirstIteration){
        $OldValue = $RamUsage
        $FirstIteration = $false
        continue
    }

    # Test if the ram usage has augmented from the last iteration
    # The MinDelta is the minimum augmentation that we will detect
    # The usual usage depand of the PC. The values are the ones detected on my PC
    # However the augmentation seems to be the same no matter what computer
    # This value is calibrated by tests
    #   Usual usage               : ~ 213-218 MB
    #   Usage on screen recording : 
    # 
    if(Test-Augmentation -OldValue $OldValue -NewValue $RamUsage -MinDelta $Config.Conf.MinDelta){
        Write-Host "Augmentation de l'utilisation de la ram --> $RamUsage" -ForegroundColor Green


        Start-FakeWebPage -Website $Config.Trigger.Website -Browser $Config.Trigger.Browser
        # [System.Windows.Forms.MessageBox]::Show("Attention!")
    }
    else{
        Write-Host "Non --> $RamUsage" -ForegroundColor Red
    }

    # Set the old value as current.
    # So in the next iteration the current value will be the last iteration value
    $OldValue = $RamUsage
    Start-Sleep -Milliseconds $Config.Conf.IterationDuration
}
