# Quark

A trimmed down (under 150MB) version of the TrimUI Smart's stock operating system with extra goodies, great for small SD cards!  
Installation is as simple as extracting the [latest release](https://github.com/cobaltgit/Quark/releases/latest) into the root of a microSD card formatted with the FAT32 filesystem.

* Many more systems to choose from than the stock base package, including home computers and ports
* RetroArch cores updated to their latest versions from source
* CPU profiles configured for best performance/battery life balance
* Overlays for handheld systems

## Hotkeys

## Global

* SELECT + L/R: Volume control
* START + L/R: Brightness control
* MENU + L/R: L2/R2 (enable in Settings)

## RetroArch

* SELECT + L: slow-motion
* SELECT + R: fast-forward
* SELECT + B: exit to MainUI
* SELECT + A: take screenshot (saves in `Saves/screenshots`)
* SELECT + Y: toggle frame rate display
* SELECT + X: open RA menu
* SELECT + D-Pad Right: save state in current slot
* SELECT + D-Pad Left: load state in current slot

## Supported Systems

Below is a list of systems that Quark supports, along with the emulator core they use by default:

* Commodore Amiga (UAE4ARM)
* Arcade (FB Alpha 2012 / MAME 2003 Plus)
* Atari 8-bit computers (Atari800)
* Atari 2600 (Stella 2014)
* Atari 5200 (A5200)
* Atari 7800 (ProSystem)
* Atari ST (Hatari)
* Commodore 64 (VICE x64)
* ColecoVision (blueMSX)
* Amstrad CPC (Caprice32)
* CP System I/II/III (FB Alpha 2012)
* Doom (PrBoom)
* MS-DOS (DOSBox Pure)
* EasyRPG
* Nintendo Entertainment System (FCEUmm)
* Nintendo Family Computer Disk System (FCEUmm)
* Nintendo Game Boy / Game Boy Color (Gambatte)
* Nintendo Game Boy Advance (gpSP)
* Sega Game Gear (PicoDrive)
* MADrigal's Simulators (GW)
* Intellivision (FreeIntv)
* Atari Lynx (Handy)
* Sega Mega Drive (PicoDrive)
* Sega Master System (PicoDrive)
* MSX / MSX2 (blueMSX)
* Neo Geo (FB Alpha 2012)
* Neo Geo CD (NeoCD)
* Neo Geo Pocket / Neo Geo Pocket Color (RACE)
* OpenBOR (standalone emulator)
* NEC PC Engine (Beetle SuperGrafx)
* NEC PC Engine CD-ROM (Beetle SuperGrafx)
* IGS PolyGame Master (FB Alpha 2012)
* Pico-8 (FAKE-08)
* Pokémon Mini (PokeMini)
* [Ported games](https://github.com/cobaltgit/Quark-Ports)
* Sony PlayStation (PCSX-ReARMed)
* Quake (TyrQuake)
* Sega 32X (PicoDrive)
* Sega Mega CD (PicoDrive / Genesis Plus GX)
* Super Nintendo Entertainment System (Snes9x 2005 Plus)
* Sega SG-1000 / SC-3000 (PicoDrive)
* NEC PC Engine SuperGrafx (Beetle SuperGrafx)
* Wolfenstein 3D (ECWolf)
* Bandai WonderSwan / WonderSwan Color (Beetle Cygne)
* Sharp X68000 (PX68K)
* Sinclair ZX Spectrum (FUSE)

## Known Issues

* Sega CD games have no CD audio playback when using `.chd` format games using the PicoDrive core. Launcher works around this by changing to the Genesis Plus GX core if needed.
* PSX cannot save states (crashes with segmentation fault)
* FPS display not showing when an overlay is applied

## Licence

This project is licenced under [CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en), however, the Dingux Commander application is licenced under the [GNU General Public License, version 2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html) (a zip file containing the source code is bundled)

## Credits

* **[spruce](https://github.com/spruceUI) team:** centralised emulator launch, smart CPU governor logic, emu icons and inspiration
* **Jutleys:** Dingux Commander from [Tomato](https://github.com/Jutleys/Trimui-Smart-Tomato)
* **[chrizzo-hb](https://github.com/chrizzo-hb/knulli-bezels):** overlays/bezels for handheld systems