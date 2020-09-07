# This is a custom ArgoCD image with Sops and Helm Secrets installed.
# Reference:
# - https://argoproj.github.io/argo-cd/operator-manual/custom_tools/#byoi-build-your-own-image
# - https://argoproj.github.io/argo-cd/user-guide/helm/#helm-plugins

FROM argoproj/argocd:v1.7.4

USER root

RUN apt-get update && \
    apt-get install -y curl gpg vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    curl -o /usr/local/bin/sops -L https://github.com/mozilla/sops/releases/download/3.2.0/sops-3.2.0.linux && \
    chmod +x /usr/local/bin/sops

USER argocd

RUN  helm plugin install https://github.com/zendesk/helm-secrets

ENV HELM_PLUGINS="/home/argocd/.local/share/helm/plugins/"