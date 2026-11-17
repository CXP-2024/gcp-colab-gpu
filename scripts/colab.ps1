# Thin Windows wrapper around the official Colab CLI (google-colab-cli), which only runs on Linux/macOS and
# is therefore installed in WSL (see references/colab.md). Usage is the same as `colab`:
#   & .\colab.ps1 usage
#   & .\colab.ps1 run --gpu G4 --timeout 900 H:\proj\job.py --epochs 3
# Absolute Windows paths (C:\..., H:/...) are converted with wslpath; relative paths work as-is because wsl.exe
# starts in the current Windows directory. stdin is closed so a lost login fails instead of waiting for a code.
# No param() block on purpose: every token, including -s / --gpu, must reach colab unchanged via $args.

$colab = if ($env:COLAB_CLI) { $env:COLAB_CLI } else { '/root/envs/colab-cli/bin/colab' }
$parts = foreach ($a in $args) {
    $s = [string]$a
    if ($s -match '^[A-Za-z]:[\\/]') { $s = (wsl.exe -e wslpath -a ($s -replace '\\', '/')).Trim() }
    "'" + ($s -replace "'", "'\''") + "'"
}
# Error text can contain the runtime proxy URL with a token; redact it before it reaches logs or chat.
$redact = 's/(colab-runtime-proxy-token=)[^& ]+/\1REDACTED/g'
$cmd = "$colab $($parts -join ' ') </dev/null 2>&1 | sed -E '$redact'; exit `${PIPESTATUS[0]}"
wsl.exe -e bash -lc $cmd
exit $LASTEXITCODE
