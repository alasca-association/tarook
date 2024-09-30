Using configuration variables in scripts
========================================

As briefly described in :doc:`cluster-configuration </user/reference/cluster-configuration>`, the Nix module is responsible for
generating the new state and the inventory from the config and the current state.


::

                     +---------+
                     | ./state |
                     +--+---^--+
                        |   |
                  +------v---+---------+
   +----------+   |                    |   +-------------+
   |  config  +--->     Nix module     +---> ./inventory |
   +----------+   |                    |   +-------------+
                  +--------------------+

Most of the configuration typically resides inside the ./config directory, but that is entirely up to the admins of the cluster.
Eg. inside flake.nix, additional dependencies are pulled that set certain configuration options. The configuration may be written in
Nix, TOML, YAML etc.

This means that, no other part of the LCM must make any assumptions about how the configuration looks. In fact, the only sources of truth
should be the directories ./state and ./inventory. Thus, every script that needs to access any configuration must first run the update_inventory.sh action.
