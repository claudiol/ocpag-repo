cloud-dependencies
=========

Downloads the appropriate tooling binaries needed to automate against common cloud providers programatically.

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
| **cloud_target** (*string*) | *aws, gcp, azure* | Selects the appropriate target image to download from the latest releases image repository. See role `vars.yml` for details. | metal |
| **dest** (*string*) |  | Local path where you want the image to be saved. Can be a directory, or an absolute file path. | "bundle" |
|**os_platform** (*string*)| *linux, macos, windows* | Which type of operating system you want to download binaries such as *oc* and *openshift-install* for. | linux |


Dependencies
------------

N/A

Example Playbook
----------------

This example will download the appropriate Amazon AWS RHCOS image and save it to your ./local/path directory.

    - hosts: localhost
      roles:
         - role: cloud-dependencies
           dest: "./local/path"
           cloud_target: aws
           os_platform: linux

License
-------

GPL-3.0-or-later

Author Information
------------------

Chris Kuperstein (ckuperst@redhat.com, chris@kuperstein.net) Red Hat
