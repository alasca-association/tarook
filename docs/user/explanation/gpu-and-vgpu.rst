GPU and vGPU Support
====================

Introduction
------------

We basically have to differentiate two different use cases: The GPU
nodes shall be used
:ref:`inside of the Kubernetes cluster <gpu-and-vgpu.internal-usage>`
**or** the gpu nodes shall be used
:ref:`outside of the Kubernetes cluster <gpu-and-vgpu.external-usage>`,
i.e. in an OpenStack cluster deployed on Kubernetes.

.. _gpu-and-vgpu.internal-usage:

Internal Usage
--------------

Internal usage means you want to run e.g. AI workload inside of your
Kubernetes cluster.

If you want to make use of GPUs inside of Kubernetes, set
:ref:`the following <cluster-configuration.kubelet-configuration>`:

.. code:: nix

   # Set this variable if this cluster contains worker with GPU access
   # and you want to make use of these inside of the cluster,
   # so that the driver and surrounding framework is deployed.
   yk8s.kubernetes.is_gpu_cluster = true

This will trigger the setup automation. GPU support inside Kubernetes is
achieved by 3 main components:

-  The presence of the nvidia driver on the workers
-  The presence of the nvidia container toolkit for the
   container runtime
-  The presence of the nvidia device plugin for
   kubernetes

Implementation-wise the role ``gpu-support-detection`` uses a pci scan
script to detect the presence of an nvidia gpu with the vendor product
id (10de:XXXX). If the detection is successful the ``node_has_gpu`` fact
is defined for the host, and further logic is triggered.

.. _gpu-and-vgpu.external-usage:

External Usage
--------------

If the GPU cards should be used outside of the Kubernetes cluster, on an
abstraction layer above (an OpenStack cluster), we must differentiate
two different use cases: PCIe passthrough and vGPU (slicing).

For direct PCIe passthrough, we **must not** load (better install) any
nvidia drivers.

vGPU Support
~~~~~~~~~~~~

The nvidia vGPUs are licensed products and therefore need extra
configuration.

Nova and the vGPU manager do not get along with parallel creation of
vGPU VM. To avoid the crash use the option ``-parallelism=1`` with
``terraform apply``

vGPU support requires i.e. the installation of a vGPU management
software to slice the actual GPU into virtual ones. The responsible role
is
``vgpu`-support`` (see `here <https://gitlab.com/yaook/k8s/-/tree/devel/k8s-base/roles/vgpu-support>`__).
The procedure is described in the following section.

The vGPU Support is only available for NVIDIA GPUs which support GPU
virtualization. If you want to check if your GPU supports virtualization
you can check the official `NVIDIA
Guide <https://docs.nvidia.com/grid/gpus-supported-by-vgpu.html>`__.

Both AMD CPUs and INTEL CPUs are supported in YAOOK/K8s for GPU
virtualization. To virtualize the GPU the BIOS setting VT-D/IOMMU has to
be enabled. Therefore a ``enable_iommu.cfg`` snippet will be
automatically added in ``/etc/default/grub.d``. This is useful because
the grubfile is not changed and therefore presets are kept and the
``*.cfg`` files in ``grub.d`` are loaded after the grubfile. This allows
us to make additional modifications in the future.

To enable the vGPU support in YAOOK/K8s, the following variables must be
set in the configuration. For a full reference see
:ref:`cluster-configuration.nvidia-configuration`.
The vGPU Manager software can be downloaded in the
`NVIDIA Licensing portal <https://ui.licensing.nvidia.com/>`__.

.. code:: nix

   # vGPU Support
   yk8s.nvidia.vgpu = {
      driver_blob_url = "foo";   # vGPU manager storage location
      manager_filename = "bar";  # vGPU manager
   }

After YAOOK/K8s has been rolled out, the folder for the chosen
configuration still has to be found. The following steps have to be done
only once and are needed for Yaook
`Operator <https://docs.yaook.cloud/index.html>`__ and Openstack.

.. note::

   It is recommended to save the folder name including the
   configuration and GPU so that the process only needs to be performed
   once.

A distinction must be made between two cases.

1. NVIDIA GPU that does not support SR-IOV. (All GPUs before the
   Ampere architectur)


   Physical GPUs supporting virtual GPUs propose mediate device types (mdev). To see the required properties, go to the following folder.  Note: You still need to get the right PCI port, in which the GPU is plugged in.

   .. code:: console

      $ lspci | grep NVIDIA
      82:00.0 3D controller: NVIDIA Corporation TU104GL [Tesla T4] (rev a1)


   Find the folder with your desired vGPU configuration. Replace `"vgpu-type"` with your chosen vGPU configuration.

   .. code:: console

      $ grep -l "vgpu-type" nvidia-*/name

2. NVIDIA GPU that supports SR-IOV. (All GPUs of the Ampere architecture
   or newer)

   Obtain the bus, domain, slot and function of the available virtual
   functions on the GPU.

   .. code:: console

      $ ls -l /sys/bus/pci/devices/domain\:bus\:slot.function/ | grep virtfn

   This example shows the output of this command for a physical GPU with
   the slot 00, bus 82, domain 0000 and function 0.

   .. code:: console

      $ ls -l /sys/bus/pci/devices/0000:82:00.0/ | grep virtfn
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn0 -> ../0000:82:00.4
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn1 -> ../0000:82:00.5
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn10 -> ../0000:82:01.6
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn11 -> ../0000:82:01.7
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn12 -> ../0000:82:02.0
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn13 -> ../0000:82:02.1
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn14 -> ../0000:82:02.2
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn15 -> ../0000:82:02.3
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn2 -> ../0000:82:00.6
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn3 -> ../0000:82:00.7
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn4 -> ../0000:82:01.0
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn5 -> ../0000:82:01.1
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn6 -> ../0000:82:01.2
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn7 -> ../0000:82:01.3
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn8 -> ../0000:82:01.4
      lrwxrwxrwx 1 root root           0 Jul 25 07:57 virtfn9 -> ../0000:82:01.5

   Choose the virtual function on which you want to create the vGPU.
   Change to the ``mdev_supported_types`` directory on which you want to
   create the vGPU and find the subdirectory, that contains your chosen
   vGPU configuration. Replace ``vgpu-type`` with your chosen vGPU
   configuration.

   .. code:: console

      $ cd /sys/class/mdev_bus/0000\:82\:00.4/mdev_supported_types/
      $ grep -l "vgpu-type" nvidia-*/name

3. With the subdirectory name information you can proceed with the Yaook
   `Operator <https://docs.yaook.cloud/index.html>`__. There you can set
   the ``enable_vgpu_types`` in the ``nova.yaml``. The file is located
   under ``operator/docs/examples/nova.yaml``.

   .. code:: yaml

      compute:
        configTemplates:
        - nodeSelectors:
          - matchLabels: {}
          novaComputeConfig:
            DEFAULT:
              debug: True
            devices:
              enabled_vgpu_types:
              - nvidia-233

Physical host considerations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Customers may have different
`scheduling preferences <https://docs.nvidia.com/grid/10.0/grid-vgpu-user-guide/index.html#vgpu-scheduler-time-slice>`__.

Some vGPU VM might fail to start depending on the vGPU model if
`ECC is enabled <https://docs.nvidia.com/grid/10.0/grid-vgpu-user-guide/index.html#disabling-enabling-ecc-memory>`__.
