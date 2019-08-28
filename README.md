# Terraform GCP GKE Shared VPC Module
This repository contains configuration for managing relationships between host projects and service projects within a Shared VPC on Google Cloud, with the intention of making GKE cluster implementations easy. It does not contain the VPC network configuration itself, but is rather intended to build upon the network configuration within the `shared-vpc` network module in the [terraform-gcp-vpc-native][] repository, which contains two GKE-ready subnetworks intended for use with service projects. Likewise, this module also does not contain the GKE cluster configuration itself, but is also intended to be used with the [terraform-gke][] set of modules to create VPC-native GKE clusters.


## Usage
This is intended to be used within the context of the host project. Add a `shared_vpc.tf` to your host project's terraform configuration and fill it out like so, with the appropriate project names and IDs:

```
module "shared-vpc" {
  source               = "git@github.com:/FairwindsOps/terraform-gcp-gke-shared-vpc?ref=v0.0.1"
  host_project_name    = "demohostproject"
  service_projects = {
    "demoserviceproject0" = "976846051113"
    "demoserviceproject1" = "355184829110"
  }

  service_networks = {
    "demoserviceproject0" = "${module.network.staging_subnetwork}"
    "demoserviceproject1" = "${module.network.prod_subnetwork}"
  }
}
```
Please note that this module can take any number of service projects and networks. Just add the details in the format above, and it will create the necessary resources. 

## Contributing
See [CONTRIBUTING.md](./CONTRIBUTING.md).


## Release Expectations
We intend to use semantic versioning in this repository. This means that release tags will look similar to `v0.0.1`. We never intend any versions to recreate the Shared VPC relationships, since this could result in state loss for the GKE clusters built on this. If any changes are breaking, we will note in release notes. If any compatibility issues are found in the wild, please submit an issue with a way to recreate the scenario.

We do not anticipate retrofitting patches to older MINOR versions. If we are currently on v1.2.0 and a bug is found that was introduced in v1.1.0 we will patch to v1.2.1 (and there will not be a v1.1.1). Pull requests always accepted if you have a need to patch older releases.

### Version Differences
* MAJOR: Changing versions here will require changes to your module parameters
  * Could have new **required** parameters or changes to defaults that could affect implementations
  * May remove certain parameters
  * Will not re-provision your cluster, unless noted in the changelog release notes
* MINOR: Changing minor versions should have parameter backwards compatibility
  * **Required** parameters should not change between MINOR versions
  * _Optional_ parameters may change or there may be new _optional_ parameters
  * We will **not remove _optional_ parameters** between MINOR releases, a MAJOR is required
  * Defaults on _optional_ parameters **may change** between MINOR versions, including default versions or other cluster settings
  * Change Log will outline expected differences between Minor releases
* PATCH: Changing minor defaults or logic fixes
  * Bugs that fix behavior or adjust "constant change" issues in terraform runs
  * Typos could be fixed with patch if it affects behavior of the terraform module
  * Fixes to older supported features of the module that broke with MINOR functionality changes
  * README and USAGE documentation changes may trigger a PATCH change and should be documented in CHANGELOG


[terraform-gcp-vpc-native]: https://github.com/FairwindsOps/terraform-gcp-vpc-native
[terraform-gke]: https://github.com/FairwindsOps/terraform-gke