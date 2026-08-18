# Lenovo Conservation Mode Automation (Fedora)

Automatically manages Lenovo Conservation Mode based on battery charge level.

## Purpose

This service keeps the battery charging normally until it reaches **95%**, then automatically enables Lenovo Conservation Mode to prevent further charging and reduce long-term battery wear.

When the battery drops below 95%, Conservation Mode is automatically disabled so the battery can charge again the next time the charger is connected.

### Logic

| Charger State | Battery Level | Conservation Mode |
| ------------- | ------------- | ----------------- |
| Plugged In    | < 95%         | OFF               |
| Plugged In    | ≥ 95%         | ON                |
| Unplugged     | < 95%         | OFF               |
| Unplugged     | ≥ 95%         | No Change         |

The script only toggles the state when necessary and avoids unnecessary writes.

---

## Requirements

* Lenovo laptop with `ideapad_acpi` driver support
* Fedora (or another Linux distribution using systemd)
* A writable Lenovo Conservation Mode interface exposed by `ideapad_acpi`

The script discovers the firmware-specific device path automatically. To verify
that the current kernel exposes it:

```bash
grep -H . /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode
```

Expected output:

```txt
/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode:0
```

or

```txt
/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode:1
```

---

## Installation

No additional Fedora packages are required.

Run these commands from the `auto-conservation-mode` directory.

### 1. Test before installing

```bash
bash test.sh
```

Every test must report `PASS`. Do not install the service if a test fails.

### 2. Install the script and documentation

```bash
sudo install -Dm755 script.sh /usr/local/bin/auto-conservation-mode
sudo install -Dm644 README.md /usr/local/share/doc/auto-conservation-mode/README.md
```

### 3. Install the systemd service

```bash
sudo install -Dm644 auto-conservation-mode.service /etc/systemd/system/auto-conservation-mode.service
```

### 4. Enable and start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now auto-conservation-mode.service
```

### 5. Confirm that it started successfully

```bash
systemctl status auto-conservation-mode.service
journalctl -u auto-conservation-mode.service -n 30 --no-pager
grep -H . /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode
```

The service status should be `active (running)`. The final command reports `0`
when Conservation Mode is off and `1` when it is on.

### Updating an existing installation

After changing the script or service file, test and reinstall both files:

```bash
bash test.sh
sudo install -Dm755 script.sh /usr/local/bin/auto-conservation-mode
sudo install -Dm644 README.md /usr/local/share/doc/auto-conservation-mode/README.md
sudo install -Dm644 auto-conservation-mode.service /etc/systemd/system/auto-conservation-mode.service
sudo systemctl daemon-reload
sudo systemctl restart auto-conservation-mode.service
systemctl status auto-conservation-mode.service
```

---

## Verification

Check service status:

```bash
systemctl status auto-conservation-mode.service
```

View live logs:

```bash
journalctl -u auto-conservation-mode.service -f
```

Check current conservation mode state:

```bash
grep -H . /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode
```

Output:

```txt
0 = Disabled
1 = Enabled
```

---

## Service Management

Restart:

```bash
sudo systemctl restart auto-conservation-mode.service
```

Stop:

```bash
sudo systemctl stop auto-conservation-mode.service
```

Disable:

```bash
sudo systemctl disable auto-conservation-mode.service
```

---

## Troubleshooting

### Verify power-supply devices

```bash
for device in /sys/class/power_supply/*; do
  printf '%s: ' "$(basename "$device")"
  cat "$device/type"
done
```

Typical laptop entries:

```txt
ADP0: Mains
BAT0: Battery
```

or

```txt
AC: Mains
BAT0: Battery
```

### Verify Conservation Mode support

```bash
ls /sys/bus/platform/drivers/ideapad_acpi/
```

Ensure a `conservation_mode` file exists under one of the device directories:

```txt
VPC2004:00/conservation_mode
```

### Check service logs

```bash
journalctl -u auto-conservation-mode.service -n 100
```

---

## Tested Hardware

* Lenovo Legion 5 15ARH05
* Fedora 44
* systemd

## Configuration

Edit these service environment values to change the defaults:

```ini
Environment=THRESHOLD=95
Environment=INTERVAL=30
```

After editing the installed service, run:

```bash
sudo systemctl daemon-reload
sudo systemctl restart auto-conservation-mode.service
```
