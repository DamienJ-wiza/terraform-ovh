variable "wizaops_ssh_public_key" {
  default = "/home/damien/.ssh/wizaops.pub"
}

variable "project_id" {
  default = "9e1013faed644b4a9452f7edcc391dc9"
}

variable "regions" {
  default = "GRA7"
}

variable "instances_names_back" {
  description = "Create back instances"
  type        = list(string)
  default     = ["Back1", "Back2", "Worker"]
}

variable "instances_names_front" {
  description = "Create front instances"
  type        = list(string)
  default     = ["Front1", "Front2"]
}
