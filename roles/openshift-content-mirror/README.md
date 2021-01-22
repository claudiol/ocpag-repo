rhcos-image-download
=========

Downloads multiple dependencies required to deploy Openshift 4 in a private network. Will store the contents locally to a path.

oc, kubectl, openshift-install, openshift-release-dev, nginx+docker-registry container images are pulled with appropriate matching versions.

Requirements
------------

* Ansible 2.9+ (Execution)
* Molecule (Testing)
* Docker (Testing)

Testing is currently based on CentOS 8. See `molecule/default/molecule.yml` for details.

Role Variables
--------------


| Variable | Options | Description | Default Value |
|--|--|--|--|
| **pull_secret_file** (*string*) |  | Path to your pull secret file, which can be obtained in the Red Hat Cluster Manager website. | /tmp/pull_secret.txt |
| **dest** (*string*) |  | Local path where you want the image to be saved. Can be a directory, or an absolute file path. | ./ |
|**os_platform** (*string*)| *linux, macos, windows* | Which type of operating system you want to download binaries such as *oc* and *openshift-install* for. | linux |
| **ocp_version** (*string*)|  | Version of Openshift to target for pulling dependencies | 4.6.8 |



Dependencies
------------

N/A

Example Playbook
----------------

This example will download the appropriate content and dependencies and save them to your ./local/path directory.

    - hosts: localhost
      roles:
         - role: openshift-content-mirror
           dest: "./local/path"
           pull_Secret_file: "~/Downloads/pull_secret.txt"
           os_platform: linux
           ocp_version: "4.6.8"

License
-------

GPL-3.0-or-later

Author Information
------------------

Chris Kuperstein (ckuperst@redhat.com, chris@kuperstein.net) Red Hat
