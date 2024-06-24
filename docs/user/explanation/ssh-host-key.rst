SSH Host Key Verification
=========================

SSH host key verification is enabled by default.
The known hosts file is automatically managed and can be found at
``etc/ssh_known_hosts``.

For Ansible, we're making use of TOFU (trust on first use).
To do so, we set

.. code::ini

  [ssh_connection]
  # ...
  ssh_args=-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=../../etc/ssh_known_hosts
  # ...

in the Ansible configuration file ``ansible/ansible.cfg``.

Instead of maintaining a list of keys for each node in the known hosts file,
we make use of the SSH secrets engine of vault and create signed certificates
on each node such that we can just put the CA into the known hosts file.
This allows us to simplify maintaining the relationship of trust.
Certificates are valid for 8 days.

For the creation of the certificates we differentiate two different cases.
For non-productive cluster, we provide the option to deploy a vault instance
inside a docker container which then can be used as backend.
This has the restriction, that nodes are not able to reach that vault instance.
Productive clusters make use of a vault instance which is routable as backend.

Certificate generation (development setup)
------------------------------------------

If a local docker-based development Vault instance is used,
nodes are not able to reach out to that instance.
Therefore, certificates get renewed automatically via the orchestrator
on a rollout.
As mentioned above, certificates are valid for 8 days only.
However, for development clusters this should not be an issue as
development environments are not meant to be long-lasting.
In case a devcluster hasn't been touched for 8 days, the file
``etc/ssh_known_hosts`` can be deleted to reset to TOFU.

Certificate generation (productive setup)
-----------------------------------------

In productive setups, the necessary tools to login to vault get deployed on
each node.
A systemd timer and service is configured which automatically trigger a script
which logins to vault and renews SSH certificates.
This ensures nodes can always present an up-to-date certificate.
