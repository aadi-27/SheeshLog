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
        tail -n 50 "$AUTH_LOG" | grep "session opened for user" | while read -r line; do
            user=$(echo "$line" | grep -oP "session opened for user \K\w+")
            timestamp=$(date "+%Y-%m-%d %H:%M:%S")
            log_message "Login detected for user $user"
        done
        sleep 5
    done
}

store_logs_to_file() {
    echo -e "Enter the filename to store the logs (e.g., backup.txt):"
    read -r output_filename
    if [ -n "$output_filename" ]; then
        cp "$LOG_FILE" "$output_filename"
        log_message "Session logs stored to '$output_filename'"
        dialog --msgbox "Session logs stored to '$output_filename'." 10 40
    else
        dialog --msgbox "No filename provided. Log storage cancelled." 10 40
    fi
}

show_menu() {
    while true; do
        CHOICE=$(dialog --clear --backtitle "Sheesh Log - Login Monitor" \
            --title "Main Menu" \
            --menu "Choose an option:" 17 50 7 \
            1 "View Logs" \
            2 "Filter Logs by User" \
            3 "Clear Logs" \
            4 "Monitor Logins (Background)" \
            5 "Store Logs to File" \
            6 "Exit" \
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
                store_logs_to_file
                ;;
            6)
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