{
  autoPatchelfHook,
  buildFHSEnvChroot,
  dpkg,
  lib,
  stdenv,
  sysctl,
  iptables,
  iproute2,
  procps,
  cacert,
  libxml2_13,
  sqlite,
  libidn2,
  zlib,
  wireguard-tools,
  icu72,
  libnl,
  libcap_ng,
  nordvpn-amd64-deb,
  nordvpn-arm64-deb,
}: let
  pname = "nordvpn";
  version = "4.2.0";

  nordVPNBase = stdenv.mkDerivation {
    inherit pname version;

    src =
      if stdenv.hostPlatform.system == "x86_64-linux"
      then nordvpn-amd64-deb
      else if stdenv.hostPlatform.system == "aarch64-linux"
      then nordvpn-arm64-deb
      else throw "Unsupported platform: ${stdenv.hostPlatform.system}";

    buildInputs = [libidn2 icu72 libnl libcap_ng sqlite libxml2_13];
    nativeBuildInputs = [dpkg autoPatchelfHook stdenv.cc.cc.lib];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg --extract $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      mv usr/* $out/
      mv var/ $out/
      mv etc/ $out/
      runHook postInstall
    '';
  };

  nordVPNfhs = buildFHSEnvChroot {
    name = "nordvpnd";
    runScript = "${nordVPNBase}/bin/nordvpnd";

    targetPkgs = pkgs: [
      nordVPNBase
      sysctl
      iptables
      iproute2
      libxml2_13
      procps
      cacert
      libidn2
      zlib
      wireguard-tools
      icu72
      libnl
      libcap_ng
    ];
  };
in
  stdenv.mkDerivation {
    inherit pname version;

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share
      ln -s ${nordVPNBase}/bin/nordvpn $out/bin
      ln -s ${nordVPNfhs}/bin/nordvpnd $out/bin
      ln -s ${nordVPNBase}/share/* $out/share/
      ln -s ${nordVPNBase}/var $out/
      runHook postInstall
    '';

    meta = with lib; {
      description = "CLI client for NordVPN";
      homepage = "https://www.nordvpn.com";
      license = licenses.unfreeRedistributable;
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
