Openshift 4 Offline Bundle Generation Tool
=========

Generates an Openshift dependency bundle for desired cloud, execution platform, and latest version. This is used to aggregate dependencies from all of the various Red Hat official resources. You choose how to compress/package the directory contents.

This tool does not create the tarball for you, but pre-baked packages are available below if you do not wish to execute your own.

This tool will not assume simultaneous contiguous access to a destination image repository. This tool is used to produce local disk content only.

This tool will not create or fill an image registry for you.

Pre-reqs
--------------

* Ansible
* Makeself - makeself.noarch

Pre-Generated Bundles
--------------

Please check releases for latest download links.

<br />

| Status | Download Link | Checksum |
|--|--|--|

<br />

Playbook Variables
--------------

There is an example yaml file under examples/my_variables.yaml that you can use.

<br />

| Variable | Options | Description | Default Value |
|--|--|--|--|
| **cloud_selection** (*string*) | *aws, gcp, openstack, azure, rhv, vmware, metal* | Selects the appropriate target image to download from the latest releases image repository. | aws |
| **destination** (*string*) |  | Local path where you want the image to be saved. Can be a directory, or an absolute file path. |  |
| **desired_os_platform** (*string*)| *linux, macos, windows* | Which type of operating system you want to download binaries such as *oc* and *openshift-install* for. | linux |
| **desired_ocp_version** (*string*)| 4.6.8 or stable-4.11 | Version of Openshift to target for pulling dependencies |  |
| **desired_archive_size** (*string*)| 4 | Archive size in GiB passed to oc-mirror for size of tar balls created |  |
| **pull_secret_path** (*string*) |  | Path to your pull secret file, which can be obtained in the Red Hat Cluster Manager website. |  |
| **bundle_destination_dir** (*string*) | | Temporary directory where self-extracting bundles will be created | |
| **openshift_full_channel** (*bool*) | | Whether you want the full channel or not as an oc-mirror option ||
| **openshift_min_version** || oc-mirror optional: min value for OpenShift version ||
| **openshift_max_version** || oc-mirror optional: max value for OpenShift version ||
| **openshift_shortest_path** || oc-mirror optional: Tell oc-mirror to use shortest path ||
| **olm_catalog_version** || Version of OLM catalog to use for operators ||
| **olm_debug**           || Debug flag to show OLM versions during run ||
| **desired_redhat_operators** || List of Red Hat Operators to be mirrored | *name* - name of operator, *channel* - channel for operator |
| **desired_redhat_operators_additional_images** || List of additional images | *name* - Name of additional image |
| **desired_community_operators** || List of Community Operators to be mirrored ||
| **desired_community_operators_additional_images** || List of additional images | *name* - Name of additional image |

<br />

Use Guide
--------------

While it is preferred to just download one of the pre-fabricated bundles we have provided above in the release download links, if you need to generate a bundle with your own custom code, or for a different version of Openshift, please feel free to follow these instructions:

<br />

**Recommended**: Write desired values to a variables YAML file, then input through `--extra-vars`. This can be automated.

```yaml
cat > my_variables.yml << EOF
###################################
#
# Variables for OpenShift Images gathering
#
###################################

#
# Cloud selection
#
cloud_selection: aws

#
# Destination directory where you want all the binaries and images to be placed.
#
destination: /home/claudiol/work/bundle-4.11

#
# Platform target
#
desired_os_platform: linux

#
# Version of OpenShift needed.  Valid values are: stable-4.X or 4.X.X
#
#desired_ocp_version: "stable-4.12"
desired_ocp_version: "4.11.34"

#
# Path to the OpenShift Pull Secret
#
pull_secret_path: /home/claudiol/work/oc-mirror/pull-secret.txt


#
# Temporary directory where self-extracting bundles will be created
#
bundle_destination_dir: /home/claudiol/temp-4.11

###################################
# oc-mirror variables
###################################

#
# oc-mirror archive size
#
desired_archive_size: 4

#
# Whether you want the full channel or not
#
openshift_full_channel: false

#
# Minimal version for OpenShift
#
openshift_min_version:

#
# Max version for OpenShift
#
openshift_max_version: 

#
# Shortest path
#
openshift_shortest_path: false

#
# Operator full catalog
#
operator_full_catalog: false

###################################
# 
# Operator Section
#
# Variables for Operator Images
#
###################################

#
# OLM version
#
olm_catalog_version: "4.11"
olm_debug: false

# 
# Operators from the redhat-operators catalog
#
# To list redhat operators you can run:
# oc-mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.12
#
desired_redhat_operators: 
  - name: advanced-cluster-management
    channel: release-2.7
  - name: openshift-gitops-operator
    channel: latest

#
# Additional images needed
#
desired_redhat_operators_additional_images:
  - name: registry.redhat.io/redhat/redhat-operator-index:v4.11
  - name: registry.redhat.io/redhat/redhat-marketplace-index:v4.11
  - name: registry.redhat.io/redhat/certified-operator-index:v4.11
  - name: registry.access.redhat.com/ubi8/httpd-24:1-226
  - name: registry.connect.redhat.com/hashicorp/vault:1.12.1-ubi
  - name: registry.redhat.io/ansible-automation-platform-23/ee-supported-rhel8:latest
  - name: ghcr.io/external-secrets/external-secrets:v0.8.1-ubi
  - name: registry.access.redhat.com/ubi8/ubi-minimal:latest
  - name: quay.io/hybridcloudpatterns/utility-container

#
# 
# Operators from the community-operators catalog
#
# To list community operators you can run:
# oc-mirror list operators --catalog registry.redhat.io/redhat/community-operator-index:v4.12
desired_community_operators:
  - name: patterns-operator
    channel: fast
  - name: vault-config-operator
    channel: alpha
  - name: external-secrets-operator
    channel: alpha

#
# Additional images needed
#
desired_community_operators_additional_images:
  - name: registry.redhat.io/redhat/community-operator-index:v4.11


#
# 
# Operators from the certified-operators catalog
#
# To list community operators you can run:
# oc-mirror list operators --catalog registry.redhat.io/redhat/community-operator-index:v4.12
desired_certified_operators: []

#
# Additional images needed
#
desired_certified_operators_additional_images:
  - name: registry.redhat.io/redhat/certified-operator-index:v4.11
EOF

ansible-playbook generate.yml --extra-vars "@my_variables.yml"
```

<br />

**Alternative**: Run the playbook as needed, and provide the inputs to the prompts. This is preferred for direct or manual use as a field tool with no preparation.

```
➜  $ ./create-bundle.sh                                                                                                                
Generating OpenShift images ... done                                                                                                      
Generating Red Hat OpenShift operators ... done                                                                                           
Generating Community OpenShift operators ... done                                                                                         
Generating OpenShift self-extracting bundles ... done  
```

<br />

Bundle Contents
--------------

The contents of the openshift bundles consists of the following:

* Red Hat CoreOS Image | RHCOS is the only supported operating system for OpenShift Container Platform control plane, or master, machines. RHCOS is the default operating system for all cluster machines.
    - [RHCOS Image Release Repository](http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/latest)
* OpenShift Container Images
    - [Official OpenShift Released Images on Quay](https://quay.io/repository/openshift-release-dev/ocp-release?tab=tags)
    - NOTE: You will need to use the oc command to mirror the image contents
* Archived Container Images (.tar)
    - `registry.tar` | Docker-Registry for standing up a temporary external hosted service for bootstrapping the container images into RHCOS nodes
    - `nginx.tar` | Webserver for privately serving .ign Ignition files which are transpiled from the installer
* Optional Tertiary cloud dependencies. These are determined by each cloud provider and their specific needs for enabling image upload/import.
    - see [this link for AWS](https://docs.aws.amazon.com/vm-import/latest/userguide/vmimport-image-import.html) for an example of why these templates are included. (`vmimport-role.json` and `vmimport-policy.json`)
* An appropriate CLI binary per cloud target selection (awscli for AWS, azure-cli python venv for Azure, gcloud-sdk for GCloud/GCP, etc.) Most cloud targets which have native ansible modules available as an interface, are excluded as an opinion. 
    - Azure-CLI is included as a python virtual environment. At time of writing, they did not have a method for sourcing a portable executable such as a static ELF binary. A python virtual environment was compiled and provided by our project maintainers for convenience.
* `oc` binary which is also used to perform the mirroring operation of Openshift content
    - [Official Openshift Client Binaries Repository](http://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/)
    - NOTE: While you can download the `openshift-install` binary from here, historically it has been found that the repo-provided executable and the "proper" executable which is supposed to be extracted from the Quay images are different. Whenever possible, please source your installer executable from the images using `oc`.
* `openshift-install` binary which is extracted from the mirrored blobs produced by `oc` using an adequate Red Hat Cluster Manager pull secret.
    - NOTE: There is a direct relationship between this executable and the OCP release images.  If you use the wrong openshift-install executable it will lead to an unsuccessful deployment of OpenShift.
* `kubectl` binary which is co-sourced within the appropriate `oc` binary tarball for toolchain and client access use cases


<br />

A typical bundle generated with this toolset will appear like so:

```
➜  bundle tree -L 2
.
├── bin
│   ├── bundle-manifest.yaml
│   ├── community-operator-images.yaml
│   ├── image-config.yaml
│   ├── kubectl
│   ├── oc
│   ├── oc-mirror
│   ├── openshift-install
│   └── redhat-operator-images.yaml
├── cloud-dependencies
│   ├── awscli-exe-linux-x86_64.zip
│   ├── aws-vmimport-policy.json
│   └── aws-vmimport-role.json
├── containers
│   ├── mirror-registry.tar.gz
│   ├── nginx.tar
│   └── registry.tar
├── openshift-release-dev
│   └── oc-mirror-workspace
│       └── src
│           ├── charts
│           ├── publish
│           ├── release-signatures
│           └── v2
├── operators
│   ├── community
│   │   ├── mirror_seq1_000000.tar
│   │   ├── oc-mirror-workspace
│   │   └── publish
│   └── redhat
│       ├── mirror_seq1_000000.tar
│       ├── mirror_seq1_000001.tar
│       ├── mirror_seq1_000002.tar
│       ├── mirror_seq1_000003.tar
│       ├── oc-mirror-workspace
│       └── publish
└── rhcos-aws.x86_64.vmdk.gz

18 directories, 20 files
```
<br />

This project/tool does not assume a specific structure, if you so desire, you can leverage the individual Ansible roles in your own projects and create your own generation playbook(s). Please see each role's README.md for role-specific documentation.

Self-extracting Bundle files created
--------------
Self-extracting files created for a particular OpenShift version.

```
.
├── ocp-4.11.34-binaries-installer.run
├── ocp-cloudcli-installer.run
├── ocp-community-operators-installer-0.run
├── ocp-containers-installer.run
├── ocp-redhat-operators-installer-0.run
├── ocp-redhat-operators-installer-1.run
├── ocp-redhat-operators-installer-2.run
└── ocp-redhat-operators-installer-3.run
```

Ansible Roles Included
--------------

* `cloud-dependencies` is the Ansible role that provides the cloud-dependencies folder, with the cloud CLI binaries and tertiary template materials as needed.
* `openshift-content-mirror` is the Ansible role that provides the core Openshift 4 mirror via the `openshift-release-dev` folder seen in this bundle example, which is 1 for 1 what is pulled directly from Quay and the Red Hat Registry when using `oc-mirror` per the product documentation.
* `rhcos-image-download` is the Ansible role that provide the appropriate RHCOS image depending on the cloud target selected. This is used to simplify/translate a simple input parameter such as `rhv, metal, aws, azure, ...` into its appropriate download link, as well as checksum validate the image file.
* `create-ocp-bundles` this is the Ansible role that creates self extracting bundles.
