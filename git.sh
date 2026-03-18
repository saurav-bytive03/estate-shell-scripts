#!/usr/bin/env bash
set -e

# Colors
R='\033[0m'
B='\033[1m'
G='\033[0;32m'
Y='\033[0;33m'
C='\033[0;36m'
M='\033[0;35m'
RED='\033[0;31m'
DIM='\033[0;2m'

# Get script directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FE_DIR="${SCRIPT_DIR}/estate-craft-fe"
BACKEND_DIR="${SCRIPT_DIR}/estate-craft-backend"
ENV_FILE="${BACKEND_DIR}/.env"

usage() {
  echo -e "${C}Usage:${R} $0 --dev | --prod"
  echo -e "  ${G}--dev${R}   Switch both fe and backend to dev branch, set DB to estate-craft-dev"
  echo -e "  ${Y}--prod${R}  Switch both fe and backend to prod branch, set DB to estate-craft-prod"
  exit 1
}

pick_env() {
  echo -e "\n${B}${C}Please specify environment:${R}"
  echo -e "  ${G}1) --dev${R}   ${DIM}(dev branch, estate-craft-dev DB)${R}"
  echo -e "  ${Y}2) --prod${R}  ${DIM}(prod branch, estate-craft-prod DB)${R}"
  echo ""
  while true; do
    printf "${M}Enter 1 or 2 (or --dev / --prod): ${R}"
    read -r choice
    case "$choice" in
      1|--dev)  BRANCH="dev"; DB_NAME="estate-craft-dev"; return ;;
      2|--prod) BRANCH="prod"; DB_NAME="estate-craft-prod"; return ;;
      *) echo -e "${RED}Invalid. Choose 1, 2, --dev, or --prod.${R}" ;;
    esac
  done
}

if [[ $# -eq 0 ]]; then
  pick_env
elif [[ $# -eq 1 ]]; then
  case "$1" in
    --dev)
      BRANCH="dev"
      DB_NAME="estate-craft-dev"
      ;;
    --prod)
      BRANCH="prod"
      DB_NAME="estate-craft-prod"
      ;;
    *)
      echo -e "${RED}Unknown option: $1${R}"
      pick_env
      ;;
  esac
else
  usage
fi

echo -e "\n${B}${C}=== Syncing to environment: ${R}${B}$BRANCH${R} ${DIM}(DB: $DB_NAME)${R} ${C}===${R}\n"

# Frontend: checkout branch
if [[ -d "$FE_DIR" ]]; then
  echo -e "${C}[Frontend]${R} Switching to branch ${G}$BRANCH${R}"
  (cd "$FE_DIR" && git fetch -q 2>/dev/null; git checkout "$BRANCH")
else
  echo -e "${Y}Warning:${R} Frontend folder not found at $FE_DIR"
fi

# Backend: checkout branch
if [[ -d "$BACKEND_DIR" ]]; then
  echo -e "${C}[Backend]${R} Switching to branch ${G}$BRANCH${R}"
  (cd "$BACKEND_DIR" && git fetch -q 2>/dev/null; git checkout "$BRANCH")
else
  echo -e "${RED}Warning:${R} Backend folder not found at $BACKEND_DIR"
  exit 1
fi

# Backend .env: set DATABASE_URL with correct db name
if [[ -f "$ENV_FILE" ]]; then
  if grep -q '^DATABASE_URL=' "$ENV_FILE"; then
    # Replace db name in DATABASE_URL (swap estate-craft-prod <-> estate-craft-dev)
    tmp_env=$(mktemp)
    sed -e "s|estate-craft-prod|${DB_NAME}|g" -e "s|estate-craft-dev|${DB_NAME}|g" "$ENV_FILE" > "$tmp_env"
    mv "$tmp_env" "$ENV_FILE"
    echo -e "${C}[Backend]${R} .env DATABASE_URL set to ${G}$DB_NAME${R}"
  else
    echo -e "${Y}Warning:${R} DATABASE_URL not found in $ENV_FILE"
  fi
else
  echo -e "${Y}Warning:${R} .env not found at $ENV_FILE"
fi

echo -e "\n${B}${G}=== Done.${R} Frontend and Backend on branch ${G}$BRANCH${R}, DB: ${G}$DB_NAME${R} ${C}===${R}\n"
