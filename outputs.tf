output "dynamic_group_ocid" {
  description = "OCID of the Full Stack DR dynamic group."
  value       = local.dynamic_group_ocid
}

output "dynamic_group_reused" {
  description = "True when the stack reused a compatible dynamic group already present in the selected identity domain."
  value       = tostring(var.reuse_existing_dynamic_group)
}

output "dynamic_group_matching_rule" {
  description = "Generated matching rule for the Full Stack DR dynamic group."
  value       = local.dynamic_group_matching_rule
}

output "policy_ocids" {
  description = "OCIDs of the generated Full Stack DR policy objects, one OCID per line."
  value       = join("\n", [for key in sort(keys(oci_identity_policy.fsdr)) : oci_identity_policy.fsdr[key].id])
}

output "policy_statements" {
  description = "Generated policy statements for review, one statement per line."
  value       = join("\n", local.policy_statements)
}
