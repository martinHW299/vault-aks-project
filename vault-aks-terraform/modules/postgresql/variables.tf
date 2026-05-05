# modules/postgresql/variables.tf

variable "namespace"     { type = string }
variable "admin_user"    { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "db_name"       { type = string }
