# Hat's Minecraft Launcher (HMCL)

The **Hat's MC Launcher** is a program written in PowerShell script that is intended to assist with deploying custom Minecraft Mod Packs. 


## Installation

Download the most recent stable installer executable from the releases page and run it from anywhere. [Releases](https://github.com/TylerHats/Hats-MC-Launcher/releases)

The installer will handle downloading any files and setting up directories as needed. It will also package the scripts to be executables directly on your system to increase compatibility.

*You may be prompted about the safety of the installer upon launching it, you may ignore this warning. It is only due to the lack of a code signature since those would be a significant expense for a simple program like this. If this concerns you, please feel free to compile the installer script with PS2EXE on your own system.*

## Launcher Use

***In Development***
Launching the **HMCL** will display a GUI where you may select your desired options. The launcher is intended to assist with the setup of mod packs and troubleshooting common issues.

## Custom Mod Packs

***In Development***
By default, the **HMCL** will have support for any Hat's MC or contracted server mod packs. In the *Custom Mod Packs* menu, you can add or remove support for any HMCL formatted mod pack via a URL or local file path.

## HMCL Mod Pack Format

***In Development***
A custom mod pack can be created manually or with the assistance of the **HMCL** in the *Custom Mod Packs* menu. A custom mod pack is comprised of a specific folder structure with some special information stored in plain text all in a ZIP file. 

**The structure is as follows:**
ModPackName.zip*/
Configs/ *Minecraft config files and config subdirectories*
Mods/ *Minecraft mods files*
Resources/ *Resource packs (Must be ZIP files)*
ModLoader.jar *Forge and NeoForge installers have been verified to work*
HMCL.txt

**The HMCL.txt file format is as follows:**

$ModPackName = "NAME"
$ModPackVersion = "v2.5" *# Optional*
$MinRAM = "8" *# Minimum system RAM to run the mod pack in GB*
$MaxRAM = "12" *# Max RAM to assign to mod pack in GB*
$ModLoaderVersion = "" *# Must be the full version name as displayed in the official Minecraft launcher*
$JavaVersion = "17" *# May be 8, 11, or 19 (Generally for MC <=1.12.2 use Java 8, for >1.12.2 & <1.16 use Java 11, for >=1.16 use Java 17)*