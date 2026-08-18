# ⛓️ ChainIntern — Blockchain Internship Tracking System

A full-stack dApp using Flask, Solidity, Ganache, and MetaMask.

---

## 🧱 Tech Stack

| Layer        | Technology                    |
|-------------|-------------------------------|
| Blockchain  | Ganache (local PoA network)   |
| Smart Contract | Solidity 0.8.x            |
| IDE (compile) | Remix IDE                  |
| Wallet      | MetaMask                      |
| Backend     | Flask (Python)                |
| Frontend    | HTML/CSS/JS (static via Flask)|
| Web3 bridge | Web3.js v4                    |

---

## ⚙️ Consensus Algorithm: Proof of Authority (PoA)

**Why PoA for a campus environment?**

1. **Trusted validators** — University servers are known entities; no need for mining or token staking
2. **Fast finality** — Transactions finalize in <1 second; critical for real-time status updates
3. **Energy efficient** — No computational waste; suitable for academic infrastructure
4. **Ganache compatibility** — Ganache uses PoA simulation by default
5. **Permissioned access** — Only admin-registered wallets can write to the ledger

---

## 🚀 Setup Instructions

### Step 1: Install Ganache

Download from: https://trufflesuite.com/ganache/

- Open Ganache → Create a **New Workspace**
- Set RPC: `HTTP://127.0.0.1:7545`
- Note the 10 pre-funded accounts

### Step 2: Configure MetaMask

1. Install MetaMask browser extension
2. Add Custom Network:
   - Network Name: `Ganache Local`
   - RPC URL: `http://127.0.0.1:7545`
   - Chain ID: `1337`
   - Currency: `ETH`
3. Import a Ganache account using its private key

### Step 3: Compile Smart Contract (Remix IDE)

1. Open https://remix.ethereum.org
2. Create new file → paste contents of `contracts/InternshipTracker.sol`
3. Go to **Solidity Compiler** tab → Select version `0.8.x` → Click **Compile**
4. Click **Compilation Details** → Copy the `object` field from `bytecode`

### Step 4: Install Python Dependencies

```bash
cd blockchain_internship
pip install -r requirements.txt
```

### Step 5: Run Flask App

```bash
python app.py
```

Open: http://localhost:5000

---

## 📋 Usage Flow

### Admin (Account 0 — deployer)
1. Go to `/admin` → Connect MetaMask (use Ganache Account 0)
2. Go to **Deploy Contract** → Paste bytecode from Remix → Click **Deploy Contract**
3. Go to **Register Recruiter** → Enter company name + wallet address (from Ganache)
4. Go to **Register Student** → Enter student name + wallet address
5. View **Full Ledger** for audit trail

### Recruiter (Registered wallet)
1. Go to `/recruiter` → Connect MetaMask (use registered recruiter account)
2. Go to **Post Internship** → Fill in role, description, location → Post
3. Go to **Applications** → View all student applications
4. Click **Update** to change status (under_review → shortlisted → accepted/rejected)
5. Click **History** to see full immutable audit trail

### Student (Registered wallet)
1. Go to `/student` → Connect MetaMask (use registered student account)
2. Go to **Browse Openings** → View all active internships
3. Click **Apply Now** → Confirm on-chain application
4. Go to **My Applications** → Track statuses
5. Use **Track Status** with any App ID to see the blockchain timeline

---

## 🔒 Role-Based Access Control

| Action                    | Admin | Recruiter | Student |
|--------------------------|-------|-----------|---------|
| Deploy contract          | ✅    | ❌        | ❌      |
| Register recruiters      | ✅    | ❌        | ❌      |
| Register students        | ✅    | ❌        | ❌      |
| Post internship          | ❌    | ✅        | ❌      |
| Update application status| ❌    | ✅ (own)  | ❌      |
| Apply for internship     | ❌    | ❌        | ✅      |
| View own applications    | ❌    | ❌        | ✅      |
| View full ledger         | ✅    | ❌        | ❌      |

---

## 📐 Smart Contract Architecture

```
InternshipTracker.sol
├── Roles: admin, isRecruiter[], isStudent[]
├── Structs: Internship, Application, StatusEntry
├── Admin Functions
│   ├── registerRecruiter(wallet, name)
│   └── registerStudent(wallet, name)
├── Recruiter Functions
│   ├── postInternship(role, desc, location)
│   └── updateApplicationStatus(appId, status, note) — APPEND ONLY
├── Student Functions
│   └── applyForInternship(internshipId)
└── View Functions
    ├── getStatusHistory(appId) → StatusEntry[]
    ├── getStudentApplications(addr) → uint256[]
    ├── getInternshipApplications(id) → uint256[]
    └── getRole(wallet) → string
```

---

## 📜 Status Flow (Append-Only)

```
submitted → under_review → shortlisted → accepted
                                      → rejected
```

Each status change is a new `StatusEntry` pushed to the array.
**Old entries are NEVER overwritten.** The full history is always readable.

---

## 🗂️ Project Structure

```
blockchain_internship/
├── app.py                          # Flask backend
├── requirements.txt
├── contract_address.txt            # Auto-generated after deploy
├── contracts/
│   └── InternshipTracker.sol       # Solidity smart contract
├── static/
│   ├── css/style.css               # Global design system
│   └── js/web3utils.js             # Shared Web3 utilities
└── templates/
    ├── index.html                  # Landing page
    ├── admin/dashboard.html        # Admin portal
    ├── recruiter/dashboard.html    # Recruiter portal
    └── student/dashboard.html      # Student portal
```

---

## 👥 Authors

- **B B Varun Kumar** — [@ATNB11](https://github.com/ATNB11)
- **Praneet V M** — [@Praneet-Vasudev-Mahendrakar](https://github.com/Praneet-Vasudev-Mahendrakar)
