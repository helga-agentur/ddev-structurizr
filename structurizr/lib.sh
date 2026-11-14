#!/usr/bin/env bash
#ddev-generated
# Shared settings and helpers for the structurizr add-on.
# One workspace per Drupal module, named after the module.
# The source always lives in the module:
#   <module>/architecture/diagrams/workspace.dsl
# The layout only decides where `ddev c4-export` writes:
# STRUCTURIZR_LAYOUT=root (default): central folder in the project, sorted by module.
#   Works for contrib modules too: they're installed by Composer and usually
#   git-ignored, so exports inside them would not be committed.
#   architecture/<module>/
# STRUCTURIZR_LAYOUT=module: next to the source
#   <module>/architecture/exports/
#
# Override per project, e.g.:
#   ddev dotenv set .ddev/.env.structurizr --structurizr-layout=module
# and commit .ddev/.env.structurizr.

ENV_FILE="${DDEV_APPROOT}/.ddev/.env.structurizr"
if [ -f "$ENV_FILE" ]; then set -a; . "$ENV_FILE"; set +a; fi

LAYOUT="${STRUCTURIZR_LAYOUT:-root}"
ARCH_DIR="${STRUCTURIZR_ARCHITECTURE_DIR:-architecture}"
DIAGRAMS_SUBDIR="${STRUCTURIZR_DIAGRAMS_SUBDIR:-diagrams}"
EXPORTS_SUBDIR="${STRUCTURIZR_EXPORTS_SUBDIR:-exports}"
MODULES_DIR="${DDEV_APPROOT}/${DDEV_DOCROOT:+$DDEV_DOCROOT/}modules"
IMAGE="${STRUCTURIZR_IMAGE:-structurizr/structurizr}"
PLANTUML_IMAGE="${STRUCTURIZR_PLANTUML_IMAGE:-plantuml/plantuml}"
FORMATS="${STRUCTURIZR_EXPORT_FORMATS:-svg,mermaid}"
PREFIX="structurizr_${DDEV_SITENAME}_"

# Containers must write to the mounted folders as the host user, not the image's default user.
# Rootless Docker maps container root to the host user; rootful Docker needs the host user's IDs.
if docker info --format '{{.SecurityOptions}}' 2>/dev/null | grep -q rootless; then
  CONTAINER_USER="0:0"
else
  CONTAINER_USER="$(id -u):$(id -g)"
fi

case "$LAYOUT" in
  module|root) ;;
  *) echo "STRUCTURIZR_LAYOUT must be 'module' or 'root', got '$LAYOUT'." >&2; exit 1 ;;
esac

# Prints "module<TAB>architecture dir" for every workspace, e.g. "my_module<TAB>.../my_module/architecture".
_workspace_table() {
  local f d
  find "$MODULES_DIR" -path "*/$ARCH_DIR/$DIAGRAMS_SUBDIR/workspace.dsl" \
    -not -path '*/node_modules/*' -not -path '*/vendor/*' 2>/dev/null |
    while read -r f; do
      d="$(dirname "$(dirname "$f")")"
      printf '%s\t%s\n' "$(basename "$(dirname "$d")")" "$d"
    done
}

workspaces() { _workspace_table | cut -f1 | sort -u; }

# Architecture dir of a module inside the module, or empty.
arch_dir() { _workspace_table | awk -F'\t' -v m="$1" '$1 == m && !found { print $2; found = 1 }'; }

# Folder with workspace.dsl of a module.
source_dir() { echo "$(arch_dir "$1")/$DIAGRAMS_SUBDIR"; }

# Folder the exports of a module go to, depending on the layout.
export_dir() {
  if [ "$LAYOUT" = "module" ]; then
    echo "$(arch_dir "$1")/$EXPORTS_SUBDIR"
  else
    echo "$DDEV_APPROOT/$ARCH_DIR/$1"
  fi
}

rel() { echo "${1#$DDEV_APPROOT/}"; }

EXPECTED_SOURCE="$(rel "$MODULES_DIR")/**/<module>/$ARCH_DIR/$DIAGRAMS_SUBDIR/workspace.dsl"

no_workspaces_hint() {
  echo "No module workspaces found (expected $EXPECTED_SOURCE)." >&2
}

require_workspace() {
  if [ -z "$(arch_dir "$1")" ]; then
    echo "No workspace for module '$1' (expected $EXPECTED_SOURCE)." >&2
    if [ -n "$(workspaces)" ]; then
      { echo "Available:"; workspaces | sed 's/^/  /'; } >&2
    fi
    exit 1
  fi
}
