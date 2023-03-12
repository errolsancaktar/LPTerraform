variable "projectid" {
  type        = string
  default     = "lptest-380322"
  description = "GCP Project ID"
}

variable "regionid" {
  type        = string
  default     = "us-central1"
  description = "Region ID"
}

variable "zoneid" {
  type        = string
  default     = "us-central1-c"
  description = "Zone ID"
}


variable "name" {
  type    = string
  default = "remmina"
}
