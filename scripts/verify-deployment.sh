#!/usr/bin/env bash
# ==============================================================================
# CS223 Term Project | Read-only OpenStack Kolla Ansible Deployment Verification
# ==============================================================================
# Repository : https://github.com/ronnakrit303/CS223-TermProject
# Place at   : scripts/verify-deployment.sh
# Tested for : Ubuntu 24.04, OpenStack 2026.1, Kolla Ansible Multinode (Non-HA)
# Nodes      : controller01 (192.168.1.160), compute01 (192.168.1.7)
#
# PURPOSE
#   Verify the running deployment without changing any OpenStack resource,
#   service, container, configuration, or operating-system setting.
#
# DEFAULT BEHAVIOR
#   - Local-only execution on controller01 (no SSH to compute01)
#   - Check Horizon HTTP response (200 or redirect to login)
#   - Authenticate via /etc/kolla/admin-openrc.sh (token VALUE is never shown)
#   - Query Keystone, Nova, Placement-backed hypervisor visibility, Neutron,
#     Glance, and the existing CirrOS VM through OpenStack CLI
#   - Check the local Docker containers if Docker is accessible (optional)
#   - Do not run Kolla prechecks/deploy/reconfigure or create/delete resources
#
# SECURITY
#   - NEVER commit /etc/kolla/admin-openrc.sh or /etc/kolla/clouds.yaml.
#   - Results intentionally do not include full API JSON, OpenStack token IDs,
#     passwords, SSH keys, or console URLs.
#   - Avoid `bash -x`, `set -x`, or redirecting raw credentials to a public log.
#   - Check screenshots before adding them to a public GitHub repository.
#   - This check is a snapshot, not continuous monitoring or an HA assessment.
#
# EXIT STATUS
#   0: All REQUIRED checks pass; optional checks may WARN/SKIP.
#   1: One or more REQUIRED checks failed.
#   2: Local prerequisites/credentials could not be loaded.
#
# USAGE
#   chmod +x scripts/verify-deployment.sh
#   ./scripts/verify-deployment.sh
#   ./scripts/verify-deployment.sh --no-docker
#   ./scripts/verify-deployment.sh --help
#   ./scripts/verify-deployment.sh --openrc /path/to/admin-openrc.sh \
#       --cli /path/to/openstack --controller 192.168.1.160
#
# REFERENCES
#   docs/04-kolla-deployment.md
#   docs/05-deployment-verification.md
#   docs/06-troubleshooting.md
#   docs/07-handover.md
# ==============================================================================

set -uo pipefail
IFS=$'\n\t'

# ----- Configuration: override using documented flags only -------------------
CONTROLLER_IP="192.168.1.160"
CONTROLLER_HOST="controller01"
COMPUTE_HOST="compute01"
NETWORK_NAME="cs223-private-net"
SUBNET_NAME="cs223-private-subnet"
INSTANCE_NAME="cs223-test-vm"
IMAGE_NAME="cirros-0.6.3"
FLAVOR_NAME="cs223.tiny"
GUEST_IP="10.10.10.117"
EXPECTED_NETWORK_MTU="1400"
EXPECTED_SUBNET_CIDR="10.10.10.0/24"
OPENRC_PATH="/etc/kolla/admin-openrc.sh"
CLI_PATH="${HOME}/openstack-cli-venv/bin/openstack"
CHECK_DOCKER=1

# Read-only output accounting: optional checks do not fail the script.
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

usage() {
  cat <<'EOF'
Usage: ./scripts/verify-deployment.sh [options]

Read-only verification of the CS223 Kolla Ansible Multinode deployment.
Run this on controller01. No VM, Neutron network, or service is modified.

Options:
  --openrc PATH        Admin openrc file (default: /etc/kolla/admin-openrc.sh)
  --cli PATH           OpenStack CLI binary (default: ~/openstack-cli-venv/bin/openstack)
  --controller IP      Horizon/API controller IP (default: 192.168.1.160)
  --no-docker          Skip optional local Docker check
  -h, --help           Display this help

Exit codes: 0=all required checks passed, 1=required check failed,
            2=missing local prerequisite/credential.

The tool uses OpenStack read-only GET/list/show calls. It neither deploys,
reconfigures, restarts, creates, nor deletes anything.
EOF
}

pass() { printf '  [PASS] %s\n' "$*"; PASS_COUNT=$((PASS_COUNT + 1)); }
warn() { printf '  [WARN] %s\n' "$*"; WARN_COUNT=$((WARN_COUNT + 1)); }
fail() { printf '  [FAIL] %s\n' "$*"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
skip() { printf '  [SKIP] %s\n' "$*"; SKIP_COUNT=$((SKIP_COUNT + 1)); }
heading() { printf '\n== %s ==\n' "$*"; }

# Argument parsing deliberately never uses eval.
while (($# > 0)); do
  case "$1" in
    --openrc|--cli|--controller)
      option="$1"
      if (($# < 2)) || [[ -z "$2" ]]; then
        printf 'ERROR: %s requires a non-empty value\n' "$option" >&2
        exit 2
      fi
      case "$option" in
        --openrc) OPENRC_PATH="$2" ;;
        --cli) CLI_PATH="$2" ;;
        --controller) CONTROLLER_IP="$2" ;;
      esac
      shift 2
      ;;
    --no-docker) CHECK_DOCKER=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'ERROR: unknown option %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

printf 'CS223 | Kolla Ansible Deployment Verification (READ ONLY)\n'
printf 'Controller: %s | Compute: %s | Test VM: %s\n' \
  "$CONTROLLER_HOST" "$COMPUTE_HOST" "$INSTANCE_NAME"
printf 'This script does not change the existing OpenStack deployment.\n'

# ----- Local prerequisites ----------------------------------------------------
heading "1. Prerequisites"
if ! command -v python3 >/dev/null 2>&1; then
  printf '  [FAIL] python3 is required for parsing OpenStack JSON.\n' >&2
  exit 2
fi
pass "python3 is installed"

if [[ ! -x "$CLI_PATH" ]]; then
  if command -v openstack >/dev/null 2>&1; then
    CLI_PATH="$(command -v openstack)"
    warn "Using OpenStack CLI from PATH instead of ~/openstack-cli-venv"
  else
    printf '  [FAIL] OpenStack CLI not found. Use --cli /path/to/openstack\n' >&2
    exit 2
  fi
fi
pass "OpenStack CLI available at $CLI_PATH"

if [[ ! -r "$OPENRC_PATH" ]]; then
  printf '  [FAIL] Cannot read %s (check ownership/permissions).\n' "$OPENRC_PATH" >&2
  exit 2
fi

# OpenRC is trusted LOCAL configuration. Never display its content or use -x.
# Temporarily disable nounset for compatibility with older openrc scripts.
set +u
# shellcheck disable=SC1090
if ! source "$OPENRC_PATH" >/dev/null 2>&1; then
  set -u
  printf '  [FAIL] Could not load OpenStack credentials from the local openrc file.\n' >&2
  exit 2
fi
set -u
pass "OpenStack environment loaded (credentials hidden)"

# Prevent long waits when an OpenStack API is unavailable. Environment options
# are applied to the CLI process; they do not alter the deployment.
export OS_CLIENT_TIMEOUT="${OS_CLIENT_TIMEOUT:-15}"
export OS_CONNECT_RETRIES="${OS_CONNECT_RETRIES:-1}"

# ----- Python JSON validators ------------------------------------------------
# Each validator prints ONLY a curated, non-sensitive status line.
# Full API output stays in shell memory; never print it or save to files.
# The final Python argument indicates which expected resource to validate.
validate_json() {
  python3 -c '
import json
import re
import sys

kind, controller, compute, network, subnet, instance, image, flavor, guest_ip, mtu, cidr = sys.argv[1:]
try:
    data = json.load(sys.stdin)
except (ValueError, UnicodeDecodeError) as exc:
    print("OpenStack CLI output is not valid JSON")
    sys.exit(1)

def norm(s):
    return re.sub(r"[^a-z0-9]", "", str(s).lower())

def field(row, *names, default=""):
    index = {norm(k): v for k, v in row.items()}
    for name in names:
        value = index.get(norm(name))
        if value is not None:
            return value
    return default

def value_is_up(s):
    return str(s).strip().lower() in {"up", "true", ":-)", "alive", "1"} or s is True

def require(ok, success, problem):
    print(success if ok else problem)
    sys.exit(0 if ok else 1)

if kind == "compute-services":
    if not isinstance(data, list):
        require(False, "", "Nova services: unexpected JSON structure")
    needed = [
        ("nova-scheduler", controller),
        ("nova-conductor", controller),
        ("nova-compute", compute),
    ]
    bad = []
    for binary, host in needed:
        candidates = [row for row in data
            if str(field(row, "Binary")).lower() == binary
            and str(field(row, "Host")).lower() == host.lower()]
        if not candidates:
            bad.append(binary + " on " + host + " missing")
            continue
        row = candidates[0]
        if not value_is_up(field(row, "State")):
            bad.append(binary + " on " + host + " not UP")
        if str(field(row, "Status", default="enabled")).lower() != "enabled":
            bad.append(binary + " on " + host + " disabled")
    require(not bad,
            "Nova scheduler/conductor and nova-compute are enabled/UP",
            "; ".join(bad))

elif kind == "hypervisors":
    if not isinstance(data, list):
        require(False, "", "Hypervisor list: unexpected JSON structure")
    matches = [row for row in data
        if str(field(row, "Hypervisor Hostname", "Hypervisor Host", "Hostname"))
             == compute]
    require(bool(matches) and any(value_is_up(field(r, "State")) for r in matches),
            "Hypervisor " + compute + " is visible and UP",
            "Hypervisor " + compute + " missing or not UP")

elif kind == "network-agents":
    if not isinstance(data, list):
        require(False, "", "Neutron agents: unexpected JSON structure")
    needed = [
        (controller, "dhcp"), (controller, "l3"),
        (controller, "metadata"), (controller, "open vswitch"),
        (compute, "open vswitch"),
    ]
    failures = []
    for host, agent_type in needed:
        rows = [r for r in data
                if str(field(r, "Host")).lower() == host.lower()
                and agent_type in str(field(r, "Agent Type", "Agent_Type")).lower()]
        if not rows:
            failures.append(agent_type + " agent on " + host + " missing")
            continue
        if not any(value_is_up(field(r, "Alive")) for r in rows):
            failures.append(agent_type + " agent on " + host + " not alive")
    require(not failures,
            "Neutron DHCP/L3/Metadata/OVS agents alive on expected nodes (5 roles)",
            "; ".join(failures))

elif kind == "network":
    if not isinstance(data, dict):
        require(False, "", "Neutron network: unexpected JSON structure")
    name = str(field(data, "name"))
    status = str(field(data, "status")).upper()
    network_mtu = str(field(data, "mtu"))
    net_type = str(field(data, "provider:network_type", "provider_network_type"))
    ok = name == network and status == "ACTIVE" and network_mtu == mtu
    if net_type:
        ok = ok and net_type.lower() == "vxlan"
    require(ok,
            "Network " + network + " ACTIVE (VXLAN, MTU " + network_mtu + ")",
            "Network " + network + " has unexpected status/MTU/type")

elif kind == "subnet":
    if not isinstance(data, dict):
        require(False, "", "Neutron subnet: unexpected JSON structure")
    actual_cidr = str(field(data, "cidr"))
    dhcp = field(data, "enable_dhcp", "Enable DHCP")
    dhcp_on = dhcp is True or str(dhcp).lower() == "true"
    require(actual_cidr == cidr and dhcp_on,
            "Subnet " + subnet + " " + actual_cidr + ", DHCP enabled",
            "Subnet " + subnet + " CIDR/DHCP differs from Lab baseline")

elif kind == "image":
    if not isinstance(data, dict):
        require(False, "", "Glance image: unexpected JSON structure")
    actual_status = str(field(data, "status")).lower()
    require(actual_status == "active",
            "Glance image " + image + " ACTIVE",
            "Glance image " + image + " is not ACTIVE")

elif kind == "flavor":
    if not isinstance(data, dict):
        require(False, "", "Flavor: unexpected JSON structure")
    ram = str(field(data, "ram"))
    vcpus = str(field(data, "vcpus"))
    disk = str(field(data, "disk"))
    require(ram == "512" and vcpus == "1" and disk == "1",
            "Flavor " + flavor + " = 1 vCPU / 512 MB / 1 GB",
            "Flavor " + flavor + " differs from Lab baseline")

elif kind == "server":
    if not isinstance(data, dict):
        require(False, "", "Nova server: unexpected JSON structure")
    status = str(field(data, "status")).upper()
    host = str(field(data, "OS-EXT-SRV-ATTR:host", "hypervisor_hostname", "host"))
    addr = str(field(data, "addresses", "networks"))
    ok = status == "ACTIVE" and host == compute
    # An OpenStack client may omit the addresses field; do not fail merely
    # because this optional field has a different display representation.
    if addr and guest_ip not in addr:
        ok = False
    require(ok,
            "Instance " + instance + " ACTIVE on " + compute +
            (" (IP " + guest_ip + ")" if guest_ip in addr else ""),
            "Instance " + instance + " is not ACTIVE/on expected compute/IP")

else:
    print("Internal error: unknown validation kind")
    sys.exit(1)
' \
    "$1" "$CONTROLLER_HOST" "$COMPUTE_HOST" \
    "$NETWORK_NAME" "$SUBNET_NAME" "$INSTANCE_NAME" \
    "$IMAGE_NAME" "$FLAVOR_NAME" "$GUEST_IP" \
    "$EXPECTED_NETWORK_MTU" "$EXPECTED_SUBNET_CIDR"
}

# Run a read-only OpenStack CLI command, validate its JSON without displaying
# the raw output, and mark the REQUIRED check PASS/FAIL. No `eval` is used.
check_openstack_json() {
  local label="$1" kind="$2" output result
  shift 2
  if ! output=$("$CLI_PATH" "$@" -f json 2>/dev/null); then
    fail "$label — OpenStack API command failed (details hidden)"
    return 0
  fi
  if result=$(printf '%s' "$output" | validate_json "$kind" 2>/dev/null); then
    pass "$label — $result"
  else
    fail "$label — ${result:-invalid API response}"
  fi
}

# ----- HTTP / Horizon ---------------------------------------------------------
heading "2. Horizon HTTP availability"
if command -v curl >/dev/null 2>&1; then
  # Do not follow redirects (which can expose auth URL/query parameters).
  # A 302 to the Login page means Horizon is answering HTTP, not that
  # browser-based admin login has been re-verified during this run.
  http_status=$(curl --silent --output /dev/null \
    --connect-timeout 4 --max-time 8 \
    --write-out '%{http_code}' "http://${CONTROLLER_IP}/" 2>/dev/null) || http_status=""
  case "$http_status" in
    200|301|302|303|307|308)
      pass "Horizon endpoint responds with HTTP ${http_status}"
      ;;
    "") fail "Horizon endpoint not reachable at http://${CONTROLLER_IP}/" ;;
    *) fail "Horizon endpoint returned HTTP ${http_status}" ;;
  esac
else
  fail "curl not installed, cannot verify Horizon HTTP availability"
fi

# ----- Keystone authentication ------------------------------------------------
heading "3. Keystone authentication"
if expires=$("$CLI_PATH" token issue -f value -c expires 2>/dev/null); then
  if [[ -n "$expires" ]]; then
    pass "Keystone issued a valid token (token value not displayed)"
  else
    fail "Keystone returned an empty token expiry field"
  fi
else
  fail "Keystone token issue failed (credentials/API/Keystone may be unavailable)"
fi

# ----- Service-plane validation ----------------------------------------------
heading "4. Nova / Hypervisor"
check_openstack_json "Nova compute services" "compute-services" compute service list
check_openstack_json "Nova hypervisor" "hypervisors" hypervisor list

heading "5. Neutron / Networking"
check_openstack_json "Neutron agents" "network-agents" network agent list
check_openstack_json "Neutron private network" "network" network show "$NETWORK_NAME"
check_openstack_json "Neutron private subnet" "subnet" subnet show "$SUBNET_NAME"

heading "6. Glance / Flavor / VM"
check_openstack_json "Glance CirrOS image" "image" image show "$IMAGE_NAME"
check_openstack_json "Nova test flavor" "flavor" flavor show "$FLAVOR_NAME"
check_openstack_json "Nova test instance" "server" server show "$INSTANCE_NAME"

# ----- Docker local visibility (OPTIONAL) ------------------------------------
heading "7. Docker containers on local controller (optional)"
if ((CHECK_DOCKER == 0)); then
  skip "Docker check disabled with --no-docker"
elif ! command -v docker >/dev/null 2>&1; then
  skip "Docker CLI not installed; remote Nova/Neutron API checks were still performed"
else
  # List-only. Do not inspect environment variables, healthcheck secrets,
  # container configs, or raw log contents.
  if docker_lines=$(docker ps --format '{{.Names}}' 2>/dev/null); then
    docker_count=$(printf '%s\n' "$docker_lines" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')
    if ((docker_count > 0)); then
      pass "Docker accessible: ${docker_count} running container(s) on local controller"
    else
      warn "Docker accessible but no running containers were listed"
    fi
  else
    skip "Docker permission unavailable for current user; no sudo attempted"
  fi
fi

# ----- Finished ---------------------------------------------------------------
heading "Summary"
printf '  PASS: %d | WARN: %d | FAIL: %d | SKIP: %d\n' \
  "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT" "$SKIP_COUNT"
if ((FAIL_COUNT > 0)); then
  printf '  RESULT: FAILED — one or more required read-only checks failed.\n'
  printf '  Check docs/06-troubleshooting.md; do not re-deploy automatically.\n'
  exit 1
fi
printf '  RESULT: PASSED — required checks succeeded at verification time.\n'
printf '  Note: guest login, Floating IP, internet egress, VM-to-VM traffic and HA\n'
printf '        are NOT validated by this script. See docs/05 and docs/07.\n'
exit 0
