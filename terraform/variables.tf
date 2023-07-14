variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "openweathermap_apikey" {
  sensitive = true
  type      = string
}
