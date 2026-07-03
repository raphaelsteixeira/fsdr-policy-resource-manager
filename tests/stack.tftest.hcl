mock_provider "oci" {
  mock_data "oci_identity_domains" {
    defaults = {
      domains = [
        {
          id           = "ocid1.domain.oc1..example"
          display_name = "ExampleDomain"
          url          = "https://idcs-example.identity.oraclecloud.com"
        }
      ]
    }
  }

  mock_data "oci_identity_compartments" {
    defaults = {
      compartments = []
    }
  }


  mock_resource "oci_identity_domains_dynamic_resource_group" {
    defaults = {
      ocid = "ocid1.dynamicresourcegroup.oc1..example"
    }
  }
}

run "selected_products_generate_scoped_rules" {
  command = plan

  variables {
    tenancy_ocid            = "ocid1.tenancy.oc1..example"
    region                  = "eu-madrid-1"
    identity_domain_id      = "ocid1.domain.oc1..example"
    policy_identifier_style = "OCIDS"

    dr_protection_groups_in_tenancy = true
    object_storage_in_tenancy       = true

    enable_compute           = true
    compute_compartment_id_1 = "ocid1.compartment.oc1..compute1"
    compute_compartment_id_2 = "ocid1.compartment.oc1..compute2"

    enable_networking        = true
    network_compartment_id_1 = "ocid1.compartment.oc1..network"

    enable_vault     = true
    vault_in_tenancy = true
  }

  assert {
    condition     = strcontains(output.dynamic_group_matching_rule, "resource.type = 'drprotectiongroup'")
    error_message = "The mandatory DR Protection Group rule was not generated."
  }

  assert {
    condition     = strcontains(output.dynamic_group_matching_rule, "instance.compartment.id = 'ocid1.compartment.oc1..compute1'")
    error_message = "A selected Compute compartment was not added to the matching rule."
  }

  assert {
    condition     = local.scopes.networking == ["compartment id ocid1.compartment.oc1..network"]
    error_message = "The selected network compartment was not converted to the expected IAM policy scope."
  }

  assert {
    condition     = length(oci_identity_policy.fsdr) == 1
    error_message = "This small selection should fit in one IAM policy object."
  }
}

run "large_selection_is_split_at_fifty_statements" {
  command = plan

  variables {
    tenancy_ocid            = "ocid1.tenancy.oc1..example"
    region                  = "eu-madrid-1"
    identity_domain_id      = "ocid1.domain.oc1..example"
    policy_identifier_style = "OCIDS"

    dr_protection_groups_in_tenancy = true
    object_storage_in_tenancy       = true
    enable_networking               = true
    networking_in_tenancy           = true
    enable_vault                    = true
    vault_in_tenancy                = true

    enable_compute = true
    compute_compartment_ids = [
      "ocid1.compartment.oc1..compute01",
      "ocid1.compartment.oc1..compute02",
      "ocid1.compartment.oc1..compute03",
      "ocid1.compartment.oc1..compute04",
      "ocid1.compartment.oc1..compute05",
      "ocid1.compartment.oc1..compute06",
      "ocid1.compartment.oc1..compute07",
      "ocid1.compartment.oc1..compute08",
      "ocid1.compartment.oc1..compute09",
      "ocid1.compartment.oc1..compute10",
      "ocid1.compartment.oc1..compute11",
    ]
  }

  assert {
    condition     = length(oci_identity_policy.fsdr) == 2
    error_message = "More than 50 generated statements must be split across IAM policy objects."
  }

  assert {
    condition     = alltrue([for policy in oci_identity_policy.fsdr : length(policy.statements) <= 50])
    error_message = "An IAM policy object exceeded OCI's 50-statement limit."
  }
}
