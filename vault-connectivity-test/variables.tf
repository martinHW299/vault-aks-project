variable "vault_addr" {
  description = "Vault address reachable from the test pod."
  type        = string
  default     = "http://vault-server-service.bci-infra:8200"
}

variable "vault_profile" {
  description = "Profile/environment label. Used only when vault_secrets_path is empty."
  type        = string
  default     = "test"
}

variable "vault_secrets_path" {
  description = "Vault secret path (KV v1). Example: secret/myapp/test. If empty, it defaults to secret/myapp/<vault_profile>."
  type        = string
  default     = "secret/myapp/test"
}

variable "vault_role_id" {
  description = "AppRole role_id for the test."
  type        = string
  sensitive   = true
}

variable "vault_secret_id" {
  description = "AppRole secret_id for the test."
  type        = string
  sensitive   = true
}
