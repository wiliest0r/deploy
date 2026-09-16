# Deploy & Infrastructure (K8s / WASM / k3s)

Infrastructure manifests and configuration scripts for deploying WebAssembly microservices to k3s running inside WSL2 (Ubuntu).

## Files
- `k3s-setup.sh`: Shell script to install `containerd-shim-spin-v2`, configure k3s containerd CRI runtime, and setup kubeconfig.
- `runtime-class.yaml`: Kubernetes `RuntimeClass` resource for `wasm-spin`.
- `app-deployment.yaml`: Deployment (WASM container), Service (NodePort `30080`), and Traefik Ingress.

## Quick Start
```bash
chmod +x k3s-setup.sh
./k3s-setup.sh
```
