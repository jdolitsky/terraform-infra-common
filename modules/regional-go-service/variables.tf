variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "regions" {
  description = "A map from region names to a network and subnetwork.  A pub/sub topic and ingress service (publishing to the respective topic) will be created in each region, with the ingress service configured to egress all traffic via the specified subnetwork."
  type = map(object({
    network = string
    subnet  = string
  }))
}

variable "ingress" {
  type        = string
  description = "The ingress mode for the service.  Must be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER, or INGRESS_TRAFFIC_INTERNAL_ONLY."
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"
}

variable "egress" {
  type        = string
  description = "The egress mode for the service.  Must be one of ALL_TRAFFIC, or PRIVATE_RANGES_ONLY. Egress traffic is routed through the regional VPC network from var.regions."
  default     = "ALL_TRAFFIC"
}

variable "service_account" {
  type        = string
  description = "The service account as which to run the service."
}

variable "containers" {
  description = "The containers to run in the service.  Each container will be run in each region."
  type = map(object({
    source = object({
      base_image  = optional(string, "cgr.dev/chainguard/static:latest-glibc")
      working_dir = string
      importpath  = string
    })
    args = optional(list(string), [])
    ports = optional(list(object({
      name           = optional(string, "http1")
      container_port = number
    })), [])
    resources = optional(
      object(
        {
          limits = optional(object(
            {
              cpu    = string
              memory = string
            }
          ), null)
          cpu_idle = optional(bool, true)
        }
      ),
      {
        cpu_idle = true
      }
    )
    env = optional(list(object({
      name  = string
      value = optional(string)
      value_source = optional(object({
        secret_key_ref = object({
          secret  = string
          version = string
        })
      }), null)
    })), [])
    regional-env = optional(list(object({
      name  = string
      value = map(string)
    })), [])
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
  }))
}

variable "scaling" {
  description = "The scaling configuration for the service."
  type = object({
    min_instances                    = optional(number, 0)
    max_instances                    = optional(number, 100)
    max_instance_request_concurrency = optional(number)
  })
  default = {}
}

variable "regional-volumes" {
  description = "The volumes to make available to the containers in the service for mounting."
  type = list(object({
    name = string
    gcs = optional(map(object({
      bucket    = string
      read_only = optional(bool, true)
    })), {})
    nfs = optional(map(object({
      server    = string
      path      = string
      read_only = optional(bool, true)
    })), {})
  }))
  default = []
}

variable "volumes" {
  description = "The volumes to make available to the containers in the service for mounting."
  type = list(object({
    name = string
    empty_dir = optional(object({
      medium = optional(string, "MEMORY")
    }))
    secret = optional(object({
      secret = string
      items = list(object({
        version = string
        path    = string
      }))
    }))
  }))
  default = []
}

// https://cloud.google.com/run/docs/configuring/request-timeout
variable "request_timeout_seconds" {
  description = "The timeout for requests to the service, in seconds."
  type        = number
  default     = 300
}

variable "notification_channels" {
  description = "List of notification channels to alert."
  type        = list(string)
}

variable "execution_environment" {
  description = "The execution environment for the service"
  type        = string
  default     = "EXECUTION_ENVIRONMENT_GEN1"
  validation {
    error_message = "Must be EXECUTION_ENVIRONMENT_GEN1 or EXECUTION_ENVIRONMENT_GEN2. Got ${var.execution_environment}"
    condition     = var.execution_environment == "EXECUTION_ENVIRONMENT_GEN1" || var.execution_environment == "EXECUTION_ENVIRONMENT_GEN2"
  }
}
