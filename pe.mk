$(call inherit-product, vendor/aosp/config/common_full_phone.mk)
$(call inherit-product, vendor/aosp/config/BoardConfigSoong.mk)
$(call inherit-product, device/custom/sepolicy/common/sepolicy.mk)
-include vendor/aosp/build/core/config.mk
TARGET_BOOT_ANIMATION_RES := 1080

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.system.ota.json_url=https://raw.githubusercontent.com/thefiredragon/treble_build_pe/twelve/ota.json

TARGET_SUPPORTS_QUICK_TAP := true

PRODUCT_PACKAGES += \
    libaptX_encoder \
    libaptXHD_encoder \
    NowPlayingOverlay