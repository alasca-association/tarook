# Architecture

GPU and vGPU support in kubernetes is achieved by 3 main component:
- The presence of the nvidia driver on the workers (drivers are different for vGPU/GPU)
- The presence of the nvidia runtime for docker
- The presence of the nvidia device plugin for kubernetes

Implementation-wise the role `gpu-and-vpgu` uses a pci scan script to detect the presence of an nvidia gpu with the vendor product id (10de:XXXX). If the detection
is successful the `has_gpu` fact is defined, and further logic is triggered. Thus the `gpu-and-vpgu` becomes dependency of the `docker` role, which checks the `has_gpu` fact as well to decide whenever or not the nvidia runtime has to be installed and set as default.

For the moment, when a GPU is detected, it is assumed to be a pci passed-through GPU, and the classic nvidia driver is installed.

If you wish to install the vGPU driver instead, override the `is_virtual_gpu` to `yes` in the host/group vars.

If you wish to install the device plugin, override the `is_gpu_cluster` variable to `yes` in `group_vars/all.yaml` of `03_final`.


# vGPU operational considerations

The nvidia vGPUs are licensed products and therefore need extra configuration. The licensing is by default triggered with our own nvidia license servers. If you wish to use other servers please override the default variables defined in the `gpu-and-vpgu` role.

Nova and the vGPU manager do not get along with parallel creation of vGPU VM. To avoid the crash use the option `-parallelism=1` with `terraform apply`


# About pci scan and driver install

The pci scan script could detect itself if the GPU is virtual or physical in the future. Indeed the product id of the subsystem is different (`lspci -nnk -d 10de:`). This could be implemented for example by maintaining a whitelist of the physical product ids, and if an unknown product id is encounter for a nvidia device subsystem, the GPU is probably virtual.

If the VM hosts need to see their kernels updated, using the `--dkms` option for the drivers installation may need to be evaluated.

# Physical host considerations

Customers may have different scheduling preferences:
https://docs.nvidia.com/grid/10.0/grid-vgpu-user-guide/index.html#vgpu-scheduler-time-slice

Some vGPU VM might fail to start depending on the vGPU model if ECC is enabled:
https://docs.nvidia.com/grid/10.0/grid-vgpu-user-guide/index.html#disabling-enabling-ecc-memory
