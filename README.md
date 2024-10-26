# terraform-terraform-template
Template repository for terraform modules. Good for any cloud and any provider.

[![tflint](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/tflint.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/tflint.yaml)
[![trivy](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/trivy.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/trivy.yaml)
[![yamllint](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/yamllint.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/yamllint.yaml)
[![mispell](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/mispell.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/mispell.yaml)
[![pre-commit-check](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/pre-commit-check.yaml/badge.svg?branch=master&event=push)](https://github.com/rhythmictech/terraform-aws-config-remediation-rules/actions/workflows/pre-commit-check.yaml)
<a href="https://twitter.com/intent/follow?screen_name=RhythmicTech"><img src="https://img.shields.io/twitter/follow/RhythmicTech?style=social&logo=twitter" alt="follow on Twitter"></a>

## Example
Here's what using the module will look like
```hcl
module "example" {
  source = "rhythmictech/terraform-mycloud-mymodule
}
```

## About
A bit about this module

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tags"></a> [tags](#module\_tags) | rhythmictech/tags/terraform | ~> 1.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Moniker to apply to all resources in the module | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | User-Defined tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tags_module"></a> [tags\_module](#output\_tags\_module) | Tags Module in it's entirety |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Getting Started
This workflow has a few prerequisites which are installed through the `./bin/install-x.sh` scripts and are linked below. The install script will also work on your local machine. 

- [pre-commit](https://pre-commit.com)
- [terraform](https://terraform.io)
- [tfenv](https://github.com/tfutils/tfenv)
- [terraform-docs](https://github.com/segmentio/terraform-docs)
- [trivy]([https://github.com/tfsec/tfsec](https://github.com/aquasecurity/trivy))
- [tflint](https://github.com/terraform-linters/tflint)

We use `tfenv` to manage `terraform` versions, so the version is defined in the `versions.tf` and `tfenv` installs the latest compliant version.
`pre-commit` is like a package manager for scripts that integrate with git hooks. We use them to run the rest of the tools before apply. 
`terraform-docs` creates the beautiful docs (above),  `tfsec` scans for security no-nos, `tflint` scans for best practices. 
