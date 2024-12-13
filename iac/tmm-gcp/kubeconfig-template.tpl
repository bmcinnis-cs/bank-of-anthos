apiVersion: v1
kind: Config
current-context: my-cluster
contexts:
- name: my-cluster
  context:
    cluster: ${cluster_name}
    user: ${cluster_name}
clusters:
- name: ${cluster_name}
  cluster:
    server: ${endpoint}
    certificate-authority-data: ${cluster_ca}
users:
- name: ${cluster_name}
  user:
    token: ${token}
