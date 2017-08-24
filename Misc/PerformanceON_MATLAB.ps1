# Turn off Real-Time Virusscanner
Set-MpPreference -DisableRealtimeMonitoring 1
# turn off auto updates
net stop wuauserv
# turn off indexing service
net stop WSearch