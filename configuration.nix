# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:


let
	unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
	zen-browser = import (builtins.fetchTarball "https://github.com/0xc000022070/zen-browser-flake/archive/main.tar.gz") {};
	noctaliaGreeterSrc = builtins.fetchTarball {
    url = "https://github.com/noctalia-dev/noctalia-greeter/archive/85ea4863e363973254e091bc82a3c39cb73af3c1.tar.gz";
    sha256 = "0gl4kc9innm095j48ha8lf9y57z2q88n6x27154yy05x3pilri4a";
  };

  noctaliaGreeter = pkgs.callPackage
    "${noctaliaGreeterSrc}/nix/package.nix"
    { };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
	"${noctaliaGreeterSrc}/nix/nixos-module.nix"
    ];

  #Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.resumeDevice = "/dev/disk/by-uuid/d9e4400c-e55e-49e2-98bb-ef5528caf429";

  swapDevices = [
    { device = "/dev/disk/by-uuid/d9e4400c-e55e-49e2-98bb-ef5528caf429"; }
  ];

  nix.gc = { automatic = true; dates = "weekly"; };
  nix.settings.auto-optimise-store = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Lenovo XiaoXin 14 Pro AHP9 sleep reboot fix

  systemd.sleep.settings.Sleep.HibernateMode = "shutdown";

  services.logind.settings.Login = {
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
    HandleLidSwitchDocked = "hibernate";
  };
 
# Hardware

  hardware.opentabletdriver.enable = true;
  services.upower.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam and most games need this
  };

hardware.amdgpu.opencl.enable = true;
hardware.firmware = [ pkgs.sof-firmware ];
hardware.enableRedistributableFirmware = true;

services.lact.enable = true;

# Network

  networking.hostName = "snwball-laptop"; # Define your hostname.
  
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.bluetooth = {
	enable = true;
	powerOnBoot = true;
  };
  
  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  i18n.inputMethod = {
  enable = true;
  type = "ibus";
};

  services.udisks2.enable = true;

# Sound
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;
 
  programs.niri.enable = true;

services.power-profiles-daemon.enable = true;
 services.displayManager.noctalia-greeter = {
  enable = true;
  package = noctaliaGreeter;

  settings = {
    keyboard.layout = "us";

    cursor = {
      theme = "Bibata-Modern-Ice";
      size = 24;
    };
  };

  cursorTheme.package = pkgs.bibata-cursors;
};
  
services.xserver.xkb = {
  layout = "us,ru";
  options = "grp:alt_shift_toggle";
};

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.niri = {
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    };
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    liberation_ttf
    carlito
    caladea
    corefonts
    vista-fonts
    inter
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  # makes Electron apps run on Wayland

# Programs

  services.gvfs.enable = true; # for android device mounting

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };

  programs.gamemode.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.throne = {
	enable = true;
	tunMode.enable = true;
  };

# Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."snwball" = {
    isNormalUser = true;
    description = "snwball";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "git" ];
    packages = with pkgs; [
    
    ];
  };

  nixpkgs.config.allowUnfree = true;

environment.systemPackages = with pkgs; [
    unstable.noctalia-shell # shell, most important
    obsidian
    davinci-resolve
    telegram-desktop
    figma-linux
    audacity
    obs-studio
    yt-dlp
    qbittorrent
    zathura # pdf viewer
    exiftool
    mpv # media viewer
    yazi # CLI file manager
    imv # image viewer
    xdg-desktop-portal # already pulled in by xdg.portal.enable above; kept explicit since you listed it
    cliphist # clipboard
    grim
    slurp
    p7zip # archiving
    texlive.combined.scheme-medium # bump to scheme-full if you hit missing-package errors often
    bibata-cursors   # cursor theme referenced by the greeter config above
    xwayland-satellite # xorg and wayland compatibility
    alacritty # terminal
    nautilus # GUI file manager
    zen-browser.default # web browser
    osu-lazer-bin 
    adwaita-icon-theme # noctalia-shell icons
    hmcl # minecraft launcher
    vesktop # vencord fork
    udiskie # auto mounting disks
    jdk8 # older java for minecraft
    flacon # .cue splitting
    shotcut # fast video editing (ffmpeg ultra compatible or sth)
    git
   ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
   programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
