# modules/aks/variables.tf

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "cluster_name" { type = string }
variable "node_count" { type = number }
variable "node_size" { type = string }
variable "kubernetes_version" { type = string }
variable "project" { type = string }
variable "environment" { type = string }
