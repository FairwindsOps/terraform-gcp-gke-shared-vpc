// Copyright 2019 FairwindsOps Inc
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

## This module enables Shared VPC functionality and associates service projects to a host project.
## This terraform configuration can only be ran by an account that is a Shared VPC Admin.
## (see https://cloud.google.com/vpc/docs/provisioning-shared-vpc#nominating_shared_vpc_admins_for_the_organization)

#######################
# Define all the variables we'll need
#######################

variable "host_project_name" {
  description = "The shared VPC host project name"
}

variable "service_projects" {
  description = "map of service project names to project IDs"
  type        = map(string)
}

variable "service_networks" {
  description = "map of service project names to associated subnetworks"
  type        = map(string)
}

#######################
# enable necessary APIs for shared VPC
# note that google_project_service is additive and not authoritative, unlike google_project_services 
# (see https://www.terraform.io/docs/providers/google/r/google_project_services.html on why we aren't using it)
#######################

resource "google_project_service" "host-compute" {
  project = var.host_project_name
  service = "compute.googleapis.com"
}

resource "google_project_service" "host-container" {
  project = var.host_project_name
  service = "container.googleapis.com"
}

#######################
# enable shared VPC for host project, attach service projects to host project
#######################
resource "google_compute_shared_vpc_host_project" "host-shared-vpc" {
  project = var.host_project_name
}

resource "google_compute_shared_vpc_service_project" "service" {
  count           = length(var.service_projects)
  host_project    = var.host_project_name
  service_project = element(keys(var.service_projects), count.index)

  // Shared VPC needs to be enabled on host project fist
  depends_on = [google_compute_shared_vpc_host_project.host-shared-vpc]
}

#######################
# set necessary network permissions on host network for service accounts from service projects, so that they can create resources within their given subnetworks of the host network
#######################
resource "google_compute_subnetwork_iam_member" "cloudservices" {
  count      = length(var.service_projects)
  subnetwork = var.service_networks[element(keys(var.service_networks), count.index)]
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:${var.service_projects[element(keys(var.service_projects), count.index)]}@cloudservices.gserviceaccount.com"
}

resource "google_compute_subnetwork_iam_member" "container-engine-robot" {
  count      = length(var.service_projects)
  subnetwork = var.service_networks[element(keys(var.service_networks), count.index)]
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${var.service_projects[element(keys(var.service_projects), count.index)]}@container-engine-robot.iam.gserviceaccount.com"
}

#######################
# enable GKE API for service projects
#######################
resource "google_project_service" "service-container" {
  count   = length(var.service_projects)
  project = element(keys(var.service_projects), count.index)
  service = "container.googleapis.com"
}

resource "google_project_iam_member" "gke-service-account" {
  count   = length(var.service_projects)
  project = var.host_project_name
  member  = "serviceAccount:service-${var.service_projects[element(keys(var.service_projects), count.index)]}@container-engine-robot.iam.gserviceaccount.com"
  role    = "roles/container.hostServiceAgentUser"
}
