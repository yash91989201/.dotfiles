# Lenovo Conservation Mode Automation

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
* Linux distribution using systemd
* Verified Conservation Mode path:

```bash
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

Expected output:

```txt
0
```

or

```txt
1
```

---

## Installation

### 1. Install the script

```bash
sudo cp auto-conservation-mode /usr/local/bin/auto-conservation-mode
sudo chmod +x /usr/local/bin/auto-conservation-mode
```

### 2. Install the systemd service

```bash
sudo cp auto-conservation-mode.service /etc/systemd/system/
```

### 3. Reload systemd

```bash
sudo systemctl daemon-reload
```

### 4. Enable and start the service

```bash
sudo systemctl enable --now auto-conservation-mode.service
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
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
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

### Verify battery devices

```bash
ls /sys/class/power_supply
```

Typical output:

```txt
ACAD
BAT0
```

or

```txt
AC
BAT0
```

### Verify Conservation Mode support

```bash
ls /sys/bus/platform/drivers/ideapad_acpi/
```

Ensure the following file exists:

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
* Zorin OS (Ubuntu-based)
* systemd
