# Note: You need to run these scripts as admin and allow powershell script execution on your system
# You could, for instance, create a link 'powershell.exe -ExecutionPolicy Bypass -File PerformanceOFF.ps1'
# Turn off Internet Connection
netsh interface set interface name="Internet" admin=disabled
# Turn off Real-Time Virusscanner
Set-MpPreference -DisableRealtimeMonitoring 1
#turn off auto updates
net stop wuauserv
#turn off indexing service
net stop WSearch