# ActiveCollab on Kubernetes (activecollab-sh-kubernetes)

This repository contains Kubernetes manifests for deploying ActiveCollab.

## What's inside

- Kubernetes manifests for ActiveCollab (deployments, services, PV/PVC, cronjob, HPA, nginx edge)
- `docker/` contains Dockerfiles for building images

## Prerequisites

- A Kubernetes cluster with `kubectl` configured
- Docker registry access (Docker Hub or a private registry)
- A MySQL server running on a separate VM

## Required configuration

1. **MySQL server on a separate VM**
   - The MySQL server is not deployed in this cluster.
   - Update the MySQL **endpoint** definition to point to your VM IP address.
   - Edit `mysql-endpoint.yml` and replace the IP under `subsets.addresses` with your MySQL VM IP.

2. **Hostname replacement**
   - All manifests use the placeholder hostname `activecollab.example.com`.
   - Replace it with your real hostname/domain in all YAML files before applying.

3. **Custom PHP-FPM image**
   - Build your own PHP-FPM Docker image and push it to Docker Hub or your private registry.
   - Use the Dockerfiles under `docker/` and update the image reference in the PHP-FPM deployment
     manifest(s) to point to your image.

## Configuration (Kubernetes Secret)

The deployment expects a Secret named `ac-secrets` in the `activecollab` namespace with these keys:

- `DB_HOST` (e.g., `mariadb-ext` when using the provided external service)
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `ES_URL` (e.g., `http://elastic-ext:9200`)

Secret values are not stored in this repository.

Example command to create the secret:
```bash
kubectl create secret generic ac-secrets -n activecollab \
  --from-literal=DB_HOST=mariadb-ext \
  --from-literal=DB_NAME=activecollab \
  --from-literal=DB_USER=ac_user \
  --from-literal=DB_PASSWORD=your_secure_password \
  --from-literal=ES_URL=http://elastic-ext:9200
```

## Deploy (quick start)

Apply the manifests with `kubectl apply -f` in a stable order:

```bash
# Config
kubectl apply -f nginx-config-template.yml

# Storage
kubectl apply -f persistent-volume-code.yml
kubectl apply -f persistent-volume-logs.yml

# MySQL endpoint/service (points to your external VM)
kubectl apply -f mysql-endpoint.yml
kubectl apply -f mysql-service.yml

# ElasticSearch endpoint/service (if used)
kubectl apply -f elastic-endpoint.yml
kubectl apply -f elastic-service.yml

# PHP-FPM (make sure the image is updated first)
kubectl apply -f php-fpm-depl-service.yml

# Nginx ingress/service
kubectl apply -f nginx-depl-service.yml

# Cron and metrics server (optional)
kubectl apply -f activecollab-cron.yml
kubectl apply -f metrics-server-components.yml

# HPA
kubectl apply -f php-fpm-hpa.yml
```

Or run the helper script:

```bash
./apply-k8s.sh
```

## Local validation (no cluster needed)

```bash
yamllint *.yml
kubeconform -strict *.yml
kube-linter lint *.yml
```

## Notes

- **Domain/Hostname**: Ensure all hostname references are updated from `activecollab.example.com` to your own domain across all YAML files.
- **External Database & Search**: Ensure the MySQL endpoint in `mysql-endpoint.yml` (and ElasticSearch if used) points to your VM/server IP address.
- **PHP-FPM image**: Ensure the PHP-FPM image is built and published to your container registry before deploying.
- **Cluster DNS**: The manifests currently include a custom `dnsPolicy: "None"` and `dnsConfig` pointing to `10.96.0.10` (default kube-dns/CoreDNS Service IP on standard kubeadm clusters). If your cluster uses a different DNS service IP (e.g., `10.43.0.10` in k3s) or if you want default pod DNS behavior, remove the custom `dnsConfig` or switch back to `dnsPolicy: ClusterFirst`.
- **Storage for Multi-node Clusters**: The included persistent volumes use `hostPath` (`/mnt/activecollab-data/...`) with `ReadWriteOnce`. If deploying across multiple nodes, consider using a network-backed storage provider supporting `ReadWriteMany` (RWX) such as NFS, CephFS, or Longhorn so that PHP-FPM, Nginx, and CronJobs can access the files concurrently.

## Disclaimer

This project is not affiliated with or endorsed by ActiveCollab. ActiveCollab is a trademark of its respective owner.

## License

Licensed under the MIT License. See [LICENSE](LICENSE).
