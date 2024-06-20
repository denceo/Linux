usage() {
    echo "Usage: $0 <interface> <new_ip> <netmask> <gateway>"
    echo "Example: $0 eth0 192.168.1.159 255.255.255.0 192.168.1.1"
}

backup_config() {
    if [ ! -f /etc/network/interfaces.backup ]; then
        cp /etc/network/interfaces /etc/network/interfaces.backup
        if [ $? -ne 0 ]; then
            echo "Failed to create a backup of the configuration file."
            exit 1
        else
            echo "Backup of the configuration file created successfully."
        fi
    else
        echo "Backup file already exists. Skipping backup."
    fi
}

restore_config() {
    if [ -f /etc/network/interfaces.backup ]; then
        cp /etc/network/interfaces.backup /etc/network/interfaces
        if [ $? -ne 0 ]; then
            echo "Failed to restore the configuration file from the backup."
            exit 1
        else
            echo "Configuration file restored successfully from the backup."
        fi
    else
        echo "No backup file found to restore."
        exit 1
    fi
}

modify_config() {
    local interface=$1
    local new_ip=$2
    local netmask=$3
    local gateway=$4

    backup_config

    sed -i "/iface $interface inet static/,+3 s/^.*$/    address $new_ip\n    netmask $netmask\n    gateway $gateway/" /etc/network/interfaces
    if [ $? -ne 0 ]; then
        echo "Failed to modify the configuration file."
        restore_config
        exit 1
    else
        echo "Configuration file modified successfully."
    fi

    /etc/init.d/networking restart
    if [ $? -ne 0 ]; then
        echo "Failed to restart the networking service."
        restore_config
        exit 1
    else
        echo "Networking service restarted successfully."
    fi
}

display_network_info() {
    echo "Current network configuration:"
    ip -4 addr show $1 | grep inet
    ip route show
}

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

if [ "$#" -ne 4 ]; then
    usage
    exit 1
fi

interface=$1
new_ip=$2
netmask=$3
gateway=$4

modify_config $interface $new_ip $netmask $gateway

display_network_info $interface

echo "Network configuration has been successfully updated."
