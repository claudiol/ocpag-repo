Openshift 4 Offline Bundle Generation Tool
=========

Generates an Openshift dependency bundle for desired cloud, execution platform, and latest version. This is used to aggregate dependencies from all of the various Red Hat official resources. You choose how to compress/package the directory contents.

This tool does not create the tarball for you, but pre-baked packages are available below if you do not wish to execute your own.

This tool will not assume simultaneous contiguous access to a destination image repository. This tool is used to produce local disk content only.

This tool will not create or fill an image registry for you.

Pre-Generated Bundles
--------------

Please check releases for latest download links.

<br />

| Status | Download Link | Checksum |
|--|--|--|
| ![AWS Bundle](https://github.com/mikthoma/ocpag-repo/workflows/AWS%20Bundle/badge.svg?branch=4.6.8) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/aws/openshift4-aws-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/aws/sha256sum.txt) |
| ![Azure Bundle](https://github.com/mikthoma/ocpag-repo/workflows/Azure%20Bundle/badge.svg?branch=4.6.8) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/aws/openshift4-azure-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/azure/sha256sum.txt) |
| ![VMWare Bundle](https://github.com/mikthoma/ocpag-repo/workflows/VMWare%20Bundle/badge.svg?branch=4.6.8) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/vmware/openshift4-vmware-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/vmware/sha256sum.txt) |
| ![GCP Bundle](https://github.com/mikthoma/ocpag-repo/workflows/GCP%20Bundle/badge.svg?branch=4.6.8) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/gcp/openshift4-gcp-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/gcp/sha256sum.txt) |
| ![Openstack Bundle](https://github.com/mikthoma/ocpag-repo/workflows/Openstack%20Bundle/badge.svg?branch=4.6.8) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/openstack/openshift4-openstack-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/openstack/sha256sum.txt) |
| ![Metal Bundle](https://github.com/mikthoma/ocpag-repo/workflows/Metal%20Bundle/badge.svg?branch=4.6.8) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/baremetal/openshift4-metal-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/baremetal/sha256sum.txt) |
| ![Red Hat Virtualization Bundle](https://github.com/mikthoma/ocpag-repo/workflows/RHV%20Bundle/badge.svg?branch=4.6.8) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/rhv/openshift4-rhv-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/rhv/sha256sum.txt) |

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

<br />

Use Guide
--------------

While it is preferred to just download one of the pre-fabricated bundles we have provided above in the release download links, if you need to generate a bundle with your own custom code, or for a different version of Openshift, please feel free to follow these instructions:

<br />

**Recommended**: Write desired values to a variables YAML file, then input through `--extra-vars`. This can be automated.

```yaml
cat > my_variables.yml << EOF
cloud_selection: aws
destination: /home/claudiol/work/bundle
desired_os_platform: linux
desired_ocp_version: "4.11.20"
pull_secret_path: /home/claudiol/work/oc-mirror/pull-secret.txt
desired_archive_size: 4
EOF

ansible-playbook generate.yml --extra-vars "@my_variables.yml"
```

<br />

**Alternative**: Run the playbook as needed, and provide the inputs to the prompts. This is preferred for direct or manual use as a field tool with no preparation.

```
➜  ansible-playbook generate.yml



[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
Desired path to dump content (example: /home/user1/bundle): /home/user1/folder
Cloud to generate content for (aws,gcp,azure,metal,vmware,openstack) [aws]: 
Path to your Pull Secret file (example: /home/user1/pull_secret.txt): /home/user1/pull_secret.txt
Desired Operating System Platform for execution (linux,macos,windows) [linux]: 
Desired Openshift Version [4.6.8]: 

PLAY [Generate Openshift Bundle] ***********************************
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
├── bin
│   ├── bundle-manifest.yaml
│   ├── image-config.yaml
│   ├── kubectl
│   ├── oc
│   ├── oc-mirror
│   └── openshift-install
├── cloud-dependencies
│   ├── awscli-exe-linux-x86_64.zip
│   ├── aws-vmimport-policy.json
│   └── aws-vmimport-role.json
├── containers
│   ├── mirror-registry.tar.gz
│   ├── nginx.tar
│   └── registry.tar
├── openshift-release-dev
│   ├── mirror_seq1_000000.tar
│   ├── mirror_seq1_000001.tar
│   ├── mirror_seq1_000002.tar
│   ├── mirror_seq1_000003.tar
│   ├── oc-mirror-workspace
│   └── publish
└── rhcos-aws.x86_64.vmdk.gz
```
<br />

This project/tool does not assume a specific structure, if you so desire, you can leverage the individual Ansible roles in your own projects and create your own generation playbook(s). Please see each role's README.md for role-specific documentation.

Ansible Roles Included
--------------

* `cloud-dependencies` is the Ansible role that provides the cloud-dependencies folder, with the cloud CLI binaries and tertiary template materials as needed.
* `openshift-content-mirror` is the Ansible role that provides the core Openshift 4 mirror via the `openshift-release-dev` folder seen in this bundle example, which is 1 for 1 what is pulled directly from Quay and the Red Hat Registry when using `oc-mirror` per the product documentation.
* `rhcos-image-download` is the Ansible role that provide the appropriate RHCOS image depending on the cloud target selected. This is used to simplify/translate a simple input parameter such as `rhv, metal, aws, azure, ...` into its appropriate download link, as well as checksum validate the image file.
* `create-ocp-bundles` this is the Ansible role that creates self extracting bundles.
