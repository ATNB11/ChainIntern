"""
app.py — ChainIntern Flask Backend

Architecture:
  - Flask serves HTML pages and provides ABI + contract address to the frontend.
  - ALL blockchain transactions are signed and sent by MetaMask in the browser.
  - Flask never signs transactions or holds private keys.

Run:  python app.py
"""

from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
from pathlib import Path
import json

app = Flask(__name__)
CORS(app)

BASE      = Path(__file__).parent
ABI_FILE  = BASE / "contracts" / "abi.json"
ADDR_FILE = BASE / "contract_address.txt"

def load_abi():
    return json.loads(ABI_FILE.read_text()) if ABI_FILE.exists() else []

def get_contract_address():
    return ADDR_FILE.read_text().strip() if ADDR_FILE.exists() else None

# ── Page Routes ───────────────────────────────────────────────────────────────

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/admin")
def admin_dashboard():
    return render_template("admin/dashboard.html")

@app.route("/recruiter")
def recruiter_dashboard():
    return render_template("recruiter/dashboard.html")

@app.route("/student")
def student_dashboard():
    return render_template("student/dashboard.html")

# ── API ───────────────────────────────────────────────────────────────────────

@app.route("/api/contract-info")
def contract_info():
    return jsonify({"abi": load_abi(), "address": get_contract_address()})

@app.route("/api/save-contract", methods=["POST"])
def save_contract():
    data = request.json or {}
    if "address" in data: ADDR_FILE.write_text(data["address"])
    if "abi"     in data: ABI_FILE.write_text(json.dumps(data["abi"], indent=2))
    return jsonify({"ok": True})

@app.route("/api/compile", methods=["POST"])
def compile_contract():
    """Compile .sol → return ABI + bytecode. Deployment done by MetaMask."""
    try:
        from solcx import compile_source, install_solc, get_installed_solc_versions
        installed  = [str(v) for v in get_installed_solc_versions()]
        compatible = [v for v in installed if v.startswith("0.8.")]
        if not compatible:
            install_solc("0.8.0"); compatible = ["0.8.0"]
        needed   = compatible[-1]
        source   = (BASE / "contracts" / "InternshipTracker.sol").read_text()
        compiled = compile_source(source, output_values=["abi", "bin"], solc_version=needed)
        key      = next(k for k in compiled if "InternshipTracker" in k)
        abi      = compiled[key]["abi"]
        bytecode = "0x" + compiled[key]["bin"]
        ABI_FILE.write_text(json.dumps(abi, indent=2))
        return jsonify({"ok": True, "abi": abi, "bytecode": bytecode, "solc": needed})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500

# ── Run ───────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    addr = get_contract_address()
    print(f"  {'✅ Contract: ' + addr if addr else '⚠️  No contract deployed yet — use Admin → Deploy'}")
    print("  🌐 http://localhost:5000\n")
    app.run(debug=True, port=5000)
