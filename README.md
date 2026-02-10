# Ripple32 CPU Repo

## Environment Setup (Ubuntu 24.04 / WSL2)

### 1) Create and activate a Python venv

```bash
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
