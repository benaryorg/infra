{
  services.btrbk =
  {
    ioSchedulingClass = "idle";
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
        ssh_user = "btrbk";
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
          "ssh://mir.home.bsocat.net/" =
          {
            backend_remote = "btrfs-progs-sudo";
            subvolume =
            {
              "." =
              {
                snapshot_name = "@";
                snapshot_create = "no";
                target = "/.snapshot/remote/mir.home.bsocat.net/";
              };
              "./home" =
              {
                snapshot_name = "@home";
                snapshot_create = "no";
                target = "/.snapshot/remote/mir.home.bsocat.net/";
              };
            };
          };
        };
      };
    };
  };
}
