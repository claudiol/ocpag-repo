rhcos-image-download
=========

Downloads the appropriate latest RHCOS immutable image for the selected cloud target platform, sourced from the official Red Hat RHCOS Image repository found here: http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/

This role can be used to source the image in use cases where the target cloud region, or infrastructure does not have an adequate publicly available image to use, or if you are building and deploying Openshift 4 privately on-premises. 

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
| **cloud_target** (*string*) | *aws, gcp, openstack, azure, vmware, metal* | Selects the appropriate target image to download from the latest releases image repository. See role `vars.yml` for details. | metal |
| **dest** (*string*) |  | Local path where you want the image to be saved. Can be a directory, or an absolute file path. | ./ |


Dependencies
------------

N/A

Example Playbook
----------------

This example will download the appropriate Amazon AWS RHCOS image and save it to your ./local/path directory.

    - hosts: localhost
      roles:
         - role: rhcos-image-download
           dest: "./local/path"
           cloud_target: aws

License
-------

GPL-3.0-or-later

Author Information
------------------

Chris Kuperstein (ckuperst@redhat.com, chris@kuperstein.net) Red Hat
