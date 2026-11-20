#!/bin/bash
#
# Push a disk mirror produced by the generate playbooks into a mirror registry.
#
# Replaces the one-off scripts/mirror-*-m1.sh commands. Each catalog is a
# separate oc-mirror v2 push. The release payload is limited to one image and
# one layer at a time. Operator catalogs are not.
#
# Usage:
#   scripts/mirror-to-registry.sh --vars my_variables.yml
#   scripts/mirror-to-registry.sh --vars my_variables.yml --only release
#   scripts/mirror-to-registry.sh --bundle /images/bundle --registry host:8443 --prefix sig_ops_dev
#
# Values in the vars file:
#   destination
#   oc_mirror_config.cache_dir
#   oc_mirror_config.authfile
#   oc_mirror_config.push.registry              host:port, no scheme
#   oc_mirror_config.push.repository_prefix     for example sig_ops_dev
#   oc_mirror_config.push.dest_tls_verify       true or false (default false)
#   oc_mirror_config.push.parallel_images       release push only (default 1)
#   oc_mirror_config.push.parallel_layers       release push only (default 1)
#   oc_mirror_config.push.repositories.*        release, redhat, community, certified
#
# Command-line flags override the vars file.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/mirror-to-registry.sh [options]

Push disk content from an oc-mirror v2 bundle to a mirror registry.

Options:
  --vars FILE            Ansible vars file (destination, oc_mirror_config)
  --bundle DIR           Bundle directory (overrides destination)
  --registry HOST:PORT   Mirror registry (overrides push.registry)
  --prefix NAME          Repository prefix (overrides push.repository_prefix)
  --cache DIR            oc-mirror cache directory
  --authfile FILE        Registry auth file (default ~/.docker/config.json)
  --dest-tls-verify BOOL Verify the registry TLS certificate (default false)
  --only LIST            Comma-separated: release,redhat,community,certified
                         Default is all. Missing catalogs are skipped for all,
                         and are an error when named in --only.
  --parallel-images N    Release push only (default 1)
  --parallel-layers N    Release push only (default 1)
  --dry-run              Print the oc-mirror commands and do not run them
  -h, --help             Show this help

Catalog layout written by the Ansible roles:
  release    bin/image-config.yaml              openshift-release-dev
  redhat     bin/redhat-operator-images.yaml    operators/redhat
  community  bin/community-operator-images.yaml operators/community
  certified  bin/certified-operator-images.yaml operators/certified
EOF
}

VARS_FILE=""
CLI_BUNDLE=""
CLI_REGISTRY=""
CLI_PREFIX=""
CLI_PREFIX_SET=0
CLI_CACHE=""
CLI_AUTHFILE=""
CLI_TLS=""
CLI_ONLY=""
CLI_PARALLEL_IMAGES=""
CLI_PARALLEL_LAYERS=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vars)
      VARS_FILE=${2:?--vars requires a file}
      shift 2
      ;;
    --bundle)
      CLI_BUNDLE=${2:?--bundle requires a directory}
      shift 2
      ;;
    --registry)
      CLI_REGISTRY=${2:?--registry requires host:port}
      shift 2
      ;;
    --prefix)
      if [[ $# -lt 2 ]]; then
        echo "--prefix requires a value. Use --prefix '' for no repository prefix." >&2
        exit 1
      fi
      CLI_PREFIX=$2
      CLI_PREFIX_SET=1
      shift 2
      ;;
    --cache)
      CLI_CACHE=${2:?--cache requires a directory}
      shift 2
      ;;
    --authfile)
      CLI_AUTHFILE=${2:?--authfile requires a file}
      shift 2
      ;;
    --dest-tls-verify)
      CLI_TLS=${2:?--dest-tls-verify requires true or false}
      shift 2
      ;;
    --only)
      CLI_ONLY=${2:?--only requires a catalog list}
      shift 2
      ;;
    --parallel-images)
      CLI_PARALLEL_IMAGES=${2:?--parallel-images requires a number}
      shift 2
      ;;
    --parallel-layers)
      CLI_PARALLEL_LAYERS=${2:?--parallel-layers requires a number}
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

VARS_BUNDLE=""
VARS_REGISTRY=""
VARS_PREFIX=""
VARS_CACHE=""
VARS_AUTHFILE=""
VARS_TLS=""
VARS_PARALLEL_IMAGES=""
VARS_PARALLEL_LAYERS=""
VARS_REPO_RELEASE=""
VARS_REPO_REDHAT=""
VARS_REPO_COMMUNITY=""
VARS_REPO_CERTIFIED=""

if [[ -n "$VARS_FILE" ]]; then
  if [[ ! -f "$VARS_FILE" ]]; then
    echo "Vars file not found: $VARS_FILE" >&2
    exit 1
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to read $VARS_FILE" >&2
    exit 1
  fi
  eval "$(python3 - "$VARS_FILE" <<'PY'
import shlex
import sys

try:
    import yaml
except ImportError:
    sys.stderr.write("PyYAML is required to read the vars file\n")
    sys.exit(1)

def quote(value):
    if value is None:
        return "''"
    return shlex.quote(str(value))

def as_bool(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    text = str(value).strip().lower()
    if text in ("1", "true", "yes"):
        return "true"
    if text in ("0", "false", "no", ""):
        return "false"
    sys.stderr.write("dest_tls_verify must be true or false\n")
    sys.exit(1)

def normalize_registry(value):
    text = str(value).strip()
    for prefix in ("docker://", "http://", "https://"):
        if text.startswith(prefix):
            text = text[len(prefix):]
    return text.strip("/")

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = yaml.safe_load(handle) or {}

config = data.get("oc_mirror_config") or {}
push = config.get("push") or {}
storage = config.get("storage") or {}
registry_storage = storage.get("registry") or {}
repos = push.get("repositories") or {}

registry = push.get("registry") or registry_storage.get("url") or ""
if registry:
    registry = normalize_registry(registry)

tls = push.get("dest_tls_verify")
tls_text = "" if tls is None else as_bool(tls)

pairs = {
    "VARS_BUNDLE": data.get("destination") or "",
    "VARS_REGISTRY": registry,
    "VARS_PREFIX": (push.get("repository_prefix") or "").strip("/"),
    "VARS_CACHE": config.get("cache_dir") or "",
    "VARS_AUTHFILE": config.get("authfile") or "",
    "VARS_TLS": tls_text,
    "VARS_PARALLEL_IMAGES": push.get("parallel_images") if push.get("parallel_images") is not None else "",
    "VARS_PARALLEL_LAYERS": push.get("parallel_layers") if push.get("parallel_layers") is not None else "",
    "VARS_REPO_RELEASE": repos.get("release") or "",
    "VARS_REPO_REDHAT": repos.get("redhat") or "",
    "VARS_REPO_COMMUNITY": repos.get("community") or "",
    "VARS_REPO_CERTIFIED": repos.get("certified") or "",
}
for key, value in pairs.items():
    print(f"{key}={quote(value)}")
PY
)"
fi

normalize_registry() {
  local value=$1
  value=${value#docker://}
  value=${value#http://}
  value=${value#https://}
  value=${value%/}
  printf '%s' "$value"
}

expand_tilde() {
  local value=$1
  case "$value" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s' "$HOME/${value:2}" ;;
    *) printf '%s' "$value" ;;
  esac
}

BUNDLE=${CLI_BUNDLE:-$VARS_BUNDLE}
REGISTRY=$(normalize_registry "${CLI_REGISTRY:-$VARS_REGISTRY}")
if [[ "$CLI_PREFIX_SET" -eq 1 ]]; then
  PREFIX=$CLI_PREFIX
else
  PREFIX=$VARS_PREFIX
fi
PREFIX=${PREFIX#/}
PREFIX=${PREFIX%/}
AUTHFILE=$(expand_tilde "${CLI_AUTHFILE:-${VARS_AUTHFILE:-~/.docker/config.json}}")
TLS_VERIFY=${CLI_TLS:-${VARS_TLS:-false}}
ONLY=${CLI_ONLY:-all}
PARALLEL_IMAGES=${CLI_PARALLEL_IMAGES:-${VARS_PARALLEL_IMAGES:-1}}
PARALLEL_LAYERS=${CLI_PARALLEL_LAYERS:-${VARS_PARALLEL_LAYERS:-1}}
REPO_RELEASE=${VARS_REPO_RELEASE:-release}
REPO_REDHAT=${VARS_REPO_REDHAT:-rh_operators}
REPO_COMMUNITY=${VARS_REPO_COMMUNITY:-community_operators}
REPO_CERTIFIED=${VARS_REPO_CERTIFIED:-certified_operators}

case "$TLS_VERIFY" in
  true|false) ;;
  *)
    echo "--dest-tls-verify must be true or false" >&2
    exit 1
    ;;
esac

if [[ -z "$BUNDLE" ]]; then
  echo "Bundle directory is required. Set destination in the vars file or pass --bundle." >&2
  exit 1
fi
if [[ ! -d "$BUNDLE" ]]; then
  echo "Bundle directory does not exist: $BUNDLE" >&2
  exit 1
fi
BUNDLE=$(cd "$BUNDLE" && pwd)

if [[ -z "$REGISTRY" ]]; then
  echo "Registry is required. Set oc_mirror_config.push.registry or pass --registry host:port." >&2
  exit 1
fi

if [[ -n "$CLI_CACHE" ]]; then
  CACHE=$(expand_tilde "$CLI_CACHE")
elif [[ -n "$CLI_BUNDLE" ]]; then
  CACHE="${BUNDLE}/cache"
elif [[ -n "$VARS_CACHE" ]]; then
  CACHE=$(expand_tilde "$VARS_CACHE")
else
  CACHE="${BUNDLE}/cache"
fi

if [[ "$DRY_RUN" -eq 0 && ! -x "${BUNDLE}/bin/oc-mirror" ]]; then
  echo "oc-mirror was not found at ${BUNDLE}/bin/oc-mirror" >&2
  exit 1
fi

validate_only() {
  local item
  local part
  local known=0
  if [[ "$ONLY" == "all" ]]; then
    return 0
  fi
  IFS=',' read -ra part <<< "$ONLY"
  for item in "${part[@]}"; do
    item=${item//[[:space:]]/}
    if [[ -z "$item" ]]; then
      continue
    fi
    case "$item" in
      release|redhat|community|certified) known=1 ;;
      *)
        echo "Unknown catalog in --only: $item" >&2
        exit 1
        ;;
    esac
  done
  if [[ "$known" -eq 0 ]]; then
    echo "--only did not name a catalog" >&2
    exit 1
  fi
}

selected() {
  local name=$1
  local item
  local part
  if [[ "$ONLY" == "all" ]]; then
    return 0
  fi
  IFS=',' read -ra part <<< "$ONLY"
  for item in "${part[@]}"; do
    item=${item//[[:space:]]/}
    if [[ "$item" == "$name" ]]; then
      return 0
    fi
  done
  return 1
}

validate_only

destination_for() {
  local repo=$1
  if [[ -n "$PREFIX" ]]; then
    printf 'docker://%s/%s/%s' "$REGISTRY" "$PREFIX" "$repo"
  else
    printf 'docker://%s/%s' "$REGISTRY" "$repo"
  fi
}

ran=0
skipped=0

push_catalog() {
  local name=$1
  local config_name=$2
  local source_rel=$3
  local repo=$4
  local with_parallel=$5
  local source="${BUNDLE}/${source_rel}"
  local config="${BUNDLE}/bin/${config_name}"
  local dest
  local -a cmd

  if ! selected "$name"; then
    return 0
  fi

  if [[ ! -d "$source" ]]; then
    if [[ "$ONLY" == "all" ]]; then
      echo "Skipping ${name}: ${source} is not in this bundle" >&2
      skipped=$((skipped + 1))
      return 0
    fi
    echo "Catalog ${name} was requested but ${source} does not exist" >&2
    exit 1
  fi
  if [[ ! -f "$config" ]]; then
    echo "Image set config for ${name} was not found: ${config}" >&2
    exit 1
  fi

  dest=$(destination_for "$repo")
  cmd=(
    "${BUNDLE}/bin/oc-mirror"
    -c "$config"
    --from "file://${source}"
    "$dest"
    --v2
    --authfile "$AUTHFILE"
    --dest-tls-verify="$TLS_VERIFY"
  )
  if [[ "$with_parallel" == "yes" ]]; then
    cmd+=(--parallel-images "$PARALLEL_IMAGES" --parallel-layers "$PARALLEL_LAYERS")
  fi
  cmd+=(--cache-dir "$CACHE")

  echo "Pushing ${name} to ${dest}"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf ' '
    printf '%q ' "${cmd[@]}"
    printf '\n'
  else
    if ! "${cmd[@]}"; then
      echo "Push of ${name} failed" >&2
      exit 1
    fi
  fi
  ran=$((ran + 1))
}

push_catalog release image-config.yaml openshift-release-dev "$REPO_RELEASE" yes
push_catalog redhat redhat-operator-images.yaml operators/redhat "$REPO_REDHAT" no
push_catalog community community-operator-images.yaml operators/community "$REPO_COMMUNITY" no
push_catalog certified certified-operator-images.yaml operators/certified "$REPO_CERTIFIED" no

if [[ "$ran" -eq 0 ]]; then
  echo "No catalogs were pushed." >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Would push ${ran} catalog(s)."
else
  echo "Pushed ${ran} catalog(s)."
fi
if [[ "$skipped" -gt 0 ]]; then
  echo "Skipped ${skipped} catalog(s) that are not in the bundle."
fi
