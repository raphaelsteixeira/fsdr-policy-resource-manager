data "oci_identity_domains" "available" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_compartments" "all" {
  compartment_id            = var.tenancy_ocid
  compartment_id_in_subtree = true
  access_level              = "ANY"
  state                     = "ACTIVE"
}

locals {
  selected_identity_domains = [
    for domain in data.oci_identity_domains.available.domains : domain
    if domain.id == var.identity_domain_id
  ]

  selected_identity_domain = one(local.selected_identity_domains)

  compartment_name_by_id = {
    for compartment in data.oci_identity_compartments.all.compartments :
    compartment.id => compartment.name
  }

  compartment_parent_1_by_id = {
    for compartment in data.oci_identity_compartments.all.compartments :
    compartment.id => compartment.compartment_id
  }
  compartment_parent_2_by_id = {
    for id, parent_id in local.compartment_parent_1_by_id :
    id => lookup(local.compartment_parent_1_by_id, parent_id, "")
  }
  compartment_parent_3_by_id = {
    for id, parent_id in local.compartment_parent_2_by_id :
    id => lookup(local.compartment_parent_1_by_id, parent_id, "")
  }
  compartment_parent_4_by_id = {
    for id, parent_id in local.compartment_parent_3_by_id :
    id => lookup(local.compartment_parent_1_by_id, parent_id, "")
  }
  compartment_parent_5_by_id = {
    for id, parent_id in local.compartment_parent_4_by_id :
    id => lookup(local.compartment_parent_1_by_id, parent_id, "")
  }

  # Policies are attached at tenancy root. OCI compartment-name locations must
  # therefore use a colon-delimited path for nested compartments.
  compartment_path_by_id = {
    for id, name in local.compartment_name_by_id : id => join(":", compact([
      lookup(local.compartment_name_by_id, lookup(local.compartment_parent_5_by_id, id, ""), ""),
      lookup(local.compartment_name_by_id, lookup(local.compartment_parent_4_by_id, id, ""), ""),
      lookup(local.compartment_name_by_id, lookup(local.compartment_parent_3_by_id, id, ""), ""),
      lookup(local.compartment_name_by_id, lookup(local.compartment_parent_2_by_id, id, ""), ""),
      lookup(local.compartment_name_by_id, lookup(local.compartment_parent_1_by_id, id, ""), ""),
      name,
    ]))
  }

  enabled = {
    dr                            = true
    object_storage                = var.enable_object_storage
    networking                    = var.enable_networking
    vault                         = var.enable_vault
    compute                       = var.enable_compute
    volume_groups                 = var.enable_volume_groups
    file_systems                  = var.enable_file_systems
    database                      = var.enable_database
    autonomous_database           = var.enable_autonomous_database
    autonomous_container_database = var.enable_autonomous_container_database
    mysql                         = var.enable_mysql
    load_balancers                = var.enable_load_balancers
    network_load_balancers        = var.enable_network_load_balancers
    oke                           = var.enable_oke
    user_defined_steps            = var.enable_user_defined_steps
    functions                     = var.enable_functions
    integration                   = var.enable_integration
  }

  tenancy_scoped = {
    dr                            = var.dr_protection_groups_in_tenancy
    object_storage                = var.object_storage_in_tenancy
    networking                    = var.networking_in_tenancy
    vault                         = var.vault_in_tenancy
    compute                       = var.compute_in_tenancy
    volume_groups                 = var.volume_groups_in_tenancy
    file_systems                  = var.file_systems_in_tenancy
    database                      = var.database_in_tenancy
    autonomous_database           = var.autonomous_database_in_tenancy
    autonomous_container_database = var.autonomous_container_database_in_tenancy
    mysql                         = var.mysql_in_tenancy
    load_balancers                = var.load_balancers_in_tenancy
    network_load_balancers        = var.network_load_balancers_in_tenancy
    oke                           = var.oke_in_tenancy
    user_defined_steps            = var.user_defined_steps_in_tenancy
    functions                     = var.functions_in_tenancy
    integration                   = var.integration_in_tenancy
  }

  compartment_ids = {
    dr = distinct(compact(concat(var.dr_protection_group_compartment_ids, [
      var.dr_protection_group_compartment_id_1, var.dr_protection_group_compartment_id_2, var.dr_protection_group_compartment_id_3,
    ])))
    object_storage = distinct(compact(concat(var.object_storage_compartment_ids, [
      var.object_storage_compartment_id_1, var.object_storage_compartment_id_2, var.object_storage_compartment_id_3,
    ])))
    networking = distinct(compact(concat(var.network_compartment_ids, [
      var.network_compartment_id_1, var.network_compartment_id_2, var.network_compartment_id_3,
    ])))
    vault = distinct(compact(concat(var.vault_compartment_ids, [
      var.vault_compartment_id_1, var.vault_compartment_id_2, var.vault_compartment_id_3,
    ])))
    compute = distinct(compact(concat(var.compute_compartment_ids, [
      var.compute_compartment_id_1, var.compute_compartment_id_2, var.compute_compartment_id_3,
    ])))
    volume_groups = distinct(compact(concat(var.volume_group_compartment_ids, [
      var.volume_group_compartment_id_1, var.volume_group_compartment_id_2, var.volume_group_compartment_id_3,
    ])))
    file_systems = distinct(compact(concat(var.file_system_compartment_ids, [
      var.file_system_compartment_id_1, var.file_system_compartment_id_2, var.file_system_compartment_id_3,
    ])))
    database = distinct(compact(concat(var.database_compartment_ids, [
      var.database_compartment_id_1, var.database_compartment_id_2, var.database_compartment_id_3,
    ])))
    autonomous_database = distinct(compact(concat(var.autonomous_database_compartment_ids, [
      var.autonomous_database_compartment_id_1, var.autonomous_database_compartment_id_2, var.autonomous_database_compartment_id_3,
    ])))
    autonomous_container_database = distinct(compact(concat(var.autonomous_container_database_compartment_ids, [
      var.autonomous_container_database_compartment_id_1, var.autonomous_container_database_compartment_id_2, var.autonomous_container_database_compartment_id_3,
    ])))
    mysql = distinct(compact(concat(var.mysql_compartment_ids, [
      var.mysql_compartment_id_1, var.mysql_compartment_id_2, var.mysql_compartment_id_3,
    ])))
    load_balancers = distinct(compact(concat(var.load_balancer_compartment_ids, [
      var.load_balancer_compartment_id_1, var.load_balancer_compartment_id_2, var.load_balancer_compartment_id_3,
    ])))
    network_load_balancers = distinct(compact(concat(var.network_load_balancer_compartment_ids, [
      var.network_load_balancer_compartment_id_1, var.network_load_balancer_compartment_id_2, var.network_load_balancer_compartment_id_3,
    ])))
    oke = distinct(compact(concat(var.oke_compartment_ids, [
      var.oke_compartment_id_1, var.oke_compartment_id_2, var.oke_compartment_id_3,
    ])))
    user_defined_steps = distinct(compact(concat(var.user_defined_step_compartment_ids, [
      var.user_defined_step_compartment_id_1, var.user_defined_step_compartment_id_2, var.user_defined_step_compartment_id_3,
    ])))
    functions = distinct(compact(concat(var.function_compartment_ids, [
      var.function_compartment_id_1, var.function_compartment_id_2, var.function_compartment_id_3,
    ])))
    integration = distinct(compact(concat(var.integration_compartment_ids, [
      var.integration_compartment_id_1, var.integration_compartment_id_2, var.integration_compartment_id_3,
    ])))
  }

  scopes = {
    for product, compartment_ids in local.compartment_ids : product => (
      local.tenancy_scoped[product]
      ? ["tenancy"]
      : [
        for compartment_id in distinct(compartment_ids) :
        compartment_id == var.tenancy_ocid ? "tenancy" : (
          var.policy_identifier_style == "NAMES"
          ? "compartment ${lookup(local.compartment_path_by_id, compartment_id, "")}"
          : "compartment id ${compartment_id}"
        )
      ]
    )
  }

  selected_compartment_ids = distinct(flatten(values(local.compartment_ids)))
  unresolved_compartment_ids = [
    for compartment_id in local.selected_compartment_ids : compartment_id
    if compartment_id != var.tenancy_ocid && !contains(keys(local.compartment_path_by_id), compartment_id)
  ]

  missing_compartment_selections = [
    for product, is_enabled in local.enabled : product
    if is_enabled && !local.tenancy_scoped[product] && length(local.compartment_ids[product]) == 0
  ]

  # Oracle documents three resource-principal kinds for Full Stack DR: DR
  # Protection Groups, Compute instances, and compute container instances used
  # for MySQL and OKE operations.
  dr_matching_rules = var.dr_protection_groups_in_tenancy ? [
    "ALL {resource.type = 'drprotectiongroup'}"
    ] : [
    for compartment_id in local.compartment_ids.dr :
    "ALL {resource.type = 'drprotectiongroup', resource.compartment.id = '${compartment_id}'}"
  ]

  compute_matching_rules = var.enable_compute ? [
    for compartment_id in local.compartment_ids.compute :
    "ANY {instance.compartment.id = '${compartment_id}'}"
  ] : []

  mysql_matching_rules = var.enable_mysql ? (
    var.mysql_in_tenancy ? [
      "ALL {resource.type = 'computecontainerinstance'}"
      ] : [
      for compartment_id in local.compartment_ids.mysql :
      "ALL {resource.type = 'computecontainerinstance', resource.compartment.id = '${compartment_id}'}"
    ]
  ) : []

  oke_matching_rules = var.enable_oke ? (
    var.oke_in_tenancy ? [
      "ALL {resource.type = 'computecontainerinstance'}"
      ] : [
      for compartment_id in local.compartment_ids.oke :
      "ALL {resource.type = 'computecontainerinstance', resource.compartment.id = '${compartment_id}'}"
    ]
  ) : []

  dynamic_group_rules = distinct(concat(
    local.dr_matching_rules,
    local.compute_matching_rules,
    local.mysql_matching_rules,
    local.oke_matching_rules,
  ))

  dynamic_group_matching_rule = length(local.dynamic_group_rules) == 1 ? local.dynamic_group_rules[0] : "ANY {${join(", ", local.dynamic_group_rules)}}"
}
