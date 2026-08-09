# Helm values

Mirrors `charts/` layout. Argo CD Applications mount these via multi-source
`$values/helm-values/...`.

```
helm-values/
  bootstrap-layer/
    kyverno/values.yaml
    kube-prometheus-stack/values.yaml
    metrics-server/values.yaml
    infisical-operator/values.yaml
    teleport-kube-agent/values.yaml
  applications/
    demo-app/
      values.yaml
      values-staging.yaml
      values-prod.yaml
      environments/{dev,uat,prod}/
```

Wrapper charts under `charts/bootstrap-layer/*` expect values **nested** under
the upstream dependency name (e.g. top-level key `kyverno:`).
