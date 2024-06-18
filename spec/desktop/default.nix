{ config, pkgs, lib, ... }:
{
  options =
  {
    benaryorg.desktop =
    {
      enable = lib.mkEnableOption "desktop environment";
      defaultUser = lib.mkOption
      {
        description =
        ''
          Default user to deploy the desktop environment for.

          ::: {.note}
          The module can still be used by additional users.
          See {option}`benaryorg.home-manager.perUserSettings` for usage information.
          :::
        '';
        type = lib.types.str;
        default = config.benaryorg.user.ssh.name;
        defaultText = lib.literalExpression "config.benaryorg.user.ssh.name";
      };
    };
  };

  config =
    let
      cfg = config.benaryorg.desktop;
    in
      lib.mkMerge
      [
        {
          benaryorg.home-manager.perUserSettings.${cfg.defaultUser}.benaryorg.desktop.enable = lib.mkDefault cfg.enable;
          home-manager.sharedModules = lib.mkAfter
          [
            ({ lib, pkgs, config, ... }:
            {
              options =
              {
                benaryorg.desktop =
                {
                  enable = lib.mkEnableOption "desktop";
                  powerSaving = lib.mkEnableOption "X11 power saving options";
                  keyboardLayout = lib.mkOption
                  {
                    default = "de neo";
                    type = lib.types.str;
                    description =
                    ''
                      Keyboard layout to set.
                      This is passed to `setxkbmap` verbatim.
                    '';
                  };
                  xdgDesktop = lib.mkOption
                  {
                    default = "gnome";
                    type = lib.types.str;
                    description =
                    ''
                      Set {env}`XDG_CURRENT_DESKTOP` to a value appropriate for your system.
                    '';
                  };
                  extraInitCommands = lib.mkOption
                  {
                    default = "";
                    type = lib.types.listOf lib.types.str;
                    description =
                    ''
                      Additional commands run before your desktop environment starts (i.e. in your {file}`.xinitrc`).
                    '';
                  };
                  desktopCommand = lib.mkOption
                  {
                    default =
                    ''
                      ulimit -v unlimited && exec awesome
                    '';
                    type = lib.types.str;
                    description =
                    ''
                      The command to start your desktop environment or window manager.
                    '';
                  };
                  tty = lib.mkOption
                  {
                    default = 2;
                    type = lib.types.numbers.between 1 12;
                    description =
                    ''
                      Which TTY should trigger the graphical login.
                    '';
                  };
                  awesome =
                  {
                    enablePatchage = lib.mkEnableOption "*patchage* support in *awesome*";
                  };
                };
              };
              config = let cfg = config.benaryorg.desktop; in lib.mkIf cfg.enable
              {
                home.packages = with pkgs;
                [
                  # basic desktop
                  awesome gnome.gnome-themes-extra
                  # communication
                  firefox mumble thunderbird transmission_4-gtk
                  (gajim.overrideAttrs (self: { nativeBuildInputs = self.nativeBuildInputs ++ [ gsound ]; })) # gajim needs gsound for sound
                  # utilities
                  ahoviewer xpra xdg-utils yt-dlp vlc syncplay mpv ffmpeg inkscape krita feh qpdfview
                  # graphics
                  vulkan-tools mesa-demos
                  # coding
                  deadnix statix
                  cargo cargo-outdated
                  # xorg utilities
                  xsel xorg.xwininfo xorg.xset xorg.xrandr xorg.xprop xorg.xkill xorg.xinput xorg.xhost xorg.xev xorg.xauth xorg.setxkbmap
                  # sandboxing utilities
                  bubblewrap
                ];

                programs.alacritty =
                {
                  enable = true;
                  settings =
                  {
                    colors =
                    {
                      draw_bold_text_with_bright_colors = true;
                      normal.black = "#000000";
                      primary.background = "#000000";
                    };
                    font =
                    {
                      size = 10;
                      normal = { family = "monospace"; };
                    };
                    scrolling.history = 0;
                    keyboard.bindings =
                    [
                      { mode = "~Vi"; key = "V"; mods = "Control|Shift"; action = "Paste"; }
                      { mode = "~Vi"; key = "C"; mods = "Control|Shift"; action = "Copy"; }
                    ];
                  };
                };
                programs.mpv =
                {
                  enable = true;
                  config =
                  {
                    volume = 30;
                    ao = "pulse";
                    alang = "jpa,jpn,jp,eng,en";
                    slang = "eng,en,jpa,jpn,jp";
                    subs-with-matching-audio = true;
                    network-timeout = 4;
                    cache = true;
                    cache-secs = 600;
                    cache-on-disk = true;
                    screenshot-directory = "~/Downloads/";
                  };
                  scriptOpts =
                  {
                    osc =
                    {
                      timems = true;
                    };
                  };
                  defaultProfiles = [ "gpu-hq" ];
                  profiles.gpu-hq =
                  {
                    scale = "ewa_lanczossharp";
                    cscale = "ewa_lanczossharp";
                    video-sync = "display-vdrop";
                    interpolation = true;
                    tscale = "oversample";
                  };
                  bindings =
                    let
                      anime4k = pkgs.fetchzip
                      {
                        name = "anime4k";
                        url = "https://github.com/bloc97/Anime4K/releases/download/v4.0.1/Anime4K_v4.0.zip";
                        stripRoot = false;
                        hash = "sha256-9B6U+KEVlhUIIOrDauIN3aVUjZ/gQHjFArS4uf/BpaM=";
                      };
                    in
                      {
                        "CTRL+KP1" = ''no-osd change-list glsl-shaders set "${anime4k}/Anime4K_Clamp_Highlights.glsl:${anime4k}/Anime4K_Restore_CNN_VL.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A (HQ)"'';
                        "CTRL+KP2" = ''no-osd change-list glsl-shaders set "${anime4k}/Anime4K_Clamp_Highlights.glsl:${anime4k}/Anime4K_Restore_CNN_Soft_VL.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B (HQ)"'';
                        "CTRL+KP3" = ''no-osd change-list glsl-shaders set "${anime4k}/Anime4K_Clamp_Highlights.glsl:${anime4k}/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:${anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C (HQ)"'';
                        "CTRL+KP4" = ''no-osd change-list glsl-shaders set "${anime4k}/Anime4K_Clamp_Highlights.glsl:${anime4k}/Anime4K_Restore_CNN_VL.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${anime4k}/Anime4K_Restore_CNN_M.glsl:${anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A+A (HQ)"'';
                        "CTRL+KP5" = ''no-osd change-list glsl-shaders set "${anime4k}/Anime4K_Clamp_Highlights.glsl:${anime4k}/Anime4K_Restore_CNN_Soft_VL.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${anime4k}/Anime4K_Restore_CNN_Soft_M.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B+B (HQ)"'';
                        "CTRL+KP6" = ''no-osd change-list glsl-shaders set "${anime4k}/Anime4K_Clamp_Highlights.glsl:${anime4k}/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:${anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${anime4k}/Anime4K_Restore_CNN_M.glsl:${anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C+A (HQ)"'';
                        "CTRL+KP0" = ''no-osd change-list glsl-shaders clr ""; show-text "GLSL shaders cleared"'';
                        "CTRL+KP8" = ''no-osd change-list af set "lavfi=[dynaudnorm=f=75:g=25:p=0.45]"; show-text "Equalizer active"'';
                        "CTRL+KP9" = ''no-osd change-list af clr ""; show-text "Equalizer inactive"'';
                      };
                };

                home.file.".zlogin" =
                {
                  enable = true;
                  executable = true;
                  text =
                  ''
                    #! ${pkgs.zsh}

                    if
                    ${"\t"}test "$TTY" = /dev/tty${toString cfg.tty}
                    then
                    ${"\t"}exec startx -- vt${toString cfg.tty}
                    fi
                  '';
                };
                home.file.".xinitrc" =
                {
                  enable = true;
                  executable = true;
                  text =
                  ''
                    #! ${pkgs.zsh}

                    set -e

                    setxkbmap ${cfg.keyboardLayout} || true

                    ${lib.optionalString (!cfg.powerSaving) ''
                      xset -dpms || true
                      xset s noblank || true
                      xset s off || true
                    ''}

                    tmux new-session -d -s "nc" -c "$HOME" "nc -6vnklp 1337" || true
                    export XDG_CURRENT_DESKTOP=${cfg.xdgDesktop}
                    dbus-update-activation-environment --systemd DBUS_SESSION_BUS_ADDRESS DISPLAY XAUTHORITY
                    systemctl --user import-environment PATH

                    ${builtins.concatStringsSep "\n" cfg.extraInitCommands}

                    ${cfg.desktopCommand}
                  '';
                };
                xdg.configFile.awesome =
                {
                  enable = true;
                  source = pkgs.callPackage ./awesome.nix
                  {
                    inherit (cfg.awesome) enablePatchage;
                  };
                };
              };
            })
          ];
        }
        (lib.mkIf cfg.enable
        {
          fonts.enableDefaultPackages = lib.mkDefault true;
          fonts.packages = with pkgs; lib.mkAfter [ noto-fonts noto-fonts-cjk-sans noto-fonts-cjk-serif comic-mono ];
          fonts.fontconfig.defaultFonts.monospace = lib.mkDefault [ "Comic Mono" ];
          qt.style = lib.mkDefault "adwaita-dark";

          hardware.opengl.enable = lib.mkDefault true;
          hardware.opengl.driSupport = lib.mkDefault true;
          services.xserver =
          {
            enable = lib.mkDefault true;
            displayManager.startx.enable = lib.mkDefault true;
          };

          programs.firejail.enable = true;
          services.pipewire.enable = lib.mkDefault true;
        })
      ];
}
