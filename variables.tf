# variables.tf — All configurable values in one place

variable "namespace" {
  description = "Kubernetes namespace for your team"
  type        = string
}

variable "team_name" {
  description = "Human-readable team name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "redis_image" {
  description = "Redis container image"
  type        = string
  default     = "redis:7-alpine"
}

variable "api_image" {
  description = "API backend container image"
  type        = string
  default     = "retro87/team-api:latest"
}

variable "frontend_image" {
  description = "Frontend container image"
  type        = string
  default     = "retro87/team-frontend:latest"
}

variable "api_replicas" {
  description = "Number of API replicas"
  type        = number
  default     = 1
}
