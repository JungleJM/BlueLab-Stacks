# Initial Project Goals


## Background
Look at the github repo for Bluelab (https://github.com/JungleJM/BlueLab) specifically the latest in the first-boot branch, and the readme, and the docs folders. This will give you a sense of what we are trying to achieve. We are trying to do phase 2 and up in a separate repo while Phase 1 is being ironed out of bugs. 

Then, look at phase 2 in this docs folder, to try and understand what we are trying to do. 

## Audience
I'm imaginging two aaudiences for this repo. 
1) the BlueLab user whose bluelab has automatically downloaded thsi repo and is using it to continuie the BlueLab installation. 
2) The Linux user who doesn't want to install an entire OS of BlueLab, but use their current Linux distro (which can be any distro, ubuntu, fedora, debian, etc). They want to get the stacks, as they aren't experts in docker, and mayabe don't even have it installed on their computer. 

We should develop code such that our installer checks which version the user is. If it's an automatic install from bluefin, have some sort of iron-clad way of checking that. Maybe the installer checks some file that's unique to BlueLab, for instance. If that isn't there, then we assume it is a non-bluelab user and we check what Linux distro they're using, and tailor install codes to them as much as possible (like using 'apt' instead of 'dnf' as needed). We should also pay special attention to users of immutable distros like Fedora Silverblue, and find a way to do installs such that it doesn't cause conflicts with those distros' philosophy.

**Core to this product is the idea of the non-familiar user.** the product should require as few steps as possible for the user to do, and everything should "just work," and info should be readily available exactly where they would need it. The audience member is a non-linux user, maybe coming from windows/mac, maybe just mostly on an iPad or phone - and they should feel like this is intuitive and easy, rather than having to go through lots of setup.

## Software to install

There should be an initial installer, which asks for core info, such as 
-   username/passwords for apps, 
-   A Tailscale Integration so that the user can click a button and open up a browser, set up/log into tailscale, and then it authorizes automatically and gets the tailscale-specific IP address for making bookmarks later.
-   A Wireguard Config - allows the user to simply download a wireguard config file from their VPN, so that if they don't have one already they can get it set up without having to put in annoying private and public keys. If they want a suggested free one, Suggest Proton VPN, and provide a link and maybe API integration, or download the wireguard config automatically.
-   A "Steam Gaming" option that downloads Steam, maybe also an API integration so it auto-logs in. 
-   A list of all the stacks below, with some info of what they have/do. It should note that the "core" stacks will be installed either way, but the others are optional to install as they'd like.

Ideally this will be a slick interface based in somethign simple like Electron, but for now also fine to run in a bash/terminal interface so long as the authentication communication back to the terminal works once the website logins/permissions are done. 

## SHould I distrobox this?
I'm thinking for ease of installation I can make this all in a distrobox so that I won't have to worry about compatibiliity issues. I will also be able to easily un-install. Give me pros and cons for doign that vs installing on the main OS.


## Stacks
The core of this product is auto-installing a set of stacks, whose apps/programs work together for a specific purpose. For instance, the 'media' stack should have jellyfin, sonarr, radarr, prowlarr, bazarr, qbittorrent. In general, we shoudl automate any installation functions as much as possible (for instance, the media stack's programs should all share API keys and not require the user to go through and set that up). 

There will be some "core" stacks that are essential for the product to work, and other "optional" stacks that can be installed as needed. 

Core stacks:
**Dockge** - The basic interface to see all the stacks and see if they're working. All other stacks should be isntalled such that they're viewable in dockge and can be seen on its interface.
**Monitoring** - This is where we do update monitoring, Ansible cron jobs for any tasks, and where we host Homepage, the interface that will be the central hub for all the data, that is the one-stop shop to access all of our stuff
**Media** - Jellyfin, QBittorrent, Sonarr, Radarr, Bazarr, Prowlarr, Filebot
    - If selected, Also isntall the app Jellyfin media Player, and auto-connect to the server. Make it also put that in the dock if it's GNOME-based, and the bottom bar if KDE-based.
    - If selected, place info about FileBot being a paid service but optional - only if you have lots of files you want to bring in, as it's likely in a naming format that Jellyfin won't be able to read


## Uninstaller 

The program should take note of what is installed in the system already, when it first loads up (does the user already have steam, docker, watchtower, etc.?) and then create a simple uninstall script to remove everything so that it gets back to that previous state. This is mostly for me to work through bugs throughout the dev process without having to manually install/uninstall each time. But it's also useful for the user to be able to remove things. If using distrobox this should be a fairly simple task, but it should prompt the user if they want to keep or delete user data directories (and say what specifically you'd be keeping vs. deleting)