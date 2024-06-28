#!/bin/bash

#Source the configuration library
CONFIG_FILE="$(dirname "$0")/.tmux.lib.conf"

# Check if the configuration file exists, then source it
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

if [ "$1" = "next_pane" ]; then
	current_pane=$(tmux display-message -p "#P")
	panes=$(tmux list-panes -F "#P")
	next_pane=$(echo "$panes" | awk -v current=$current_pane 'NR==1 {first=$1} $1 > current {print $1; exit} END {if (!found) print first}' | head -n 1)
	tmux select-pane -t $next_pane
fi

if [ "$1" = "startup" ]; then
	# vertical split
	tmux split-window -v
	# go back to window 0
	tmux select-pane -t 0
	# horizontal split
	tmux split-window -h
	# Set base directories for work in the respective panes using the sourced variables
	# pane 0
	tmux send-keys -t 0 "cd $PANE_CD_0" C-m
	tmux send-keys -t 0 'clear' C-m
	# pane 1
	tmux send-keys -t 1 "cd $PANE_CD_1" C-m
	tmux send-keys -t 1 'clear' C-m
	# pane 2
	tmux send-keys -t 2 "cd $PANE_CD_2" C-m
	tmux send-keys -t 2 'clear' C-m
fi

if [ "$1" = "print_mounts" ]; then
    # Use `df -h` to get file system disk space usage, skip the header and exclude 'tmpfs' and 'overlay' filesystems
    df -h | tail -n +2 | grep -vE 'tmpfs|overlay' | awk '{
        size = $2;
        gsub(/B$/, "", size);
        unit = substr(size, length(size));
        num = substr(size, 1, length(size)-1);
        mult = 1;
        if (unit == "T") mult = 1024 * 1024 * 1024 * 1024;
        else if (unit == "G") mult = 1024 * 1024 * 1024;
        else if (unit == "M") mult = 1024 * 1024;
        else if (unit == "K") mult = 1024;
        size_bytes = num * mult;
        printf "%16.0f [%s] %s %s\n", size_bytes, $6, $5, $2;
    }' | sort -nr | head -3 | awk '{ printf "%s %s %s ", $2, $3, $4 } END { print "" }'
fi

if [ "$1" = "print_load" ]; then
	z_tmux_load=$(cut -d " " -f 1-3 /proc/loadavg)
	echo "${z_tmux_load}"
fi

if [ "$1" = "print_cpu" ]; then
	z_tmux_cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
	echo "${z_tmux_cpu}%"
fi

if [ "$1" = "print_mem" ]; then
	z_tmux_mem=$(free | grep Mem | awk '{printf "%.2f%", $3/$2 * 100.0}')
	echo "${z_tmux_mem}"
fi
