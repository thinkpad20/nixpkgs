{ stdenv, fetchurl, pkgconfig, dbus, libnih, python, makeWrapper, utillinux
, writeScript }:

let
  inherit (stdenv.lib) makeBinPath;
  version = "1.5";

  upstart = stdenv.mkDerivation rec {
  name = "upstart-${version}";

  src = fetchurl {
    url = "http://upstart.ubuntu.com/download/${version}/${name}.tar.gz";
    sha256 = "01w4ab6nlisz5blb0an1sxjkndwikr7sjp0cmz4lg00g3n7gahmx";
  };

  buildInputs = [ pkgconfig dbus libnih python makeWrapper];

  NIX_CFLAGS_COMPILE =
    ''
      -DSHELL="${stdenv.shell}"
      -DCONFFILE="/etc/init.conf"
      -DCONFDIR="/etc/init"
      -DPATH="/no-path"
    '';

  # The interface version prevents NixOS from switching to an
  # incompatible Upstart at runtime.  (Switching across reboots is
  # fine, of course.)  It should be increased whenever Upstart changes
  # in a backwards-incompatible way.  If the interface version of two
  # Upstart builds is the same, then we can switch between them at
  # runtime; otherwise we can't and we need to reboot.
  passthru.interfaceVersion = 2;

  # Useful tool to check syntax of a config file. Upstart needs a dbus
  # session, so this script wraps one up.
  #
  # See: http://mwhiteley.com/scripts/2012/12/11/dbus-init-checkconf.html
  passthru.check-config = writeScript "upstart-check-config" ''
    #!${stdenv.shell}

    set -o errexit
    set -o nounset

    export PATH=${makeBinPath [dbus.out upstart]}:$PATH

    if [[ $# -ne 1 ]]
    then
      echo "Usage: $0 upstart-conf-file" >&2
      exit 1
    fi
    config=$1 && shift

    dbus_pid_file=$(mktemp)
    exec 4<> $dbus_pid_file

    dbus_add_file=$(mktemp)
    exec 6<> $dbus_add_file

    dbus-daemon --fork --print-pid 4 --print-address 6 --session

    function clean {
      dbus_pid=$(cat $dbus_pid_file)
      if [[ -n $dbus_pid ]]; then
        kill $dbus_pid
      fi
      rm -f $dbus_pid_file $dbus_add_file
    }
    trap "{ clean; }" EXIT

    export DBUS_SESSION_BUS_ADDRESS=$(cat $dbus_add_file)

    init-checkconf $config
  '';



  postInstall =
    ''
      t=$out/etc/bash_completion.d
      mkdir -p $t
      cp ${./upstart-bash-completion} $t/upstart

      chmod +x $out/bin/init-checkconf
      sed -i "s,/sbin,$out/bin,g" $out/bin/init-checkconf
      wrapProgram $out/bin/init-checkconf \
        --prefix PATH : ${makeBinPath [utillinux dbus]}
      chmod +x $out/bin/initctl2dot
    '';

  meta = {
    homepage = "http://upstart.ubuntu.com/";
    description = "An event-based replacement for the /sbin/init daemon";
    platforms = stdenv.lib.platforms.linux;
  };
};

in upstart
