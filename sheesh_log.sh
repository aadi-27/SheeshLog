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
  local last_login_count=$(wc -l < "$LOG_FILE" | awk '{print $1}')
  tail -n 100 "$AUTH_LOG" | grep "Accepted password" | while IFS= read -r line; do
    grep -qF "$line" "$LOG_FILE" || {
      timestamp=$(echo "$line" | awk '{print $1, $2, $3}')
      username=$(echo "$line" | awk '{print $10}')
      log_message "LOGIN: User '$username' logged in at '$timestamp'"
    }
  done
}

show_menu() {
  while true; do
    echo -e "\nSheesh Log Menu:"
    echo "1. View Logs"
    echo "2. Filter Logs by User"
    echo "3. Clear Logs"
    echo "4. Monitor Logins (Background)"
    echo "5. Exit"
    echo -e "Enter your choice:"
    read -r choice

    case "$choice" in
      1) view_logs ;;
      2) filter_logs_by_user ;;
      3) clear_log ;;
      4) monitor_logins & log_message "Login monitoring started in the background.";;
      5) echo "Exiting Sheesh Log." ; exit 0 ;;
      *) echo "Invalid choice. Please try again." ;;
    esac
  done
}

# --- Main Execution ---

# Start monitoring logins in the background immediately
monitor_logins &
log_message "Sheesh Log started. Login monitoring initiated."

# Show the menu
show_menu
