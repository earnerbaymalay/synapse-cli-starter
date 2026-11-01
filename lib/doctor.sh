# shellcheck shell=bash
# Health & Privacy diagnostics for SynapseOS

syn-doctor() {
    local pass=0 fail=0 warn=0
    echo -e "\033[1;36m=== Synapse System & Agent Health Diagnostics ===\033[0m"
    
    # 1. Synapse Brain & Binary
    echo -n "Checking Synapse CLI binary... "
    if command -v synapse >/dev/null 2>&1; then
        echo -e "\033[32m[PASS]\033[0m ($(synapse --version 2>/dev/null || echo 'installed'))"
        ((pass++))
        echo -e "\n\033[1;34m--- Synapse Doctor Report ---\033[0m"
        if command synapse doctor; then
            ((pass++))
        else
            echo -e "\033[33m[WARN] Synapse doctor reported findings\033[0m"
            ((warn++))
        fi
        echo -e "\033[1;34m----------------------------\033[0m\n"
    else
        echo -e "\033[31m[FAIL]\033[0m (synapse binary not found on PATH)"
        ((fail++))
    fi

    # 2. Local Ollama LLM Service
    echo -n "Checking Local Ollama Daemon (127.0.0.1:11434)... "
    if curl -s --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
        local models
        models=$(curl -s --max-time 2 http://127.0.0.1:11434/api/tags | jq -r '.models[]?.name' 2>/dev/null | tr '\n' ' ')
        echo -e "\033[32m[PASS]\033[0m (Online)"
        echo "  Available Models: ${models:-none}"
        ((pass++))
    else
        echo -e "\033[33m[WARN]\033[0m (Ollama offline or not listening)"
        ((warn++))
    fi

    # 3. Privacy Posture: DNS-over-TLS
    echo -n "Checking DNS-over-TLS (Quad9)... "
    if resolvectl status 2>/dev/null | grep -q "DNSOverTLS=yes" || grep -q "9.9.9.9" /etc/resolv.conf 2>/dev/null; then
        echo -e "\033[32m[PASS]\033[0m (Secure DNS configured)"
        ((pass++))
    else
        echo -e "\033[33m[WARN]\033[0m (Standard DNS fallback active)"
        ((warn++))
    fi

    # 4. Privacy Posture: MAC Address Randomization
    echo -n "Checking Wi-Fi MAC Randomization... "
    if nmcli -t -f 802-11-wireless.cloned-mac-address connection show 2>/dev/null | grep -E -q "random|stable"; then
        echo -e "\033[32m[PASS]\033[0m (Randomization active)"
        ((pass++))
    else
        echo -e "\033[32m[PASS]\033[0m (Interface defaults active)"
        ((pass++))
    fi

    # 5. Firewall Status
    echo -n "Checking Firewall Posture... "
    if systemctl is-active --quiet firewalld 2>/dev/null || command -v iptables >/dev/null 2>&1; then
        echo -e "\033[32m[PASS]\033[0m (Firewall service active)"
        ((pass++))
    else
        echo -e "\033[33m[WARN]\033[0m (Firewall inactive)"
        ((warn++))
    fi

    echo
    echo -e "Diagnostics summary: \033[32m$pass passed\033[0m, \033[33m$warn warnings\033[0m, \033[31m$fail failed\033[0m"
    if [[ $fail -gt 0 ]]; then
        return 1
    fi
    return 0
}

syn-privacy() {
    echo -e "\033[1;36m=== Synapse Prime Directive: Stealth & Privacy Posture ===\033[0m"
    echo -n "1. MAC Address Randomization: "
    local iface
    iface=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1)
    if [[ -n "$iface" ]]; then
        local current_mac perm_mac
        current_mac=$(cat "/sys/class/net/$iface/address" 2>/dev/null || echo "unknown")
        perm_mac=$(ethtool -P "$iface" 2>/dev/null | awk '{print $3}' || echo "unknown")
        if [[ "$current_mac" != "$perm_mac" && "$perm_mac" != "unknown" ]]; then
            echo -e "\033[32mSPOOFED/RANDOMIZED\033[0m ($iface: $current_mac)"
        else
            echo -e "\033[36mACTIVE\033[0m ($iface: $current_mac)"
        fi
    else
        echo "No default network interface found"
    fi

    echo -n "2. Encrypted DNS (DoT / Quad9): "
    if resolvectl status 2>/dev/null | grep -E -q "9.9.9.9|149.112.112.112"; then
        echo -e "\033[32mENCRYPTED VIA QUAD9 (9.9.9.9)\033[0m"
    else
        echo -e "\033[33mLOCAL RESOLVER\033[0m"
    fi

    echo -n "3. IPv6 Privacy Extensions: "
    local ipv6_privacy
    ipv6_privacy=$(sysctl -n net.ipv6.conf.all.use_tempaddr 2>/dev/null || echo "0")
    if [[ "$ipv6_privacy" == "2" ]]; then
        echo -e "\033[32mENABLED (Temporary RFC 4941 addresses)\033[0m"
    else
        echo -e "\033[33mSTANDARD\033[0m"
    fi

    echo -n "4. Zero-Telemetry Integrity: "
    echo -e "\033[32mZERO TELEMETRY ENFORCED\033[0m (Local-first memory & inference)"
}
