#!/bin/bash
# health.sh - Vérification complète du système
# Usage: ./health.sh [--phase N] [--ci] [--module-prefix NAME]
#
# Options:
#   --phase N          Run only phase N (1-7)
#   --ci               Suppress colors and emoji for CI logs
#   --module-prefix    Python package name to verify (default: creative_runtime)
#   --help, -h         Show this help message

set -u
set -o pipefail

# ==========================================
# CONFIGURATION & ARGUMENT PARSING
# ==========================================

CI_MODE=false
TARGET_PHASE=0
MODULE_PREFIX="${CR_MODULE_PREFIX:-creative_runtime}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --phase)
            # Guard: ensure a trailing argument exists before shifting
            if [[ $# -lt 2 ]] || [[ "$2" =~ [^0-9] ]]; then
                printf "%s\n" "Error: --phase requires a number (1-7)" >&2
                exit 1
            fi
            TARGET_PHASE="$2"
            if [[ "$TARGET_PHASE" -lt 1 ]] || [[ "$TARGET_PHASE" -gt 7 ]]; then
                printf "%s\n" "Error: phase must be between 1 and 7" >&2
                exit 1
            fi
            shift 2
            ;;
        --ci)
            CI_MODE=true
            shift
            ;;
        --module-prefix)
            if [[ $# -lt 2 ]]; then
                printf "%s\n" "Error: --module-prefix requires a value" >&2
                exit 1
            fi
            MODULE_PREFIX="$2"
            shift 2
            ;;
        --help|-h)
            cat <<'EOF'
Usage: ./health.sh [--phase N] [--ci] [--module-prefix NAME]

Options:
  --phase N          Run only phase N (1-7)
  --ci               Suppress colors and emoji for CI logs
  --module-prefix    Python package name to verify (default: creative_runtime)
  --help, -h         Show this help message
EOF
            exit 0
            ;;
        *)
            printf "%s\n" "Unknown option: $1" >&2
            printf "%s\n" "Use --help for usage" >&2
            exit 1
            ;;
    esac
done

# ==========================================
# OUTPUT FORMATTING
# ==========================================

if [ "$CI_MODE" = true ]; then
    RED=''; GREEN=''; YELLOW=''; NC=''
    MARK_PASS='[PASS]'; MARK_FAIL='[FAIL]'
    MARK_WARN='[WARN]'; MARK_MISSING='[MISS]'
    MARK_OK='[OK]'; MARK_KO='[KO]'
else
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
    MARK_PASS='✓ PASS'; MARK_FAIL='✗ FAIL'
    MARK_WARN='⚠ WARN'; MARK_MISSING='✗ MISSING'
    MARK_OK='✅'; MARK_KO='❌'
fi

# ==========================================
# ERROR LOGGING (with automatic cleanup)
# ==========================================

ERROR_LOG=$(mktemp "/tmp/health_errors.XXXXXX") || {
    printf "%s\n" "Error: failed to create temporary error log" >&2
    exit 1
}
# Clean up on normal exit, interrupt, or termination
trap 'rm -f "$ERROR_LOG"' EXIT INT TERM

# ==========================================
# COUNTERS
# ==========================================

PASS=0
FAIL=0
WARN=0

# ==========================================
# GUARDRAILS
# ==========================================

command -v python >/dev/null 2>&1 || {
    printf "%b\n" "${RED}${MARK_FAIL} python n'est pas installé${NC}" >&2
    exit 1
}

if [ ! -d "phases" ] || [ ! -d "$MODULE_PREFIX" ]; then
    printf "%b\n" "${RED}${MARK_FAIL} Exécute ce script depuis la racine du projet (répertoires 'phases/' et '$MODULE_PREFIX/' requis)${NC}" >&2
    exit 1
fi

# ==========================================
# HELPERS
# ==========================================

test_module() {
    local name="$1"
    local import_path="$2"
    
    printf "   Testing %s... " "$name"
    
    if python -c "import $import_path" >/dev/null 2>>"$ERROR_LOG"; then
        PASS=$((PASS + 1))
        printf "%b\n" "${GREEN}${MARK_PASS}${NC}"
    else
        FAIL=$((FAIL + 1))
        printf "%b\n" "${RED}${MARK_FAIL}${NC}"
    fi
}

test_file_exists() {
    local file="$1"
    local name="$2"
    
    printf "   Checking %s... " "$name"
    
    if [ -f "$file" ]; then
        PASS=$((PASS + 1))
        printf "%b\n" "${GREEN}${MARK_PASS}${NC}"
    else
        FAIL=$((FAIL + 1))
        printf "%b\n" "${RED}${MARK_MISSING}${NC}"
    fi
}

test_import_chain() {
    local name="$1"
    shift
    local cmd=("$@")
    
    printf "   Testing %s... " "$name"
    
    if "${cmd[@]}" >/dev/null 2>>"$ERROR_LOG"; then
        PASS=$((PASS + 1))
        printf "%b\n" "${GREEN}${MARK_PASS}${NC}"
    else
        FAIL=$((FAIL + 1))
        printf "%b\n" "${RED}${MARK_FAIL}${NC}"
    fi
}

# ==========================================
# PHASES
# ==========================================

phase1() {
    echo ""
    if [ "$CI_MODE" = true ]; then
        echo "PHASE 1: FICHIERS CRITIQUES"
    else
        echo "📁 PHASE 1: VÉRIFICATION DES FICHIERS CRITIQUES"
    fi
    echo "------------------------------------------"

    test_file_exists "phases/01_seed_profile.yaml" "Seed profile (01_seed_profile.yaml)"
    test_file_exists "phases/01_music_profile.yaml" "Music profile (01_music_profile.yaml)"
    test_file_exists "phases/02_emotion_profile.yaml" "Emotion profile"
    test_file_exists "phases/03_sound_resonance_matrix.yaml" "Resonance matrix"
    test_file_exists "phases/04_resonance_rules.yaml" "Resonance rules"
    test_file_exists "phases/05_fallback_rules.yaml" "Fallback rules"
    test_file_exists "phases/06_song_blueprint.yaml" "Song blueprint"
    test_file_exists "phases/07_creative_metagovernor.yaml" "MetaGovernor"
    test_file_exists "phases/08_realization_engine.yaml" "Realization engine"
    test_file_exists "phases/09_prosody_grid.yaml" "Prosody grid"
}

phase2() {
    echo ""
    if [ "$CI_MODE" = true ]; then
        echo "PHASE 2: IMPORTS PYTHON"
    else
        echo "📦 PHASE 2: VÉRIFICATION DES IMPORTS PYTHON"
    fi
    echo "------------------------------------------"

    test_module "Loader" "${MODULE_PREFIX}.loader"
    test_module "Resonance Engine" "${MODULE_PREFIX}.resonance.engine"
    test_module "Conditional Resonance" "${MODULE_PREFIX}.resonance.conditional_engine"
    test_module "Blueprint Builder" "${MODULE_PREFIX}.blueprint.builder"
    test_module "MetaGovernor" "${MODULE_PREFIX}.governance.metagovernor"
    test_module "Realization Engine" "${MODULE_PREFIX}.realization.engine"
    test_module "Music Processor" "${MODULE_PREFIX}.input.music_processor"
    test_module "Music Alignment" "${MODULE_PREFIX}.realization.music_alignment"
}

phase3() {
    echo ""
    if [ "$CI_MODE" = true ]; then
        echo "PHASE 3: MODULES PROSODY"
    else
        echo "🎵 PHASE 3: VÉRIFICATION DES MODULES PROSODY"
    fi
    echo "------------------------------------------"

    if [ -d "${MODULE_PREFIX}/prosody" ]; then
        test_module "Prosody Grid Builder" "${MODULE_PREFIX}.prosody.grid_builder"
        test_module "Syllable Counter" "${MODULE_PREFIX}.prosody.syllable_counter"
        test_module "Phonetic Scorer" "${MODULE_PREFIX}.prosody.phonetic_scorer"
        test_module "Prosody Validator" "${MODULE_PREFIX}.prosody.validator"
        test_module "Line Rewriter" "${MODULE_PREFIX}.prosody.line_rewriter"
    else
        printf "   %b\n" "${YELLOW}${MARK_WARN} prosody/ directory not found${NC}"
        WARN=$((WARN + 1))
    fi
}

phase4() {
    echo ""
    if [ "$CI_MODE" = true ]; then
        echo "PHASE 4: ORCHESTRATION"
    else
        echo "🔀 PHASE 4: VÉRIFICATION DE L'ORCHESTRATION"
    fi
    echo "------------------------------------------"

    if [ -d "${MODULE_PREFIX}/orchestration" ]; then
        test_module "Mode Router" "${MODULE_PREFIX}.orchestration.mode_router"
        test_module "Pipeline" "${MODULE_PREFIX}.orchestration.pipeline"
        test_module "Recovery" "${MODULE_PREFIX}.orchestration.recovery"
    else
        printf "   %b\n" "${YELLOW}${MARK_WARN} orchestration/ directory not found${NC}"
        WARN=$((WARN + 1))
    fi
}

phase5() {
    echo ""
    if [ "$CI_MODE" = true ]; then
        echo "PHASE 5: CONTRATS"
    else
        echo "📜 PHASE 5: VÉRIFICATION DES CONTRATS"
    fi
    echo "------------------------------------"

    test_file_exists "contracts/resonance.contract.json" "Resonance contract"
    test_file_exists "contracts/music_alignment.contract.json" "Music alignment contract"
    test_file_exists "contracts/prosody.contract.json" "Prosody contract"
    test_file_exists "contracts/governance.contract.json" "Governance contract"
    test_file_exists "contracts/realization.contract.json" "Realization contract"
}

phase6() {
    echo ""
    if [ "$CI_MODE" = true ]; then
        echo "PHASE 6: TESTS"
    else
        echo "🧪 PHASE 6: VÉRIFICATION DES TESTS"
    fi
    echo "--------------------------------"

    if command -v pytest >/dev/null 2>&1; then
        test_import_chain "Resonance tests" pytest tests/test_resonance.py --collect-only
        test_import_chain "Blueprint tests" pytest tests/test_blueprint.py --collect-only
        test_import_chain "Governance tests" pytest tests/test_governance.py --collect-only
        test_import_chain "Realization tests" pytest tests/test_realization.py --collect-only
        test_import_chain "Music profile tests" pytest tests/test_music_profile.py --collect-only
        test_import_chain "Music alignment tests" pytest tests/test_music_alignment.py --collect-only

        if [ -f "tests/test_prosody.py" ]; then
            test_import_chain "Prosody tests" pytest tests/test_prosody.py --collect-only
        fi

        if [ -f "tests/test_integration_music_first.py" ]; then
            test_import_chain "Music-first integration" pytest tests/test_integration_music_first.py --collect-only
        fi
    else
        printf "   %b\n" "${YELLOW}${MARK_WARN} pytest absent — Phase 6 sautée${NC}"
        WARN=$((WARN + 1))
    fi
}

phase7() {
    echo ""
    if [ "$CI_MODE" = true ]; then
        echo "PHASE 7: FONCTIONNALITE MINIMALE"
    else
        echo "🚀 PHASE 7: TEST DE FONCTIONNALITÉ MINIMALE"
    fi
    echo "------------------------------------------"

    printf "   Testing seed-first initialization... "
    # Pass MODULE_PREFIX via env var to avoid shell interpolation inside Python string
    if MODULE_PREFIX="$MODULE_PREFIX" python -c '
import os
prefix = os.environ["MODULE_PREFIX"]
mod = __import__(prefix + ".main", fromlist=["CreativeRuntime"])
CreativeRuntime = mod.CreativeRuntime
runtime = CreativeRuntime(phases_path="phases", output_path="output", interactive=False)
print("init ok")
' >/dev/null 2>>"$ERROR_LOG"; then
        PASS=$((PASS + 1))
        printf "%b\n" "${GREEN}${MARK_PASS}${NC}"
    else
        FAIL=$((FAIL + 1))
        printf "%b\n" "${RED}${MARK_FAIL}${NC}"
    fi
}

# ==========================================
# HEADER
# ==========================================

echo "=========================================="
if [ "$CI_MODE" = true ]; then
    echo "VERIFICATION DU SYSTEME CREATIVE RUNTIME"
else
    echo "🔍 VÉRIFICATION DU SYSTÈME CREATIVE RUNTIME"
fi
echo "=========================================="
echo "Module prefix: $MODULE_PREFIX"
if [ "$TARGET_PHASE" -ne 0 ]; then
    echo "Target phase: $TARGET_PHASE only"
fi
echo "Error log: $ERROR_LOG"

# ==========================================
# EXECUTION
# ==========================================

if [ "$TARGET_PHASE" -eq 0 ] || [ "$TARGET_PHASE" -eq 1 ]; then phase1; fi
if [ "$TARGET_PHASE" -eq 0 ] || [ "$TARGET_PHASE" -eq 2 ]; then phase2; fi
if [ "$TARGET_PHASE" -eq 0 ] || [ "$TARGET_PHASE" -eq 3 ]; then phase3; fi
if [ "$TARGET_PHASE" -eq 0 ] || [ "$TARGET_PHASE" -eq 4 ]; then phase4; fi
if [ "$TARGET_PHASE" -eq 0 ] || [ "$TARGET_PHASE" -eq 5 ]; then phase5; fi
if [ "$TARGET_PHASE" -eq 0 ] || [ "$TARGET_PHASE" -eq 6 ]; then phase6; fi
if [ "$TARGET_PHASE" -eq 0 ] || [ "$TARGET_PHASE" -eq 7 ]; then phase7; fi

# ==========================================
# RESULTS
# ==========================================

echo ""
echo "=========================================="
if [ "$CI_MODE" = true ]; then
    echo "RESULTATS"
else
    echo "📊 RÉSULTATS"
fi
echo "=========================================="
printf "%b\n" "${GREEN}${MARK_PASS}: $PASS${NC}"
printf "%b\n" "${RED}${MARK_FAIL}: $FAIL${NC}"
printf "%b\n" "${YELLOW}${MARK_WARN}: $WARN${NC}"

if [ "$FAIL" -gt 0 ]; then
    printf "\n%b\n" "${YELLOW}Post-mortem log: $ERROR_LOG${NC}"
    if [ "$CI_MODE" = true ]; then
        echo "--- Last 20 lines of error log ---"
        tail -n 20 "$ERROR_LOG"
    fi
fi

if [ "$FAIL" -eq 0 ]; then
    printf "\n%b\n" "${GREEN}${MARK_OK} TOUS LES TESTS PASSENT${NC}"
    exit 0
else
    printf "\n%b\n" "${RED}${MARK_KO} $FAIL TEST(S) ÉCHOUÉ(S)${NC}"
    exit 1
fi
