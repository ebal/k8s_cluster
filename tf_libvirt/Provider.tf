terraform {
  required_version = ">= 1.9"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.1"
    }

    template = {
      source  = "hashicorp/template"
    }

    random = {
      source = "hashicorp/random"
    }

    time = {
      source = "hashicorp/time"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

