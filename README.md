# SynapseCli Starter Pack

> **Synapse-Native Bash Starter Pack for SynapseOS**  
> *Opt-in, zero-telemetry developer environment with local LLM acceleration, Synapse Brain memory access, and custom function management.*

---

## 🚀 Features

- **Local LLM Acceleration**: Instant shortcuts (`syn-ask`, `syn-qwen`, `syn-llama`, `syn-dolphin`, `syn-hermes`) with pre-warming (`syn-warm`), process monitoring (`syn-ps`), and memory flushing (`syn-flush`).
- **Direct Brain Integration**: Fast agent observation logging (`syn-log`) and search (`syn-mem search`) linked to the persistent `synapse mem` store.
- **Custom Functions**: Dynamic user function management via `synapse fn` / `syn-fn` (`add`, `remove`, `list`, `edit`, `run`).
- **Comprehensive Diagnostics**: `syn-doctor` and `syn-privacy` auditing local LLM health, DoT encryption, MAC address randomization, and firewall posture.
- **Zero Third-Party Branding**: Clean, native Synapse cyberdeck aesthetic.

---

## 📦 Installation & Removal

### Install (Interactive or Opt-In)
```bash
./install.sh
```
Or non-interactively (for Calamares installer / first boot):
```bash
./install.sh --yes
```

### Clean Removal
```bash
./uninstall.sh
```

---

## 🛠️ Command Reference

| Command | Purpose |
|---|---|
| `syn-ask [-m model] [prompt]` | Query local Ollama model |
| `syn-warm [model]` | Pre-warm model into RAM |
| `syn-flush` | Free resident models from RAM |
| `syn-ps` | List active models in VRAM/RAM |
| `syn-mem search <query>` | Query Synapse Brain memory |
| `syn-log <note>` | Append observation to Synapse memory |
| `syn-doctor` | Comprehensive system & health diagnostics |
| `syn-privacy` | Audit stealth posture (MAC, DoT, zero telemetry) |
| `syn-venv` | Auto-detect and activate `.venv` / `venv` |
| `syn-clip` | Read/write system clipboard (Wayland/X11) |
| `synapse fn <subcmd>` | Manage custom functions in `~/.config/synapse/functions/` |

---

## 📄 License
MIT License. Part of the SynapseOS ecosystem.
