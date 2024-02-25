{
  benaryorg.deployment.fake = true;

  benaryorg.build.role = "none";
  benaryorg.prometheus.client.enable = true;
  benaryorg.prometheus.client.exporters.node.enable = true;
  benaryorg.prometheus.client.exporters.smokeping.enable = false;
  benaryorg.prometheus.client.exporters.systemd.enable = false;
  benaryorg.prometheus.client.mocks.bgplgd =
  {
    port = 443;
  };
}
