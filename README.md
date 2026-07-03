# OCI Full Stack DR resource-principal policy stack

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https%3A%2F%2Fraw.githubusercontent.com%2Fraphaelsteixeira%2Ffsdr-policy-resource-manager%2Fmain%2Foci-fsdr-resource-principal-stack.zip)

This Terraform configuration is designed for OCI Resource Manager. It creates:

- one dynamic group in the identity domain selected in the Resource Manager form;
- one or more root-compartment IAM policies containing only the statements selected for the protected products; and
- dynamic-group matching rules for DR Protection Groups and, when selected, Compute, MySQL HeatWave, and OKE resource principals.

If a prior stack already created the dynamic group, select **Reuse an existing dynamic group** and provide its OCID. Otherwise, choose a display name that is globally unique in the identity domain. Identity Domains returns HTTP 409 when another dynamic group already has that display name.

## Deploy with OCI Resource Manager

1. Select **Deploy to Oracle Cloud** above. OCI Resource Manager opens the Create Stack workflow with the packaged Terraform configuration already selected.
2. Select the identity domain, DR Protection Group compartments, and protected products in the form.
3. For each enabled product, select up to three compartments from the OCI-populated dropdowns, or explicitly select the tenancy-wide option. The OCIDs are passed to Terraform automatically.
4. Run **Plan** and review the `policy_statements` and `dynamic_group_matching_rule` outputs before applying.

For a manual deployment, upload [`oci-fsdr-resource-principal-stack.zip`](./oci-fsdr-resource-principal-stack.zip) when creating an OCI Resource Manager stack.

The IAM policies are always created in the root compartment because the Oracle reference requires tenancy-level statements (`read all-resources`, `use tag-namespaces`, and, for Compute, `use instance-images`) and because one deployment may target compartments in different branches of the compartment hierarchy. Product permissions remain compartment-scoped unless their tenancy-wide checkbox is selected. Terraform automatically splits the result into policy objects of no more than 50 statements, matching OCI's per-policy limit.

By default, generated policies use readable identifiers: `dynamic-group '<domain-display-name>'/'<dynamic-group-name>'` and full compartment paths such as `Parent:Child`. The form can switch to immutable OCIDs when policies must survive identity or compartment renames.

## Notes

- DR Protection Group matching is mandatory.
- Object Storage is enabled by default because Full Stack DR uses it for DR Plan execution logs. Select the compartment containing the log bucket, or disable it only if your design does not require the documented access.
- Compute needs at least one selected Compute compartment even with tenancy-wide IAM permissions; Oracle's documented Compute dynamic-group matching rule is compartment based.
- MySQL and OKE use compute container instance resource principals. A tenancy-wide selection uses Oracle's documented all-compartments `computecontainerinstance` rule.
- OKE virtual node pools require the OKE cluster OCIDs and Object Storage to be enabled so the BRIE workload-principal policies can be generated.
- Networking and Vault are separate checkboxes because those resources frequently reside in compartments different from the protected service.
- The stack enforces Oracle's documented shared-service prerequisites: relevant Compute, database, storage, load balancer, and OKE selections require Networking and/or Vault; MySQL, OKE, and user-defined steps require Object Storage. Compute also receives volume and networking permissions in its selected compartments, while the shared-service selectors can add different compartments.
- Oracle's Full Stack DR page currently shows `update cloud-autonomous-vmclusters`, but `update` is not a valid OCI IAM metaverb. This stack uses `use cloud-autonomous-vmclusters` and `use autonomous-vmclusters`, which Oracle's Database IAM reference maps to the required VM-cluster update permissions for Oracle Public Cloud and Exadata Cloud@Customer.

Policy source: [Oracle Full Stack Disaster Recovery — Resource Principals](https://docs.oracle.com/en-us/iaas/disaster-recovery/doc/resource-principal.html).
