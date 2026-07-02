on run {daemon_file, agent_file, user}

  set sh1 to "echo " & quoted form of daemon_file & " > '/Library/LaunchDaemons/com.carriez.RustDesk_service.plist' && chown root:wheel '/Library/LaunchDaemons/com.carriez.RustDesk_service.plist';"

  set sh2 to "echo " & quoted form of agent_file & " > '/Library/LaunchAgents/com.carriez.RustDesk_server.plist' && chown root:wheel '/Library/LaunchAgents/com.carriez.RustDesk_server.plist';"

  set sh3 to "cp -rf /Users/" & user & "/Library/Preferences/com.carriez.RustDesk/RustDesk.toml /var/root/Library/Preferences/com.carriez.RustDesk/;"

  set sh4 to "cp -rf /Users/" & user & "/Library/Preferences/com.carriez.RustDesk/RustDesk2.toml /var/root/Library/Preferences/com.carriez.RustDesk/;"

  set sh5 to "launchctl load -w '/Library/LaunchDaemons/com.carriez.RustDesk_service.plist';"

  set sh to sh1 & sh2 & sh3 & sh4 & sh5

  do shell script sh with prompt "RustDesk wants to install daemon and agent" with administrator privileges

  display dialog "The RustDesk system service was installed successfully. Automatic startup is now enabled. RustDesk will restart to finish setup." buttons {"OK"} default button "OK" with title "RustDesk" with icon note giving up after 30
end run
