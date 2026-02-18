# Ripple32 CPU Repo

## Environment Setup (Ubuntu 24.04 / WSL2)

### 0) Install WSL2 + Ubuntu 24.04 (Windows)

1) Open **PowerShell (Admin)** and run:

```powershell
wsl --install
```

- If you want to explicitly install **Ubuntu 24.04 LTS** (recommended), first list available distros:

```powershell
wsl --list --online
```

Then install Ubuntu 24.04:

```powershell
wsl --install -d Ubuntu-24.04
```

2) Reboot Windows if prompted.

3) Launch **Ubuntu 24.04** from the Start Menu once, then finish the first-time setup (create username/password).

(Optional) Update WSL:

```powershell
wsl --update
```

(Optional) Confirm you are using WSL2:

```powershell
wsl -l -v
```

### 0.1) Install Git (inside WSL / Ubuntu)

Inside the Ubuntu (WSL) terminal:

```bash
sudo apt update
sudo apt install -y git-all
git --version
```

(Optional) Set your Git identity:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### 1) Create and activate a Python venv

```bash
cd your/path
python3 -m venv venv
source venv/bin/activate
python -m pip install -U pip
```

### 2) Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3) Install Verilator (stable)

This repo uses Verilator for linting and simulation. Cocotb requires **Verilator >= 5.036**.

Run the official Git-based install script (installs to `/usr/local`, requires `sudo`):

```bash
./install_verilator_stable.sh
```

(It may take some time)

Verify:

```bash
verilator --version
which verilator
```

### 4) Run environment checks

```bash
./env_check.sh
```

## Notes

- If you are using VS Code Remote (WSL), it may inject a project `venv/bin` into `PATH`. This is normal, but always use:

  ```bash
  which python3
  which cocotb-config
  ```

  if you suspect version/path conflicts.
