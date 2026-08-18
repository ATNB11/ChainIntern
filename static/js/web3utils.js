// ─── ChainIntern — Web3 Shared Utilities ─────────────────────────────────────
//
//  Architecture:
//    • Flask serves the ABI + contract address via /api/contract-info
//    • MetaMask (injected window.ethereum) is used for ALL transactions
//    • Ganache runs at http://127.0.0.1:7545  Chain ID: 1337 (0x539)
//
// ─────────────────────────────────────────────────────────────────────────────

let web3, contract, userAccount;

const GANACHE_CHAIN_ID_HEX = "0x539"; // 1337
const GANACHE_NETWORK_PARAMS = {
    chainId:         GANACHE_CHAIN_ID_HEX,
    chainName:       "Ganache Local",
    nativeCurrency:  { name: "Ether", symbol: "ETH", decimals: 18 },
    rpcUrls:         ["http://127.0.0.1:7545"],
    blockExplorerUrls: [],
};

// ── Fetch contract ABI + address from Flask ───────────────────────────────────
async function loadContractInfo() {
    const res = await fetch("/api/contract-info");
    return await res.json();
}

// ── Ensure MetaMask is pointed at Ganache (Chain ID 1337) ─────────────────────
async function ensureGanacheNetwork() {
    const currentChain = await window.ethereum.request({ method: "eth_chainId" });
    if (currentChain === GANACHE_CHAIN_ID_HEX) return true;

    try {
        // Try switching first (works if user added the network before)
        await window.ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: GANACHE_CHAIN_ID_HEX }],
        });
        return true;
    } catch (switchErr) {
        if (switchErr.code === 4902) {
            // Network not in MetaMask — add it automatically
            try {
                await window.ethereum.request({
                    method: "wallet_addEthereumChain",
                    params: [GANACHE_NETWORK_PARAMS],
                });
                return true;
            } catch (addErr) {
                showToast("Failed to add Ganache network to MetaMask: " + addErr.message, "error");
                return false;
            }
        }
        showToast("Please switch MetaMask to Ganache (Chain ID 1337) and try again.", "error");
        return false;
    }
}

// ── Main entry: connect MetaMask + initialise contract ────────────────────────
async function initWeb3() {
    // 1. MetaMask present?
    if (typeof window.ethereum === "undefined") {
        showToast("MetaMask not found — install it from metamask.io", "error");
        return false;
    }

    try {
        // 2. Ensure we're on Ganache
        const onGanache = await ensureGanacheNetwork();
        if (!onGanache) return false;

        // 3. Request account access (triggers MetaMask popup)
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        userAccount = accounts[0];
        web3 = new Web3(window.ethereum);

        // 4. Load ABI + address and build contract instance
        const info = await loadContractInfo();
        if (!info.address) {
            showToast("Contract not deployed yet — go to Admin → Deploy Contract first.", "warn");
        } else if (info.abi && info.abi.length) {
            contract = new web3.eth.Contract(info.abi, info.address);
        }

        // 5. React to account or chain changes
        window.ethereum.on("accountsChanged", (accs) => {
            userAccount = accs[0] || null;
            document.querySelectorAll(".wallet-addr").forEach(el => {
                el.textContent = userAccount ? shortenAddr(userAccount) : "Not connected";
            });
            if (typeof onAccountChanged === "function") onAccountChanged(userAccount);
        });

        window.ethereum.on("chainChanged", () => {
            showToast("Network changed — reloading…", "info");
            setTimeout(() => location.reload(), 800);
        });

        return true;
    } catch (e) {
        showToast("MetaMask connection failed: " + (e.message || e), "error");
        return false;
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function shortenAddr(addr) {
    if (!addr) return "";
    return addr.slice(0, 6) + "…" + addr.slice(-4);
}

function tsToDate(ts) {
    if (!ts || ts == 0) return "-";
    return new Date(Number(ts) * 1000).toLocaleString();
}

const STATUS_COLORS = {
    submitted:    "#6C63FF",
    under_review: "#F59E0B",
    shortlisted:  "#3B82F6",
    accepted:     "#10B981",
    rejected:     "#EF4444",
};

const STATUS_LABELS = {
    submitted:    "Submitted",
    under_review: "Under Review",
    shortlisted:  "Shortlisted",
    accepted:     "Accepted",
    rejected:     "Rejected",
};

function statusBadge(s) {
    const color = STATUS_COLORS[s] || "#888";
    const label = STATUS_LABELS[s] || s;
    return `<span class="badge" style="background:${color}22;color:${color};border:1px solid ${color}55">${label}</span>`;
}

function showToast(msg, type = "info") {
    const t = document.getElementById("toast");
    if (!t) return;
    t.textContent = msg;
    t.className   = "toast show " + type;
    setTimeout(() => t.className = "toast", 3500);
}

function showLoader(show) {
    const l = document.getElementById("loader");
    if (l) l.style.display = show ? "flex" : "none";
}
