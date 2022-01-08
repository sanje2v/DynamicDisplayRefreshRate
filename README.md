# Dynamically adapting display refresh rate to change in power source
This script is changes screen refresh rate according the type of
power source (i.e. AC or battery power). It is to be invoked by
Task Scheduler on power source change event
(i.e. Event ID 105, Kernel Power, Power source change.).

## Installation
1. Download/Clone the other '.ps1' and '.xml' file to your local drive.
2. Edit 'DynamicScreenRefreshRate.ps1' at around line number 178 (bottom part of the file) to edit the variables 'REFRESHRATE_ONBATTERY' and 'REFRESHRATE_ONAC' to refresh rate values on different power sources (must be display supported too).
3. Edit 'DynamicRefreshRate.xml' using any text editor to fill in 'TODO's.
4. Make sure the PowerShell program path in this file is correct.
5. Import 'DynamicRefreshRate.xml' into Task Scheduler to create a new task from it.