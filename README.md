# A2F_installer
# Fonctional on Debian/Ubuntu

## Apply TOTP on a service
bash ./a2f_installer -s <service>

# Exemple with sshd
bash ./a2f_installer -s sshd

# Check in /etc/ssh/sshd_config if the parameters ChallengeResponseAuthentication is set to yes  PasswordAuthentication is set to no
sudo systemctl restart sshd

## Set a TOTP key for an existing user
bash .a2f_installer -u <username>