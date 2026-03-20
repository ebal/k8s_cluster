# AGENTS.md - Kubernetes Cluster Terraform Project

**Author**: Evaggelos Balaskas
**Date Created**: Fri Mar 20 2026

---

## Project Structure

```
k8s_cluster/
├── AGENTS.md                    (this file)
├── k8s_state/                   (Terraform state management)
├── scripts/
│   ├── CNI_Calico.sh
│   ├── setup_k8s_worker.sh
│   └── setup_k8s_control.sh
└── tf_libvirt/                  (Terraform configuration)
    ├── Provider.tf
    ├── Domain.tf
    ├── Volume.tf
    ├── Output.tf
    ├── Variables.tf
    └── Cloudinit.tf
```
**directory path: `/Users/A93162639/Downloads/github/k8s_cluster/`**