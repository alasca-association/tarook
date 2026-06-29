Tarook only has a single primary dependency: Nix. Everything else is fetched or built automatically.

`Nix <https://nixos.org>`__ is a declarative package manager
which powers NixOS but can also be installed as an additional separate package manager on any
other GNU/Linux distribution. This repository contains a flake.nix which references all necessary
dependencies locked to specific versions so everybody can produce the same identical environment.

1. Install Nix on a non NixOS system

   .. note::

      ``nix (Nix) >= 2.9.0`` is required.

   .. tabs::

      .. tab:: Via the official installer

         Follow the `Nix documentation <https://nixos.org/download.html#download-nix>`__ on how to install.

      .. tab:: From Debian/Ubuntu repositories

         Nix can also be installed from the Debian/Ubuntu repositories.

         .. code:: console

            $ # Run installation for debian managed nix multi-user package
            $ sudo apt update && sudo apt install git nix-setup-systemd

            $ # Add current user to nix group
            $ sudo adduser $(whoami) nix-users

         Re-login to your seat (desktop session) or run the following command to use Nix right away:

         .. code:: console

            $ newgrp nix-users

         Note that the ``newgrp`` command starts a new shell and will only have
         effect within that shell.

         The Nix version provided by Debian/Ubuntu is quite old and (at the time of writing) has known vulnerabilities that don't get patched.
         Tarook provides Nix packages that are up-to-date with what we use in our CI.
         To upgrade to our Nix package, run

         .. code:: console

            $ nix run --extra-experimental-features "nix-command flakes" git+https://gitlab.com/alasca.cloud/tarook/nix#upgrade

         This will build and install our version of the `nix-bin` package.
2. `Enable Flake support <https://nixos.wiki/wiki/Flakes#Permanent>`__ by adding the following line to either ``~/.config/nix/nix.conf`` or ``/etc/nix/nix.conf``.

   .. code:: ini

      experimental-features = nix-command flakes

3. (Optional) Add our binary cache in ``/etc/nix/nix.conf``
   so you won't have to build anything from source

   .. code:: ini

      extra-substituters = https://nix-cache.tarook.cloud
      extra-trusted-public-keys = nix-cache.tarook.cloud-2:2X2yPTrpwmakhSgS83FVB2fKkG6IzfOJ1AGIIcvNyM0=

   .. note::

      The binary cache must be configured in ``/etc/nix/nix.conf``.
      Adding it to ``~/.config/nix/nix.conf`` is only doable if the current user
      is added as ``trusted-user`` in ``/etc/nix/nix.conf`` which would have security implications.

4. Restart the systemd service in order for the changes in ``nix.conf`` to take effect.

   .. code:: console

      $ sudo systemctl daemon-reload
      $ sudo systemctl restart nix-daemon

5. Install `direnv <https://direnv.net>`__ and configure its hook for your shell. This is not strictly necessary,
   but the rest of the guide assumes that direnv is available. You can enter the virtual environments and set
   all necessary environment variables manually instead, but then you're on your own.
