# Google Colab Pro+ through the official Colab CLI

Verified 2026-11-17 on a Colab Pro+ account with `google-colab-cli` 0.8.0. Use Colab when a job fits a fresh
notebook VM (training, batch generation, short GPU scripts); use the GCP VM path in SKILL.md for jobs that need
systemd services, custom drivers, baked images or more than one day.

## Why Colab first for GPU work
- Price: compute units (CU) are pre-paid. Pro+ is 49.99 USD/month for 600 CU (about 0.083 USD/CU); Colab Pro is
  9.99 USD/100 CU; pay-as-you-go 9.99 USD/100 CU. Units expire 90 days after grant.
- Third-party measured burn (Google publishes no table; check `colab usage` while a session runs):
  T4 about 1.2 CU/h, L4 about 1.7, A100 40 GB about 5.6, A100 80 GB about 7, **G4 (RTX PRO 6000) about 9**,
  H100 about 17-20. Users reported rates rising 20-33 % after 2026-10-29.
- G4 on Colab is about 0.76 USD/h vs 1.43-1.68 USD/h Spot on GCP, and does not use the GCP GPU quota (which is 1).
- H100 costs about 2x G4 in CU. For Blender (needs RT cores) and NVFP4 models, G4 is the better buy; see
  SKILL.md "H100 vs RTX PRO 6000".
- Pro+ only: G4 and H100 runtimes, background execution. Colab Pro gets T4 / L4 / A100 / TPU.

## Install (done once on this machine)
The CLI supports Linux and macOS only, so it lives in WSL in its own venv (keeps the shared WSL torch untouched):
```bash
python3 -m venv /root/envs/colab-cli
/root/envs/colab-cli/bin/pip install google-colab-cli keyrings.alt
mkdir -p ~/.config/python_keyring
printf '[backend]\ndefault-keyring=keyrings.alt.file.PlaintextKeyring\n' > ~/.config/python_keyring/keyringrc.cfg
```
WSL has no OS keyring; without `keyrings.alt` the login works for one command and is then lost
("Failed to save token to keyring"). With it the token is a **plaintext** file
(`~/.local/share/python_keyring/keyring_pass.cfg`). This is a security choice the user must make; the agent's own
attempt to configure it was blocked by the auto-mode classifier, so the user ran it.

## Login (user does this once, in WSL)
`/root/envs/colab-cli/bin/colab usage` prints an accounts.google.com URL. The user opens it, signs in with the
Pro+ account, approves, scrolls down the page titled "Sign in to the gcloud CLI" (expected: the CLI reuses that
redirect page), copies the code with the copy button and pastes it at `Enter the authorization code:`.
Each code is single-use and tied to the newest URL; an old or partial code gives `invalid_grant`.
Scopes: profile, email, cloud-platform, colaboratory, drive.file (only files the tool creates/opens).
The agent cannot do this step; give the user the one command and wait.

## Use from Windows: `scripts/colab.ps1`
Thin wrapper: same arguments as `colab`, converts absolute Windows paths with wslpath, closes stdin (a lost login
fails instead of hanging) and redacts `colab-runtime-proxy-token` from output.
```powershell
$c = "<skill dir>\scripts\colab.ps1"
& $c usage                                   # balance, burn rate, active assignments
& $c sessions                                # must say "No active sessions" when idle
& $c run --gpu G4 --timeout 900 H:\proj\job.py --epochs 3   # fresh VM, runs, auto-releases
& $c new -s train --gpu G4                   # long-lived session: bills until stop
& $c upload -s train H:\proj\data.tar /content/data.tar
& $c exec -s train -f H:\proj\step.py        # runs the file's text as a cell (no __file__)
& $c download -s train /content/out.mp4 H:\proj\out.mp4
& $c stop -s train; & $c sessions            # always confirm release
```
`colab run` is the default: it creates, runs and releases in one call (T4 check: 25 s wall in total).
`--timeout` is seconds **without output** (default 30): print progress or pass a large value.
Pass `--keep` only when you will `stop` it yourself.

## Verified hardware (2026-11-17)
| GPU | Card | VRAM | CPUs | Notes |
|---|---|---|---|---|
| T4 | Tesla T4 | 15 GB | 2 | bf16 matmul about 2 TFLOPS |
| G4 | RTX PRO 6000 Blackwell Server Edition | 97887 MiB | 48 | bf16 matmul about 138 TFLOPS in a 3 s cold test |
Both: driver 580.82.07, Python 3.13, torch 2.14.1+cu130 preinstalled, 253 GB free in /content.
Account at setup: eligible GPUs H100, G4, A100, L4, T4; TPUs V6E1, V5E1.

## Gotchas
- **Blender**: Colab's driver is 580. On GCP, Blender 5.2 OptiX failed with error 7804 on 580 and needed 590+;
  the Colab driver cannot be upgraded, so expect `--cycles-device CUDA`, not OPTIX (not yet tested on Colab).
- `/content` is deleted with the VM: download results or write to Drive (`colab drivemount`) before the end.
  Follow the egress rule in SKILL.md: encode video on the VM, never pull PNG sequences.
- `colab new` has no deadline; it meters until `colab stop -s NAME`. A stop of an unknown name prints
  "not found" and still exits 0, so always check `colab sessions`.
- Idle VMs are deleted; long silent jobs must print progress.
- Balance in `colab usage` lagged: three short runs still showed 1000.00 right after.
- Terms: no hosting, tunnels, mining, reselling or account sharing; batch jobs and training are fine.
- Upload has no mkdir: create the parent directory first (`exec` a `os.makedirs` cell).
