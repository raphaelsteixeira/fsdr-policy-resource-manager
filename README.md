# OCI Full Stack DR resource-principal policy stack

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/raphaelsteixeira/fsdr-policy-resource-manager/archive/refs/heads/main.zip)

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

For a manual deployment, select **Code** and then **Download ZIP** in GitHub, or download the [current `main` branch archive](https://github.com/raphaelsteixeira/fsdr-policy-resource-manager/archive/refs/heads/main.zip), and upload that generated archive when creating an OCI Resource Manager stack.

## Required operator permissions

The user who creates the stack and runs its Plan, Apply, or Destroy jobs must belong to an OCI IAM group with the permissions below. A tenancy administrator must create this prerequisite policy in the root compartment before the stack is used. Replace the placeholders with the identity domain and group of the **human operator**, the compartment where the Resource Manager stack will be stored, and the identity domain selected for the new dynamic group.

```text
Allow group '<operator-domain>'/'<operator-group>' to manage orm-stacks in compartment id <stack-compartment-ocid>
Allow group '<operator-domain>'/'<operator-group>' to manage orm-jobs in compartment id <stack-compartment-ocid>
Allow group '<operator-domain>'/'<operator-group>' to inspect compartments in tenancy
Allow group '<operator-domain>'/'<operator-group>' to inspect domains in tenancy
Allow group '<operator-domain>'/'<operator-group>' to manage dynamic-groups in tenancy where target.resource.domain.id = '<target-identity-domain-ocid>'
Allow group '<operator-domain>'/'<operator-group>' to manage policies in tenancy
```

- If the Resource Manager stack is stored in the root compartment, replace `in compartment id <stack-compartment-ocid>` with `in tenancy` in the first two statements.
- Members of the tenancy `Administrators` group already have the required access through the tenancy administration policy and do not need this additional policy.
- For a group in the Default identity domain, OCI also accepts the shorter subject `group <operator-group>`.
- If **Reuse an existing dynamic group** is selected, the stack does not create or delete a dynamic group, so the `manage dynamic-groups` statement can be omitted. The operator still needs `inspect domains` because the stack resolves the selected domain for policy generation.
- As an alternative to the `manage dynamic-groups` statement, Oracle permits dynamic-group administration through the Identity Domain Administrator or Security Administrator role in the target domain. Those domain roles do not replace the Resource Manager or `manage policies` statements.
- To let the operator create dynamic groups in any identity domain, remove the `where target.resource.domain.id = ...` condition.
- `manage policies in tenancy` is intentionally powerful: this stack creates IAM policies in the root compartment, and those policies can grant access across the tenancy. Keep this permission limited to a trusted deployment group.
- The operator does not need management access to the protected Compute, database, storage, networking, or OKE resources. This stack only creates the dynamic group and its IAM policies; the generated policies grant the Full Stack DR resource principals their runtime access.

Oracle references: [Securing Resource Manager](https://docs.oracle.com/iaas/Content/Security/Reference/resourcemanager_security.htm), [IAM policy reference for identity domains](https://docs.oracle.com/en-us/iaas/Content/Identity/policyreference/iampolicyreference.htm), and [Managing dynamic groups](https://docs.oracle.com/iaas/Content/Identity/dynamicgroups/managingdynamicgroups.htm).

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
