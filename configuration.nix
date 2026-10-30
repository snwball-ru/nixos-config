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

    tempora = pkgs.stdenv.mkDerivation {
    pname = "tempora";
    version = "1.5.0-beta";

    src = pkgs.fetchzip {
      url = "https://github.com/teamkongehund/Tempora/releases/download/v1.5.0-beta/Tempora-v1.5.0-beta-Linux.zip";
      hash = "sha256-F7YBMrtyHelSw51GlOv4cC76m4A1Q+00AhUCYkMAlLY=";
      stripRoot = false;
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib fontconfig zlib openssl krb5 icu
    ];

    runtimeDependencies = with pkgs; [
      xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXinerama
      xorg.libXrandr xorg.libXext xorg.libXrender
      libGL libxkbcommon alsa-lib libpulseaudio udev vulkan-loader dbus
      openssl icu
    ];

    installPhase = ''
      mkdir -p $out/share/tempora $out/bin
      cp -r Tempora-Linux data_Tempora_linuxbsd_x86_64 $out/share/tempora/
      chmod +x $out/share/tempora/Tempora-Linux
      rm -f $out/share/tempora/data_Tempora_linuxbsd_x86_64/libcoreclrtraceptprovider.so
      makeWrapper $out/share/tempora/Tempora-Linux $out/bin/tempora \
    --set DOTNET_SYSTEM_GLOBALIZATION_INVARIANT 1 \
    --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.icu pkgs.fontconfig pkgs.dbus ]}
    '';
  };
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

  networking.hostName = "snwball-laptop";

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

# Keyboard

   services.udev.extraRules = ''
  KERNEL=="hidraw*", ATTRS{idVendor}=="3151", ATTRS{idProduct}=="5029", GROUP="users", MODE="0660"
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8089", MODE="0666"
  SUBSYSTEM=="usb", ATTRS{idVendor}=="8089", MODE="0666"
'';

  services.udisks2.enable = true;

# Android camera over USB

boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
boot.kernelModules = [ "v4l2loopback" ];
boot.extraModprobeConfig = ''
  options v4l2loopback devices=2 video_nr=1,10 card_label="OBS Virtual Camera,Phone Camera" exclusive_caps=1,1
'';

security.polkit.enable = true;

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

environment.sessionVariables.TERMCMD = "alacritty -e";

xdg.portal = {
  enable = true;
  extraPortals = [
    pkgs.xdg-desktop-portal-termfilechooser
    pkgs.xdg-desktop-portal-gtk
    pkgs.xdg-desktop-portal-gnome
  ];
  config.niri = {
    default = [ "gnome" "gtk" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
  };
};

# makes cli file picker work
environment.etc."xdg/xdg-desktop-portal-termfilechooser/config".text = ''
  [filechooser]
  cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
  default_dir=$HOME
'';

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

  programs.bash.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
      configure = {
    packages.myPlugins.start = [ pkgs.vimPlugins.gruvbox-nvim ];
    customRC = ''
      set termguicolors
      set background=dark
      colorscheme gruvbox
    '';
    };
  };

  programs.obs-studio = {
  enable = true;
  # plugins = with pkgs.obs-studio-plugins; [
  # ];
};

services.zerotierone = {
  enable = true;
  joinNetworks = [ "b9a18a606f017a4b" ];
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
    yt-dlp
    qbittorrent
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
    chromium # for testing and keyboard mappping
    libreoffice
    sioyek # pdf viewer
    tempora # osu timing instrument
    scrcpy # android camera
    android-tools # android debugging
    krita # image editing
    openvpn3
    (pkgs.writeShellScriptBin "nrs" ''
    set -e
    cd /etc/nixos/
    sudo nixos-rebuild switch
    git add -A
    git commit -m "rebuild $(date -Iseconds)" || true
    git push
  '') # Git version control
];

# for minecraft shaders
programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [
  stdenv.cc.cc.lib
  # --- Graphics Drivers & OpenGL ---
  libGL
  libglvnd
  mesa
  # --- Windowing & Input (X11/Wayland dependencies for GLFW) ---
  xorg.libX11
  xorg.libXext
  xorg.libXcursor
  xorg.libXrandr
  xorg.libXi
  glfw
  # --- Audio & System Integrations ---
  openal
  udev
  vulkan-loader
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
