terraform {
  required_version = ">= 1.3"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.0"
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

