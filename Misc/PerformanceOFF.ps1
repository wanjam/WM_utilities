# Turn on Internet Connection
netsh interface set interface name="Internet" admin=enabled
# Turn on Real-Time Virusscanner
Set-MpPreference -DisableRealtimeMonitoring 0
# turn on auto updates
net start wuauserv
# turn on indexing service
net start WSearch