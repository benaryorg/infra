{
  services.btrbk =
  {
    ioSchedulingClass = "idle";
    sshAccess =
    [
      {
        # gnutoo (manually generated)
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIADAZYjYaBLKe26iN+XH2OKKHjaTPFo/oNexiAi2w/tK";
        roles = [ "source" "info" "send" ];
      }
    ];
    instances.btrbk =
    {
      onCalendar = "hourly";
      settings =
      {
        timestamp_format = "long-iso";
        stream_buffer = "256m";
        snapshot_dir = ".snapshot";
        snapshot_create = "always";
        incremental = "yes";
        preserve_hour_of_day = "0";
        preserve_day_of_week = "sunday";
        snapshot_preserve_min = "latest";
        snapshot_preserve = "25h 32d 6w *m";
        target_preserve_min = "latest";
        target_preserve = "25h 32d 6w *m";
        volume =
        {
          "/" =
          {
            incremental = "strict";
            subvolume =
            {
              "." = { snapshot_name = "@"; };
              "./home" = { snapshot_name = "@home"; };
            };
          };
        };
      };
    };
  };
}
