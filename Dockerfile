# =============================================================================
# ubuntu-bootstrap 验证镜像 — 在纯净 Ubuntu 24.04 中测试完整部署流程
# =============================================================================
# 构建并运行:
#   docker build -t ubuntu-bootstrap-test .
#   docker run --rm ubuntu-bootstrap-test
#
# 若需要安装 GitHub Release 工具（mise aqua 后端），传入 GITHUB_TOKEN:
#   docker build --build-arg GITHUB_TOKEN="ghp_xxx" -t ubuntu-bootstrap-test .
# =============================================================================
FROM ubuntu:24.04

ARG GITHUB_TOKEN

ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_INTERACTIVE=1 \
    QUIET=1 \
    GITHUB_TOKEN=${GITHUB_TOKEN}

# 最小化系统依赖（bootstrap.sh 本身需要 sudo + curl）
RUN apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends \
        sudo \
        curl \
        ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户并赋予免密 sudo
RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev

COPY . /home/dev/ubuntu-bootstrap

RUN bash /home/dev/ubuntu-bootstrap/bootstrap.sh

CMD ["bash", "/home/dev/ubuntu-bootstrap/verify.sh"]
