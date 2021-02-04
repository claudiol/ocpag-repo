Openshift 4 Offline Bundle Generation Tool
=========

Generates an Openshift dependency bundle for desired cloud, execution platform, and version. This is used to aggregate dependencies from all of the various Red Hat official resources. You choose how to compress/package the directory contents.

This tool does not create the tarball for you, but pre-baked packages are available below if you do not wish to execute your own.

Pre-Generated Bundles
--------------

Please check releases for latest download links.

<br />

| Status | Download Link | Checksum |
|--|--|--|
| ![AWS Bundle](https://github.com/mikthoma/ocpag-repo/workflows/AWS%20Bundle/badge.svg) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/aws/openshift4-aws-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/aws/sha256sum.txt) |
| ![Azure Bundle](https://github.com/mikthoma/ocpag-repo/workflows/Azure%20Bundle/badge.svg) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/aws/openshift4-azure-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/azure/sha256sum.txt) |
| ![VMWare Bundle](https://github.com/mikthoma/ocpag-repo/workflows/VMWare%20Bundle/badge.svg) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/vmware/openshift4-vmware-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/vmware/sha256sum.txt) |
| ![GCP Bundle](https://github.com/mikthoma/ocpag-repo/workflows/GCP%20Bundle/badge.svg) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/gcp/openshift4-gcp-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/gcp/sha256sum.txt) |
| ![Openstack Bundle](https://github.com/mikthoma/ocpag-repo/workflows/Openstack%20Bundle/badge.svg) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/openstack/openshift4-openstack-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/openstack/sha256sum.txt) |
| ![Metal Bundle](https://github.com/mikthoma/ocpag-repo/workflows/Metal%20Bundle/badge.svg) | [Download](https://ocpagpkg.s3-us-west-1.amazonaws.com/baremetal/openshift4-metal-linux-4.6.8-x86_64.tar.gz) | [sha256sum](https://ocpagpkg.s3-us-west-1.amazonaws.com/baremetal/sha256sum.txt) |

<br />

Playbook Variables
--------------

<br />

| Variable | Options | Description | Default Value |
|--|--|--|--|
| **cloud_selection** (*string*) | *aws, gcp, openstack, azure, vmware, metal* | Selects the appropriate target image to download from the latest releases image repository. | aws |
| **destination** (*string*) |  | Local path where you want the image to be saved. Can be a directory, or an absolute file path. |  |
| **os_platform** (*string*)| *linux, macos, windows* | Which type of operating system you want to download binaries such as *oc* and *openshift-install* for. | linux |
| **ocp_version** (*string*)|  | Version of Openshift to target for pulling dependencies | 4.6.8 |
| **pull_secret_path** (*string*) |  | Path to your pull secret file, which can be obtained in the Red Hat Cluster Manager website. |  |

<br />

Use Guide
--------------

<br />

**Recommended**: Write desired values to a variables YAML file, then input through `--extra-vars`. This can be automated.

```yaml
cat > my_variables.yml << EOF
cloud_selection: aws
destination: /my/destination/folder
os_platform: linux
ocp_version: "4.6.8"
pull_secret_path: /home/user1/pull_secret.txt
EOF

ansible-playbook generate.yml --extra-args "@my_variables.yml"
```

<br />

**Alternative**: Run the playbook as needed, and provide the inputs to the prompts. This is preferred for direct or manual use.

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
