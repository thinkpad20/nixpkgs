{ config, pkgs, ...}:

let
  bootScript = pkgs.writeScript "bootscript.sh" ''
    #!${pkgs.stdenv.shell} -eux

    export PATH=${pkgs.nix}/bin:${pkgs.curl}/bin:${pkgs.systemd}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${config.system.build.nixos-rebuild}/bin:$PATH
    export NIX_PATH=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix

    while ! curl -s --max-time 5 169.254.169.254 > /dev/null; do
      sleep 5
    done

    echo "Success"

    curl -s http://169.254.169.254/2011-01-01/user-data > /etc/nixos/amazon-init.nix

    grep '^###' /etc/nixos/amazon-init.nix | sed 's|###\s*||' > /root/.nix-channels

    nix-channel --update

    nixos-rebuild switch

    echo "All done"
  '';
in {
  imports = [ ./amazon-base-config.nix ];
  ec2.hvm = true;
  ec2.metadata = true;

  boot.postBootCommands = ''
    ${bootScript} 2> /root/boot.err > /root/boot.log &
  '';
}

