# Zooz Remote Button / Switch

### Supported Models:
ZEN34, ZEN37

## Version History

#### v2025-09-26
* WWST compliance
    * Replaced platemusic11009.firmware with firmwareUpdate
    * Removed custom association group capabilities (kept settings)
    * Removed custom device-config (not needed)
* Merged in ZEN37 and created sub-drivers for both devices where needed

#### v2023-10-22.1
* added old fingerprint

#### v2023-10-20.1
* added profile for 1.40 firmware for param #5

#### v2023-01-01.1
* added support for association groups 2 & 3 
* removed sync status capability
* replaced code with the generic code from the Multisensor driver and then added ZEN34 specific code and tests to it

#### v2021-12-28.1
* Initial release