#!/usr/bin/env bash

set -e

USER_NAME="mock-stu"   

echo "======================================"
echo " NixOS Contest User Setup Script"
echo "======================================"
    
# Step 1: Install mkpasswd if not available
echo "[+] Ensuring mkpasswd is available..."
nix-shell -p mkpasswd --run "echo 'mkpasswd ready'" > /dev/null

# Step 2: Generate password hash
echo "[+] Enter password for user '$USER_NAME'"
HASH=$(nix-shell -p mkpasswd --run "mkpasswd -m sha-512")

echo "[+] Password hash generated"

# Step 3: Backup configuration.nix
echo "[+] Backing up configuration.nix"
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.backup

# Step 4: Check if user already exists in config
if grep -q "users.users.\"$USER_NAME\"" /etc/nixos/configuration.nix; then
    echo "[!] User already exists in configuration. Skipping insert."
else
    echo "[+] Adding user to configuration.nix"

    sudo bash -c "cat >> /etc/nixos/configuration.nix <<EOF

# IUPC Contest User
users.users.\"$USER_NAME\" = {
  isNormalUser = true;
  description = \"IUPC Contest User\";
  hashedPassword = \"$HASH\";
  extraGroups = [ ];  # No sudo
  shell = pkgs.bash;
  createHome = true;
  home = \"/home/$USER_NAME\";
};
EOF"
fi

# Step 5: Rebuild system
echo "[+] Rebuilding NixOS configuration..."
sudo nixos-rebuild switch

# Step 6: Verify user exists
echo "[+] Verifying user..."
if id "$USER_NAME" &>/dev/null; then
    echo "[✔] User '$USER_NAME' created successfully"
else   
    echo "[✘] User creation failed"
    exit 1
fi

# Step 7: Ask to switch user
echo ""
read -p "Do you want to switch to '$USER_NAME' now? (y/n): " choice

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "[+] Switching user..."
    su - "$USER_NAME"
else
    echo "[+] Setup complete. You can login manually."
fi

echo "======================================"
echo " Done"
echo "======================================"
