#!/bin/bash

# --- Configuration ---
LOG_FILE="session.log"
AUTH_LOG="/var/log/auth.log" # Adjust based on your Linux distribution

# --- Utility Functions ---

log_message() {
  timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $1" >> "$LOG_FILE"
}

clear_log() {
  echo -e "Are you sure you want to clear the log file? (y/N)"
  read -r confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    > "$LOG_FILE"
    log_message "LOG CLEARED by user $(whoami)"
    echo "Log file cleared."
  else
    echo "Log clearing cancelled."
  fi
}

view_logs() {
  echo -e "\n--- Session Log ---\n"
  cat "$LOG_FILE"
  echo -e "\n--- End of Log ---\n"
}

filter_logs_by_user() {
  echo -e "Enter username to filter:"
  read -r username
  if [ -n "$username" ]; then
    echo -e "\n--- Log entries for user '$username' ---\n"
    grep "$username" "$LOG_FILE"
    echo -e "\n--- End of Filtered Log ---\n"
  else
    echo "No username provided."
  fi
}

monitor_logins() {
    while true; do
        tail -n 50 /var/log/auth.log | grep "session opened for user" | while read -r line; do
            user=$(echo "$line" | grep -oP "session opened for user \K\w+")
            timestamp=$(date "+%Y-%m-%d %H:%M:%S")
            echo "[$timestamp] Login detected for user $user" >> session.log
        done
        sleep 5
    done
}



show_menu() {
  while true; do
    CHOICE=$(dialog --clear --backtitle "Sheesh Log - Login Monitor" \
      --title "Main Menu" \
      --menu "Choose an option:" 15 50 6 \
      1 "View Logs" \
      2 "Filter Logs by User" \
      3 "Clear Logs" \
      4 "Monitor Logins (Background)" \
      5 "Exit" \
      3>&1 1>&2 2>&3)

    clear

    case $CHOICE in
      1)
        dialog --textbox "$LOG_FILE" 20 70
        ;;
      2)
        username=$(dialog --inputbox "Enter username to filter:" 10 40 3>&1 1>&2 2>&3)
        grep "$username" "$LOG_FILE" > /tmp/filtered_log.txt
        dialog --textbox /tmp/filtered_log.txt 20 70
        ;;
      3)
        dialog --yesno "Are you sure you want to clear the log file?" 10 40
        response=$?
        if [ "$response" -eq 0 ]; then
          > "$LOG_FILE"
          log_message "LOG CLEARED by user $(whoami)"
          dialog --msgbox "Log file cleared." 10 40
        else
          dialog --msgbox "Log clearing cancelled." 10 40
        fi
        ;;
      4)
        monitor_logins &
        log_message "Login monitoring started in the background."
        dialog --msgbox "Login monitoring started in background." 10 40
        ;;
      5)
        clear
        exit 0
        ;;
      *)
        dialog --msgbox "Invalid choice." 10 40
        ;;
    esac
  done
}


# --- Main Execution ---

# Start monitoring logins in the background immediately
monitor_logins &
log_message "Sheesh Log started. Login monitoring initiated."

# Show the menu
show_menu
