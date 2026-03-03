# variables.tf — team-specific configuration

variable "namespace" {
  description = "Your team's Kubernetes namespace"
  type        = string
  # Replace with your namespace:
  default     = "lillteamet"
}

variable "team_name" {
  description = "Your team's display name"
  type        = string
  default     = "Lillteamet"
}
