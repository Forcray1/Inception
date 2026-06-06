Distro: Debian 12 Bookworm

Memory, set it to 4096 MB if the machine allows, 2048 MB at the very least.
Processors, set 2.
Create a virtual hard disk now, type VDI, dynamically allocated, size 25 GB or
more. Docker images and volumes need room.
Create the VM.

Select the VM, click Settings.
System, then Processor, confirm 2 CPUs.
Display, then Screen, set Video Memory to 128 MB. This makes the desktop
smooth.
Network, confirm Adapter 1 is enabled and attached to NAT. NAT gives the VM
internet access, which is all you need, because you will open the website in
a browser inside the VM.
Storage, find the empty optical drive, click it, and choose your downloaded
Debian ISO as the disk file.
Save the settings.

Start the VM. It boots from the ISO.
Choose Graphical Install.
Pick your language, location, and keyboard layout.
Hostname, type inception. Domain name, leave it blank and continue.
Root password.
Create your user. Enter your full name, then a username, then a password.
Partition disks, choose Guided, use entire disk. Then choose to put all files
in one partition. Confirm and write the changes to disk when asked.
The base system installs. If asked about a package mirror, accept the default
country and mirror, and leave the proxy blank.
Popularity contest, you can answer No.
Software selection, this screen matters. Use the spacebar to set it like this:
    - Uncheck the GNOME desktop, it is heavy.
    - Check Xfce, the light desktop.
    - Keep the box for a desktop environment checked overall if there is one.
    - Check SSH server.
    - Keep standard system utilities checked.
    Then continue. This installs the packages.
GRUB boot loader, choose Yes to install it, and select the disk shown, which
is usually /dev/sda.
Finish the installation. When it asks, remove the ISO and reboot. In
VirtualBox the ISO is usually ejected automatically, if not, go to Devices
and remove the disk, then reboot.

Open a terminal from the application menu.
Confirm sudo, this should print your username:
sudo whoami
If it says you are not in the sudoers file, you set a root password during
install. Fix it by logging in as root with su, then running
usermod -aG sudo yourusername, then reboot.

Update the package lists and upgrade:
   sudo apt-get update && sudo apt-get upgrade -y
Install the tools you will need:
   sudo apt-get install -y git make curl ca-certificates gnupg

Use the official Docker repository, it gives you the modern docker compose
command, with a space, which your Makefile uses.

Add Docker's signing key:
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   sudo chmod a+r /etc/apt/keyrings/docker.gpg
Add the Docker repository:
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
Install Docker:
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
Let your user run Docker without sudo:
   sudo usermod -aG docker $USER
Log out of the desktop and log back in, so the new group takes effect.
Check both work:
   docker run hello-world
   docker compose version
The first prints a welcome message, the second prints a version number.

Edit the hosts file:
   sudo nano /etc/hosts
Add this line, then save with Ctrl O, Enter, and exit with Ctrl X:
   127.0.0.1 mlorenzo.42.fr
Test it:
   ping -c1 mlorenzo.42.fr
   It should reply from 127.0.0.1.

Choose a place for the repo, for example your home folder.
Clone your repository
Go into the project and confirm the Makefile is there
Create your secret files and the .env on the VM, since those are not in git.

Done

# The VM is ready when

- You boot into the XFCE desktop and have a terminal.
- sudo works for your user.
- docker succeeds without sudo.
- docker compose version prints a version.
- ping mlorenzo.42.fr replies from 127.0.0.1.
- Your project is on the VM and make starts building.
