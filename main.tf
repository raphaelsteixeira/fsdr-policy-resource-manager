resource "oci_identity_domains_dynamic_resource_group" "fsdr" {
  count = var.reuse_existing_dynamic_group ? 0 : 1

  display_name  = var.dynamic_group_name
  description   = var.dynamic_group_description
  idcs_endpoint = local.selected_identity_domain.url
  matching_rule = local.dynamic_group_matching_rule
  schemas       = ["urn:ietf:params:scim:schemas:oracle:idcs:DynamicResourceGroup"]

  lifecycle {
    precondition {
      condition     = length(local.selected_identity_domains) == 1
      error_message = "identity_domain_id must identify exactly one identity domain visible in the selected region."
    }

    precondition {
      condition     = length(local.missing_compartment_selections) == 0
      error_message = "Select at least one compartment or enable tenancy scope for: ${join(", ", local.missing_compartment_selections)}."
    }

    precondition {
      condition     = !var.enable_compute || length(local.compartment_ids.compute) > 0
      error_message = "Compute requires at least one Compute compartment for its instance dynamic-group matching rule, even when its IAM permissions are tenancy-wide."
    }

    precondition {
      condition     = !var.enable_oke_virtual_nodes || (var.enable_oke && var.enable_object_storage && length(var.oke_cluster_ocids) > 0)
      error_message = "OKE virtual nodes require OKE and Object Storage to be enabled and at least one OKE cluster OCID."
    }


    precondition {
      condition     = !var.reuse_existing_dynamic_group || var.existing_dynamic_group_ocid != ""
      error_message = "Select an existing dynamic group OCID when reuse_existing_dynamic_group is enabled."
    }

    precondition {
      condition     = !local.requires_networking || var.enable_networking
      error_message = "Networking must be enabled for the selected Compute, File Storage, Autonomous Database, Load Balancer, or OKE protection."
    }

    precondition {
      condition     = !local.requires_vault || var.enable_vault
      error_message = "Vault must be enabled for the selected Compute, Block Volume, File Storage, Database, Autonomous Database, or OKE protection."
    }

    precondition {
      condition     = !local.requires_object_storage || var.enable_object_storage
      error_message = "Object Storage must be enabled for the selected MySQL, OKE, or user-defined step protection."
    }
  }
}

locals {
  dynamic_group_ocid    = var.reuse_existing_dynamic_group ? var.existing_dynamic_group_ocid : oci_identity_domains_dynamic_resource_group.fsdr[0].ocid
  dynamic_group_subject = var.policy_identifier_style == "NAMES" ? "dynamic-group '${local.selected_identity_domain.display_name}'/'${var.dynamic_group_name}'" : "dynamic-group id ${local.dynamic_group_ocid}"

  common_policy_statements = [
    "Allow ${local.dynamic_group_subject} to use tag-namespaces in tenancy",
    "Allow ${local.dynamic_group_subject} to read all-resources in tenancy",
  ]

  dr_policy_statements = [
    for scope in local.scopes.dr :
    "Allow ${local.dynamic_group_subject} to manage disaster-recovery-family in ${scope}"
  ]

  object_storage_policy_statements = var.enable_object_storage ? [
    for scope in local.scopes.object_storage :
    "Allow ${local.dynamic_group_subject} to manage object-family in ${scope}"
  ] : []

  requires_networking = anytrue([
    var.enable_compute,
    var.enable_file_systems,
    var.enable_autonomous_database,
    var.enable_load_balancers,
    var.enable_network_load_balancers,
    var.enable_oke,
  ])

  requires_vault = anytrue([
    var.enable_compute,
    var.enable_volume_groups,
    var.enable_file_systems,
    var.enable_database,
    var.enable_autonomous_database,
    var.enable_autonomous_container_database,
    var.enable_oke,
  ])

  requires_object_storage = anytrue([
    var.enable_mysql,
    var.enable_oke,
    var.enable_user_defined_steps,
  ])

  # Compute commonly keeps attached volumes and VNICs in its own compartment.
  # Merge that scope with explicitly selected shared-service compartments so
  # checking Compute produces its documented volume and networking policies.
  effective_networking_scopes = var.enable_networking && var.networking_in_tenancy ? ["tenancy"] : distinct(concat(
    var.enable_networking ? local.scopes.networking : [],
    var.enable_compute ? local.scopes.compute : [],
  ))

  networking_policy_statements = [
    for scope in local.effective_networking_scopes :
    "Allow ${local.dynamic_group_subject} to manage virtual-network-family in ${scope}"
  ]

  vault_policy_statements = var.enable_vault ? flatten([
    for scope in local.scopes.vault : [
      "Allow ${local.dynamic_group_subject} to read vaults in ${scope}",
      "Allow ${local.dynamic_group_subject} to read secret-family in ${scope}",
    ]
  ]) : []

  compute_policy_statements = var.enable_compute ? concat(flatten([
    for scope in local.scopes.compute : [
      "Allow ${local.dynamic_group_subject} to manage instance-family in ${scope}",
      "Allow ${local.dynamic_group_subject} to use compute-capacity-reservations in ${scope}",
    ]
    ]), [
    "Allow ${local.dynamic_group_subject} to use instance-images in tenancy",
  ]) : []

  effective_volume_scopes = distinct(concat(
    var.enable_volume_groups ? local.scopes.volume_groups : [],
    var.enable_compute ? local.scopes.compute : [],
  ))

  volume_group_policy_statements = [
    for scope in local.effective_volume_scopes :
    "Allow ${local.dynamic_group_subject} to manage volume-family in ${scope}"
  ]

  file_system_policy_statements = var.enable_file_systems ? [
    for scope in local.scopes.file_systems :
    "Allow ${local.dynamic_group_subject} to manage file-family in ${scope}"
  ] : []

  database_policy_statements = var.enable_database ? [
    for scope in local.scopes.database :
    "Allow ${local.dynamic_group_subject} to manage database-family in ${scope}"
  ] : []

  autonomous_database_policy_statements = var.enable_autonomous_database ? [
    for scope in local.scopes.autonomous_database :
    "Allow ${local.dynamic_group_subject} to manage autonomous-database-family in ${scope}"
  ] : []

  autonomous_container_database_policy_statements = var.enable_autonomous_container_database ? flatten([
    for scope in local.scopes.autonomous_container_database : [
      "Allow ${local.dynamic_group_subject} to manage autonomous-container-databases in ${scope}",
      # The Full Stack DR page currently says "update", but update is a
      # permission rather than an OCI IAM metaverb. The Database IAM reference
      # maps *_VM_CLUSTER_UPDATE to the valid, least-privilege "use" metaverb.
      "Allow ${local.dynamic_group_subject} to use cloud-autonomous-vmclusters in ${scope}",
      "Allow ${local.dynamic_group_subject} to use autonomous-vmclusters in ${scope}",
    ]
  ]) : []

  mysql_policy_statements = var.enable_mysql ? [
    for scope in local.scopes.mysql :
    "Allow ${local.dynamic_group_subject} to manage mysql-family in ${scope}"
  ] : []

  load_balancer_policy_statements = var.enable_load_balancers ? [
    for scope in local.scopes.load_balancers :
    "Allow ${local.dynamic_group_subject} to manage load-balancers in ${scope}"
  ] : []

  network_load_balancer_policy_statements = var.enable_network_load_balancers ? [
    for scope in local.scopes.network_load_balancers :
    "Allow ${local.dynamic_group_subject} to manage network-load-balancers in ${scope}"
  ] : []

  oke_policy_statements = var.enable_oke ? flatten([
    for scope in local.scopes.oke : [
      "Allow ${local.dynamic_group_subject} to manage cluster-family in ${scope}",
      "Allow ${local.dynamic_group_subject} to manage cluster-virtualnode-pools in ${scope}",
      "Allow ${local.dynamic_group_subject} to manage compute-container-family in ${scope}",
    ]
  ]) : []

  oke_virtual_node_policy_statements = var.enable_oke_virtual_nodes ? flatten([
    for scope in local.scopes.object_storage : flatten([
      for cluster_ocid in distinct(var.oke_cluster_ocids) : [
        "Allow any-user to manage objects in ${scope} where all { request.principal.type = 'workload', request.principal.namespace = 'brie', request.principal.service_account = 'brie-creator', request.principal.cluster_id = '${cluster_ocid}' }",
        "Allow any-user to manage objects in ${scope} where all { request.principal.type = 'workload', request.principal.namespace = 'brie', request.principal.service_account = 'brie-reader', request.principal.cluster_id = '${cluster_ocid}' }",
      ]
    ])
  ]) : []

  agent_command_scopes = distinct(concat(
    var.enable_compute ? local.scopes.compute : [],
    var.enable_user_defined_steps ? local.scopes.user_defined_steps : [],
  ))

  # Both Compute protection and user-defined steps require these Oracle Cloud
  # Agent permissions. Merging their input-only scopes avoids duplicate policy
  # statements without making policy chunk counts depend on an apply-time OCID.
  agent_command_policy_statements = flatten([
    for scope in local.agent_command_scopes : [
      "Allow ${local.dynamic_group_subject} to manage instance-agent-command-execution-family in ${scope}",
      "Allow ${local.dynamic_group_subject} to manage instance-agent-command-family in ${scope}",
      "Allow ${local.dynamic_group_subject} to manage instance-agent-plugins in ${scope}",
    ]
  ])

  function_policy_statements = var.enable_functions ? flatten([
    for scope in local.scopes.functions : [
      "Allow ${local.dynamic_group_subject} to read fn-app in ${scope}",
      "Allow ${local.dynamic_group_subject} to read fn-function in ${scope}",
      "Allow ${local.dynamic_group_subject} to use fn-invocation in ${scope}",
    ]
  ]) : []

  integration_policy_statements = var.enable_integration ? [
    for scope in local.scopes.integration :
    "Allow ${local.dynamic_group_subject} to manage integration-instance in ${scope}"
  ] : []

  # Do not apply distinct() to this final list: the dynamic group OCID is not
  # known until apply, and distinct() would make the number of policy chunks
  # unknown during planning. Duplicates are removed structurally above.
  policy_statements = concat(
    local.common_policy_statements,
    local.dr_policy_statements,
    local.object_storage_policy_statements,
    local.networking_policy_statements,
    local.vault_policy_statements,
    local.compute_policy_statements,
    local.volume_group_policy_statements,
    local.file_system_policy_statements,
    local.database_policy_statements,
    local.autonomous_database_policy_statements,
    local.autonomous_container_database_policy_statements,
    local.mysql_policy_statements,
    local.load_balancer_policy_statements,
    local.network_load_balancer_policy_statements,
    local.oke_policy_statements,
    local.oke_virtual_node_policy_statements,
    local.agent_command_policy_statements,
    local.function_policy_statements,
    local.integration_policy_statements,
  )

  # OCI permits at most 50 statements in one IAM policy object.
  policy_statement_chunks = chunklist(local.policy_statements, 50)
}

# This policy is deliberately attached to the root compartment. It contains
# mandatory tenancy statements and may target unrelated compartments selected
# in the Resource Manager form.
resource "oci_identity_policy" "fsdr" {
  for_each = {
    for index, statements in local.policy_statement_chunks :
    format("%02d", index + 1) => statements
  }

  compartment_id = var.tenancy_ocid
  name           = length(local.policy_statement_chunks) == 1 ? var.policy_name : "${var.policy_name}-${each.key}"
  description    = length(local.policy_statement_chunks) == 1 ? var.policy_description : "${var.policy_description} (part ${tonumber(each.key)} of ${length(local.policy_statement_chunks)})"
  statements     = each.value

  lifecycle {
    precondition {
      condition     = !var.reuse_existing_dynamic_group || var.existing_dynamic_group_ocid != ""
      error_message = "Provide existing_dynamic_group_ocid when reuse_existing_dynamic_group is enabled."
    }

    precondition {
      condition     = var.policy_identifier_style == "OCIDS" || length(local.unresolved_compartment_ids) == 0
      error_message = "Could not resolve these selected compartment OCIDs to readable paths: ${join(", ", local.unresolved_compartment_ids)}. Use OCIDS policy style or grant Resource Manager permission to list the compartment hierarchy."
    }

    precondition {
      condition     = length(local.policy_statements) <= 500
      error_message = "The generated root policy exceeds OCI's hard limit of 500 policy statements in a compartment hierarchy. Reduce selected tenancy-wide products or compartments."
    }
  }
}
