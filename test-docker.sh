#!/usr/bin/env bash
# =============================================================================
# test-docker.sh — Docker 端到端集成测试
# =============================================================================
# 测试流程:
#   1. 构建镜像 (bootstrap 在构建时运行)
#   2. 运行 verify.sh --strict
#   3. 再次运行 bootstrap.sh (幂等性)
#   4. 再次运行 verify.sh --strict (幂等后验证)
#   5. 运行 uninstall.sh --all --yes (卸载)
#   6. 报告结果
# =============================================================================
set -euo pipefail

IMAGE="ubuntu-bootstrap-test"
CONTAINER="ubuntu-bootstrap-test-$$"
PASS=0
FAIL=0
TOTAL=0

GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

step()  { printf '\n%s━━━ %s ━━━%s\n' "$CYAN" "$*" "$NC"; TOTAL=$((TOTAL + 1)); }
pass()  { printf '  %s✓ PASS%s: %s\n' "$GREEN" "$NC" "$*"; PASS=$((PASS + 1)); }
fail()  { printf '  %s✗ FAIL%s: %s\n' "$RED" "$NC" "$*"; FAIL=$((FAIL + 1)); }

cleanup() {
    docker rm -f "$CONTAINER" 2>/dev/null || true
}
trap cleanup EXIT

# GITHUB_TOKEN check — avoids Docker build hitting GitHub API rate limits
DOCKER_BUILD_ARGS=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
    DOCKER_BUILD_ARGS="--build-arg GITHUB_TOKEN=${GITHUB_TOKEN}"
else
    printf '  %s⚠ WARNING%s GITHUB_TOKEN not set — Docker build may hit GitHub API rate limits.\n' "$YELLOW" "$NC"
    printf '  %s→%s Set it: export GITHUB_TOKEN="$(gh auth token)"\n' "$CYAN" "$NC"
    printf '\n'
fi

# ── Step 1: 构建镜像 ─────────────────────────────────────────────────────────
step "构建镜像 (bootstrap 在构建时运行)"
if docker build $DOCKER_BUILD_ARGS -t "$IMAGE" . 2>&1; then
    pass "镜像构建成功 (bootstrap.sh 已执行)"
else
    fail "镜像构建失败"
    exit 1
fi

# ── Step 2: verify.sh --strict ───────────────────────────────────────────────
step "首次验证 (verify.sh --strict)"
if docker run --rm "$IMAGE" bash /home/dev/ubuntu-bootstrap/verify.sh --strict 2>&1; then
    pass "verify.sh --strict 通过"
else
    fail "verify.sh --strict 失败"
    exit 1
fi

# ── Step 3-5: 在同一个容器中测试幂等性 ───────────────────────────────────────
step "启动容器用于幂等性测试"
docker run -d --name "$CONTAINER" "$IMAGE" tail -f /dev/null
pass "容器已启动: $CONTAINER"

step "幂等性: 第二次运行 bootstrap.sh"
if docker exec "$CONTAINER" bash /home/dev/ubuntu-bootstrap/bootstrap.sh 2>&1; then
    pass "bootstrap.sh 第二次运行成功 (幂等)"
else
    fail "bootstrap.sh 第二次运行失败"
fi

step "幂等性: 第二次验证 verify.sh --strict"
if docker exec "$CONTAINER" bash /home/dev/ubuntu-bootstrap/verify.sh --strict 2>&1; then
    pass "verify.sh --strict 第二次通过 (幂等)"
else
    fail "verify.sh --strict 第二次失败"
fi

step "卸载 (uninstall.sh --all --yes)"
if docker exec "$CONTAINER" bash /home/dev/ubuntu-bootstrap/uninstall.sh --all --yes 2>&1; then
    pass "uninstall.sh 执行成功"
else
    fail "uninstall.sh 执行失败"
fi

# ── 清理 ─────────────────────────────────────────────────────────────────────
docker rm -f "$CONTAINER" 2>/dev/null || true

# ── 结果 ─────────────────────────────────────────────────────────────────────
printf '\n'
printf '┌──────────────────────────────────────┐\n'
printf '│  通过: %-2d  失败: %-2d  总计: %-2d  │\n' "$PASS" "$FAIL" "$TOTAL"
printf '└──────────────────────────────────────┘\n'

if [ "$FAIL" -gt 0 ]; then
    printf '\n%s✗ 集成测试失败%s\n' "$RED" "$NC"
    exit 1
else
    printf '\n%s✓ 所有集成测试通过%s\n' "$GREEN" "$NC"
fi
