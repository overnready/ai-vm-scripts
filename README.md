# ai-vm-scripts (public)

Minimal public provisioning profiles for Debian/Ubuntu KVM images.
**Do not commit secrets.**

## How to use
Packer clones this repo into `/opt/ai-vm-scripts` and runs:

```bash
PROFILE=debian-headless bash /opt/ai-vm-scripts/bootstrap.sh

