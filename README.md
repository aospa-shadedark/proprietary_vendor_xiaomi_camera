# proprietary_vendor_xiaomi_camera

Prebuilt stock MIUI Camera to include in custom ROM builds.

### Supported devices
* POCO F5 / Redmi Note 12 Turbo (Marble)

### How to use?

1. Clone this repo to `vendor/xiaomi/camera`

2. Inherit it from `device.mk` in device tree:

```
# Camera
$(call inherit-product-if-exists, vendor/xiaomi/camera/miuicamera.mk)
```

3. Set `ro.product.mod_device` according to stock, and `ro.miui.notch=1` if the device has a display cutout, for example:

```
PRODUCT_SYSTEM_PROPERTIES += \
    ro.miui.notch=1 \
    ro.product.mod_device=lisa
```

### Environment Setup & Apktool Support

The extraction process requires apktool for dynamic patching of the MiuiCamera binary.
If you are operating on a server without sudo access, follow these steps:

1. Ensure the `bin` directory exists in your home:

```bash
mkdir -p ~/bin
```

2. Download both files directly into that bin folder:

```bash
curl -sLo ~/bin/apktool https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool
curl -sLo ~/bin/apktool.jar https://github.com/iBotPeaches/Apktool/releases/download/v2.10.0/apktool_2.10.0.jar
```

3. Make them executable:

```bash
chmod +x ~/bin/apktool ~/bin/apktool.jar
```

4. Run the extraction script by prefixing PATH to ensure your local apktool is used:

```bash
PATH="$HOME/bin:$PATH" ./extract-files.sh <path-to-blobs>
```