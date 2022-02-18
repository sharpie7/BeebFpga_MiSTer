# BeebFpga_MiSTer

An experiment in building a BBC Micro MiSTer core by using the [official core](https://github.com/MiSTer-devel/BBCMicro_MiSTer) harness with the [BeebFPGA](https://github.com/hoglet67/BeebFpga) emulation. The BeebFPGA is actively maintained and incorporates a range of improvements to the emulation over the official Mister Core.

## Filing Systems

### MMFS v1

The default filing system is [MMFS v1](https://github.com/hoglet67/MMFS). 

MMFSv1 uses files in “MMB” format. This was a format originally developed for a BBC Micro add-on that connects SD cards to the user port and makes it look like a virtual set of disk-drives. The MMB file is a bundle of hundreds of BBC floppy disk images. Using commands on the BBC Micro you can choose to mount the images from the file into virtual drives.

The BBC core offers two ways to mount the MMB file. If you have a secondary SD card then format as FAT32 or FAT16. Copy the MMB file as “BEEB.MMB” on to the card. The core will automatically pick up that card. In this mode the file can be both read and written.

The alternative copy the MMB file to the “games/BBC Micro” directory on the main SD Card. If it is renamed “boot.vhd” then it will be automatically loaded. If not then you can manually load it from the MISTer menu. In this mode the file is **read only**. To unmount a previously mounted MMB/VHD (e.g. to go back to the secondary card) press backspace when picking the file.

```
Some useful MMFS Commands:
 *DCAT [start #] [end #]   - List disks in the MMB file
 *DIN [Drive #] <Disk #>   - Mount disk in the specified drive (default 0)
 ```

### MMFS v2

An alternative filing system of [MMFS v2](https://github.com/hoglet67/MMFS) may be selected from the MISTer menu. In MMFSv2 you can access SSD disk files on a FAT 32 formatted SD card in the secondary slot. Alternatively, you can pick an a file which is disk image (IMG) on the primary SD card and read SSD files from that.


## Music 5000

The Music 5000 is an add-on for the BBC Micro supporting wave-table synthesis. At the time it was fairly rare though it had a cult following. It was an external box that connected to the BBC over the "1MHz Bus" port. Retrospectively it's had a second life though emulation and modern reconstruction of the hardware.

This emulation includes the Music 5000 hardware. To you use it you will need a ROM and suitable boot disk. (The original ROMs had a copy protection system that also needs to be patched out in the emulation).

I used the "Music 5000 System Disk" from [Colin Fraser's site](http://www.colinfraser.com/m5000/m5000.htm). His page contains instructions to use on a Master 128 (you may need to use `*OPT 4,3` to enable the shift-boot. If you are using via MMFS you will need to manually reselect the disk and reset again once the ROMs are loaded). 

To use on a BBC Micro you need to:
- Load the "Ample" ROM `R.AMPLE` into a sideways ROM slot
- Load the Ample Help File ROM `ANHF` into a sideways ROM slot
- Start the "Runner" file: `*EXEC runner`
- This should start the AMPLE environment. From the menu you can load an example, e.g. `concert`

There is also a lot of Music 5000 information and software on the [Retro-Kit](https://www.retro-kit.co.uk/Hybrid-Music-System/) site.

Aside: Back in the day I did have a Music 500 (essentially the same hardware as Music 5000). I could never get anything out of it that I thought sounded good and rapidly gave up trying. I am afraid all the demos I've heard now for Music 5000 don't improve my assessment! It always struck me as odd that what was at the time a pretty advanced system was still so "bleepy".


## Known Bugs and Limitations

- Only HDMI output has been tested. VGA may not be good (or working at all!)
- Mode 7 characters don't look nice
- Sound mixing between the Music 5000 output and the BBC sound isn't good. Don't play both at once.
