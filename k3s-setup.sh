#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up Spin containerd shim for k3s on WSL2..."

# Check dependencies
if ! command -v k3s &> /dev/null; then
    echo "k3s is not installed. Please install k3s first."
    exit 1
fi

# Install containerd-shim-spin if missing
if ! command -v containerd-shim-spin-v2 &> /dev/null; then
    echo "==> Downloading containerd-shim-spin-v2..."
    SHIM_VERSION="v0.15.1"
    ARCH=$(dpkg --print-architecture)
    if [ "$ARCH" = "amd64" ]; then
        SHIM_ARCH="x86_64"
    else
        SHIM_ARCH="aarch64"
    fi
    curl -LO "https://github.com/spinkube/containerd-shim-spin/releases/download/${SHIM_VERSION}/containerd-shim-spin-v2-linux-${SHIM_ARCH}.tar.gz"
    sudo tar -xzf "containerd-shim-spin-v2-linux-${SHIM_ARCH}.tar.gz" -C /usr/local/bin
    rm "containerd-shim-spin-v2-linux-${SHIM_ARCH}.tar.gz"
    echo "==> containerd-shim-spin-v2 installed to /usr/local/bin"
fi

# Configure containerd config template for k3s
CONTAINERD_TMPL="/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl"
sudo mkdir -p "$(dirname "$CONTAINERD_TMPL")"

if [ ! -f "$CONTAINERD_TMPL" ]; then
    echo "==> Creating k3s containerd config template..."
    cat << 'EOF' | sudo tee "$CONTAINERD_TMPL"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.spin]
  runtime_type = "io.containerd.spin.v2"
EOF
    echo "==> Restarting k3s..."
    sudo systemctl restart k3s || sudo service k3s restart
fi

# Ensure kubeconfig permissions
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    mkdir -p "$HOME/.kube"
    sudo cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
    sudo chown -R "$(id -u):$(id -g)" "$HOME/.kube"
    export KUBECONFIG="$HOME/.kube/config"
fi

echo "==> Applying RuntimeClass and Application manifests..."
kubectl apply -f runtime-class.yaml
kubectl apply -f app-deployment.yaml

echo "==> Setup completed successfully!"
