variable "tenancy_ocid" {
  description = "OCID of the tenancy (root compartment). Resource Manager populates this automatically."
  type        = string
}

variable "region" {
  description = "OCI region used by the Resource Manager stack."
  type        = string
}

variable "identity_domain_id" {
  description = "OCID of the identity domain where the dynamic group will be created."
  type        = string
}

variable "dynamic_group_name" {
  description = "Display name of the Full Stack DR dynamic group."
  type        = string
  default     = "fsdr-resource-principals"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,100}$", var.dynamic_group_name))
    error_message = "dynamic_group_name must contain 1-100 letters, digits, periods, underscores, or hyphens."
  }
}

variable "dynamic_group_description" {
  description = "Description of the Full Stack DR dynamic group."
  type        = string
  default     = "Resource principals used by OCI Full Stack Disaster Recovery"
}

variable "reuse_existing_dynamic_group" {
  description = "Reuse a dynamic group that already exists in the selected identity domain instead of creating another one."
  type        = bool
  default     = false
}

variable "existing_dynamic_group_ocid" {
  description = "OCID of an existing compatible Identity Domains dynamic group."
  type        = string
  default     = ""

  validation {
    condition     = var.existing_dynamic_group_ocid == "" || can(regex("^ocid1\\.dynamicresourcegroup\\..+", var.existing_dynamic_group_ocid))
    error_message = "existing_dynamic_group_ocid must be empty or a valid dynamic resource group OCID."
  }
}

variable "policy_name" {
  description = "Base name of the tenancy-level IAM policy or policy chunks."
  type        = string
  default     = "fsdr-resource-principal-policy"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,90}$", var.policy_name))
    error_message = "policy_name must contain 1-90 letters, digits, periods, underscores, or hyphens."
  }
}

variable "policy_description" {
  description = "Description of the tenancy-level IAM policy."
  type        = string
  default     = "Permissions used by OCI Full Stack Disaster Recovery resource principals"
}

variable "policy_identifier_style" {
  description = "Use readable identity-domain, dynamic-group, and compartment paths in policy statements, or use immutable OCIDs."
  type        = string
  default     = "NAMES"

  validation {
    condition     = contains(["NAMES", "OCIDS"], var.policy_identifier_style)
    error_message = "policy_identifier_style must be NAMES or OCIDS."
  }
}

variable "dr_protection_groups_in_tenancy" {
  description = "Match DR Protection Groups and grant disaster-recovery-family permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "dr_protection_group_compartment_ids" {
  description = "Compartments containing the DR Protection Groups."
  type        = list(string)
  default     = []
}

variable "enable_object_storage" {
  description = "Grant Object Storage permissions for DR execution logs, protected buckets, OKE, or user-defined steps."
  type        = bool
  default     = true
}

variable "object_storage_in_tenancy" {
  description = "Grant Object Storage permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "object_storage_compartment_ids" {
  description = "Compartments containing DR log buckets or protected Object Storage buckets."
  type        = list(string)
  default     = []
}

variable "enable_networking" {
  description = "Grant virtual-network-family permissions. Needed by Compute, Autonomous Database, load balancers, File Storage, and OKE when networking is managed by DR."
  type        = bool
  default     = false
}

variable "networking_in_tenancy" {
  description = "Grant networking permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "network_compartment_ids" {
  description = "Compartments containing networking resources used by protected applications."
  type        = list(string)
  default     = []
}

variable "enable_vault" {
  description = "Allow Full Stack DR to read vaults and secrets."
  type        = bool
  default     = false
}

variable "vault_in_tenancy" {
  description = "Grant Vault read permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "vault_compartment_ids" {
  description = "Compartments containing vaults and secrets required during DR operations."
  type        = list(string)
  default     = []
}

variable "enable_compute" {
  description = "Protect Compute instances, including Oracle Cloud Agent operations."
  type        = bool
  default     = false
}

variable "compute_in_tenancy" {
  description = "Grant Compute and Oracle Cloud Agent permissions throughout the tenancy. Matching remains limited to the selected Compute compartments."
  type        = bool
  default     = false
}

variable "compute_compartment_ids" {
  description = "Compartments containing protected Compute instances. These are also used in dynamic-group matching rules."
  type        = list(string)
  default     = []
}

variable "enable_volume_groups" {
  description = "Protect Block Volume volume groups."
  type        = bool
  default     = false
}

variable "volume_groups_in_tenancy" {
  description = "Grant volume-family permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "volume_group_compartment_ids" {
  description = "Compartments containing protected volume groups."
  type        = list(string)
  default     = []
}

variable "enable_file_systems" {
  description = "Protect File Storage file systems."
  type        = bool
  default     = false
}

variable "file_systems_in_tenancy" {
  description = "Grant file-family permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "file_system_compartment_ids" {
  description = "Compartments containing protected file systems."
  type        = list(string)
  default     = []
}

variable "enable_database" {
  description = "Protect Oracle Base Database or Exadata Database resources."
  type        = bool
  default     = false
}

variable "database_in_tenancy" {
  description = "Grant database-family permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "database_compartment_ids" {
  description = "Compartments containing protected Oracle Database resources."
  type        = list(string)
  default     = []
}

variable "enable_autonomous_database" {
  description = "Protect Autonomous Database resources."
  type        = bool
  default     = false
}

variable "autonomous_database_in_tenancy" {
  description = "Grant autonomous-database-family permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "autonomous_database_compartment_ids" {
  description = "Compartments containing protected Autonomous Databases."
  type        = list(string)
  default     = []
}

variable "enable_autonomous_container_database" {
  description = "Protect Autonomous Container Database and Cloud Autonomous VM Cluster resources."
  type        = bool
  default     = false
}

variable "autonomous_container_database_in_tenancy" {
  description = "Grant Autonomous Container Database permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "autonomous_container_database_compartment_ids" {
  description = "Compartments containing protected Autonomous Container Databases."
  type        = list(string)
  default     = []
}

variable "enable_mysql" {
  description = "Protect MySQL HeatWave DB Systems."
  type        = bool
  default     = false
}

variable "mysql_in_tenancy" {
  description = "Grant MySQL permissions and match compute container instances throughout the tenancy."
  type        = bool
  default     = false
}

variable "mysql_compartment_ids" {
  description = "Compartments containing protected MySQL DB Systems."
  type        = list(string)
  default     = []
}

variable "enable_load_balancers" {
  description = "Protect OCI Load Balancers."
  type        = bool
  default     = false
}

variable "load_balancers_in_tenancy" {
  description = "Grant Load Balancer permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "load_balancer_compartment_ids" {
  description = "Compartments containing protected load balancers."
  type        = list(string)
  default     = []
}

variable "enable_network_load_balancers" {
  description = "Protect OCI Network Load Balancers."
  type        = bool
  default     = false
}

variable "network_load_balancers_in_tenancy" {
  description = "Grant Network Load Balancer permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "network_load_balancer_compartment_ids" {
  description = "Compartments containing protected network load balancers."
  type        = list(string)
  default     = []
}

variable "enable_oke" {
  description = "Protect Oracle Kubernetes Engine clusters."
  type        = bool
  default     = false
}

variable "oke_in_tenancy" {
  description = "Grant OKE permissions and match compute container instances throughout the tenancy."
  type        = bool
  default     = false
}

variable "oke_compartment_ids" {
  description = "Compartments containing protected OKE clusters."
  type        = list(string)
  default     = []
}

variable "enable_oke_virtual_nodes" {
  description = "Add BRIE workload-principal Object Storage policies for OKE virtual node pools."
  type        = bool
  default     = false
}

variable "oke_cluster_ocids" {
  description = "OKE cluster OCIDs used in BRIE workload-principal conditions."
  type        = list(string)
  default     = []
}

variable "enable_user_defined_steps" {
  description = "Run scripts through Oracle Cloud Agent in user-defined DR Plan steps."
  type        = bool
  default     = false
}

variable "user_defined_steps_in_tenancy" {
  description = "Grant Oracle Cloud Agent command permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "user_defined_step_compartment_ids" {
  description = "Compartments containing Compute instances targeted by user-defined steps."
  type        = list(string)
  default     = []
}

variable "enable_functions" {
  description = "Invoke OCI Functions from DR Plan steps."
  type        = bool
  default     = false
}

variable "functions_in_tenancy" {
  description = "Grant Functions permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "function_compartment_ids" {
  description = "Compartments containing Functions applications and functions invoked by DR Plans."
  type        = list(string)
  default     = []
}

variable "enable_integration" {
  description = "Protect Oracle Integration instances."
  type        = bool
  default     = false
}

variable "integration_in_tenancy" {
  description = "Grant Oracle Integration permissions throughout the tenancy."
  type        = bool
  default     = false
}

variable "integration_compartment_ids" {
  description = "Compartments containing protected Oracle Integration instances."
  type        = list(string)
  default     = []
}

# OCI Resource Manager renders dynamic OCI selectors only as top-level schema
# variables. These fixed slots provide dropdowns while the *_compartment_ids
# lists above remain available for CLI/API callers and backward compatibility.
variable "dr_protection_group_compartment_id_1" { default = "" }
variable "dr_protection_group_compartment_id_2" { default = "" }
variable "dr_protection_group_compartment_id_3" { default = "" }
variable "object_storage_compartment_id_1" { default = "" }
variable "object_storage_compartment_id_2" { default = "" }
variable "object_storage_compartment_id_3" { default = "" }
variable "network_compartment_id_1" { default = "" }
variable "network_compartment_id_2" { default = "" }
variable "network_compartment_id_3" { default = "" }
variable "vault_compartment_id_1" { default = "" }
variable "vault_compartment_id_2" { default = "" }
variable "vault_compartment_id_3" { default = "" }
variable "compute_compartment_id_1" { default = "" }
variable "compute_compartment_id_2" { default = "" }
variable "compute_compartment_id_3" { default = "" }
variable "volume_group_compartment_id_1" { default = "" }
variable "volume_group_compartment_id_2" { default = "" }
variable "volume_group_compartment_id_3" { default = "" }
variable "file_system_compartment_id_1" { default = "" }
variable "file_system_compartment_id_2" { default = "" }
variable "file_system_compartment_id_3" { default = "" }
variable "database_compartment_id_1" { default = "" }
variable "database_compartment_id_2" { default = "" }
variable "database_compartment_id_3" { default = "" }
variable "autonomous_database_compartment_id_1" { default = "" }
variable "autonomous_database_compartment_id_2" { default = "" }
variable "autonomous_database_compartment_id_3" { default = "" }
variable "autonomous_container_database_compartment_id_1" { default = "" }
variable "autonomous_container_database_compartment_id_2" { default = "" }
variable "autonomous_container_database_compartment_id_3" { default = "" }
variable "mysql_compartment_id_1" { default = "" }
variable "mysql_compartment_id_2" { default = "" }
variable "mysql_compartment_id_3" { default = "" }
variable "load_balancer_compartment_id_1" { default = "" }
variable "load_balancer_compartment_id_2" { default = "" }
variable "load_balancer_compartment_id_3" { default = "" }
variable "network_load_balancer_compartment_id_1" { default = "" }
variable "network_load_balancer_compartment_id_2" { default = "" }
variable "network_load_balancer_compartment_id_3" { default = "" }
variable "oke_compartment_id_1" { default = "" }
variable "oke_compartment_id_2" { default = "" }
variable "oke_compartment_id_3" { default = "" }
variable "user_defined_step_compartment_id_1" { default = "" }
variable "user_defined_step_compartment_id_2" { default = "" }
variable "user_defined_step_compartment_id_3" { default = "" }
variable "function_compartment_id_1" { default = "" }
variable "function_compartment_id_2" { default = "" }
variable "function_compartment_id_3" { default = "" }
variable "integration_compartment_id_1" { default = "" }
variable "integration_compartment_id_2" { default = "" }
variable "integration_compartment_id_3" { default = "" }
