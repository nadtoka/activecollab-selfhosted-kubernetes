#!/usr/bin/env bash
set -euo pipefail

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
