vGPU Support
-------------

The vGPU Support is only available for NVIDIA GPUs which support GPU virtualization. If you want to check if your GPU supports virtualization you can check the official [NVIDIA Guide](https://docs.nvidia.com/grid/gpus-supported-by-vgpu.html).
Both AMD CPUs and INTEL CPUs are supported in Yaook for GPU virtualization.
To virtualize the GPU the BIOS setting VT-D/IOMMU has to be enabled.
Therefore a `enable_iommu.cfg` snippet will be automatically added in `/etc/default/grub.d`. This is useful because the grubfile is not changed and therefore presets are kept and the `*.cfg` files in `grub.d` are loaded after the grubfile. This allows us to make additional modifications in the future.

To enable the vGPU support in Yaook/k8s, the following variables must be set in the `config.toml`. The `config.template.toml` can be found [here](https://gitlab.com/yaook/k8s/-/blob/devel/templates/config.template.toml).
The vGPU Manager software can be downloaded in the [NVIDIA Licensing portal](https://ui.licensing.nvidia.com/).
```console
# vGPU Support
[nvidia.vgpu]
driver_blob_url =   # vGPU manager storage location
manager_filename =  # vGPU manager
```



After Yaook/k8s has been rolled out, the folder for the chosen configuration still has to be found. The following steps have to be done only once and are needed for Yaook [Operator](https://docs.yaook.cloud/index.html) and Openstack. 

**Note**: It is recommended to save the folder name including the configuration and GPU so that the process only needs to be performed once.

A distinction must be made between two cases.
1. NVIDIA GPU that does not support SR-IOV. (All GPUs before the Ampere architectur)

    Physical GPUs supporting virtual GPUs propose mediate device types (mdev). To see the required properties, go to the following folder.  Note: You still need to get the right PCI port, in which the GPU is plugged in.

    ```console
    $ lspci | grep NVIDIA
    82:00.0 3D controller: NVIDIA Corporation TU104GL [Tesla T4] (rev a1)
    ```

    Find the folder with your desired vGPU configuration. Replace `"vgpu-type"` with your chosen vGPU configuration.
        
    ```console
    $ grep -l "vgpu-type" nvidia-*/name
    ```

2. NVIDIA GPU that supports SR-IOV. (All GPUs of the Ampere architecture or newer)

    Obtain the bus, domain, slot and function of the available virtual functions on the GPU.

    ```console
    $ ls -l /sys/bus/pci/devices/domain\:bus\:slot.function/ | grep virtfn
    ```       

    This example shows the output of this command for a physical GPU with the slot 00, bus 82, domain 0000 and function 0.

    ```console
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
    ``` 

    Choose the virtual function on which you want to create the vGPU.
    Change to the `mdev_supported_types` directory on which you want to create the vGPU and find the subdirectory, that contains your chosen vGPU configuration. Replace `vgpu-type` with your chosen vGPU configuration.

    ```console
    $ cd /sys/class/mdev_bus/0000\:82\:00.4/mdev_supported_types/
    $ grep -l "vgpu-type" nvidia-*/name
    ```   
3. With the subdirectory name information you can proceed with the Yaook [Operator](https://docs.yaook.cloud/index.html). There you can set the `enable_vgpu_types` in the `nova.yaml`. The file is located under `operator//docs/examples/nova.yaml`.

    ```console
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
    ```


           

