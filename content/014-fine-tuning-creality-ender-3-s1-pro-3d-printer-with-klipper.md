---
title: Fine-tuning a Creality Ender-3 S1 Pro 3D printer with Klipper, part 1
published: "2023-03-22T09:55:03-06"
preview: Shortcuts for optimizing prints on a Creality Ender-3 S1 Pro 3D printer with Klipper
description: All the various hardships I went through to install Klipper and optimize print settings for a Creality Ender-3 S1 Pro 3D Printer
slug: fine-tuning-creality-ender-3-s1-pro-3d-printer-with-klipper-part-1
---

Not my usual K8s or Elixir post, but I recently bought a [Creality Ender-3 S1 Pro](https://www.creality.com/products/creality-ender-3-s1-pro-fdm-3d-printer). I had quite a challenging time flashing [Kilpper](https://www.klipper3d.org) and printing a high-quality base layer, and I wanted to share my experience to save other folks some time.

Watching YouTube or reading sites like All3DP, you are going to see a ton of things to tweak or optimize: ringing, pressure advance, extrusion rates, temperature (towers), etc. All of those are interesting, but none more important than starting with a level bed. I recommend waiting to optimize most things until you can print a base layer that makes you happy.

# Disclaimer

I'm using about $40 worth of upgrades to the printer. You can likely use these tips without the upgrades here, but these made my life a lot easier.

- [Glass Printer Bed](https://www.amazon.com/gp/product/B07JKGNB6W) - $12.99
- [Layerneer BED WELD](https://www.amazon.com/gp/product/B079984GV5) - $20.69
- [7mm bed clips](https://www.amazon.com/dp/B08PZKGJTR) - $7.99

The bed clips _really_ should come with a glass bed, rather than the normally included binder clips. I solved a lot of bed leveling problems when I put sturdier bed clips in place.

# Before flashing Klipper

The first thing to do is find a valid printer configuration file. The Klipper project already has one for this printer [located in Github](https://github.com/Klipper3d/klipper/blob/master/config/printer-creality-ender3-s1-2021.cfg).

I also had to figure out which ARM chip was in the S1 Pro mainboard. There are apparently two revisions being sold right now, and no material I found said which was which. However, it's as easy as removing the back cover of the printer and taking a picture of the mainboard. The mainboard chip should say either `STM32F401` OR `STM32F103`. The top of the configuration file indicates which settings to use with which chip.

# Flashing Klipper firmware

I'm fortunate to have some Raspberry Pi 3 Model B+ and Model 4 boards lying around, so I dedicated one to running [MainsailOS](https://docs.mainsail.xyz) with Klipper. This provides a much nicer, web-based interface than the touchscreen pad provided with the printer. Sitting in another room running the printer on my phone is pretty neat. In fact, I removed the touchscreen pad from the main board and printer.

However, flashing the Klipper firmware took some effort.

For the most part, I just followed the [instructions in the Klipper documentation](https://www.klipper3d.org/Installation.html). I stopped when I got to "Configuring OctoPrint to use Klipper".

One key difference is that the Ender 3 S1 Pro [**cannot** be flashed via USB](https://www.klipper3d.org/Installation.html#building-and-flashing-the-micro-controller). It requires the use of a [8GB or 16GB SDHC card](https://www.amazon.com/dp/B000WJ725U), formatted to FAT32. I used a cheap USB SD Card reader to format the card to FAT32 on my Windows machine and then plugged it directly into my Pi to compile and move the firmware around.

When mounting the SD Card, I used the following command.

```bash
sudo mount -o rw,gid=1000,uid=1000 -t vfat /dev/sdb1 /home/pi/mnt
```

That allowed the `pi` user to manage the folders and files on the card.

The other key I discovered is that the firmware filename needs to be unique. After I compiled the firmware, I renamed it when moving to the card.

```bash
cp ~/klipper/out/klipper.bin ~/mnt/firmware-v0.11.0-148-g52f4e20c.bin
```

The version string is just output after compiling Klipper. Everytime I reflash a new Klipper version, I delete the old file and create a new one with a name based on Klipper's version.

Once the firmware is on the card:

1. Turn off the printer and disconnect it from the Pi.
1. Insert the card, turn the printer on, and wait 60 seconds.
1. Turn the printer off, remove the card, attach the printer to the Pi and turn it back on.

If everything worked, it should appear as the MCU in the MainsailOS interface!

![MainsailOS machine tab](/images/014-mainsail-mcu-host.png)

In the next post, I'll go through how I created a reasonably level bed mesh with a range of 0.092mm and set a quite good Z-offset for the first layer!
