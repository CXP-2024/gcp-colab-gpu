# gcp-colab-gpu

A Claude Code / Codex skill for renting Google GPUs from the command line (Windows host, PowerShell 5.1):

- **Google Colab Pro+** through the official Colab CLI (`google-colab-cli`, installed in WSL):
  T4, L4, A100, G4 (RTX PRO 6000 96 GB), H100. Wrapper: [scripts/colab.ps1](scripts/colab.ps1);
  guide: [references/colab.md](references/colab.md).
- **Google Cloud Compute Engine** Spot VMs with `gcloud` (L4, RTX PRO 6000): quota check, US-first zone fallback,
  custom Blender image, headless OptiX render, fetch, delete. Script: [scripts/gcp_render.ps1](scripts/gcp_render.ps1).

[SKILL.md](SKILL.md) explains when to use which, the measured prices and speeds, and the lessons learned.
This repo was called `gcp-blender-render` before Colab support was added.

Install: copy this folder to `~/.claude/skills/gcp-colab-gpu` (and/or `~/.codex/skills/gcp-colab-gpu`).

Billing: `gcp_render.ps1 -Action create` is a dry run unless `-Yes` is passed; `colab.ps1 run` / `new` spend
Colab compute units immediately.
