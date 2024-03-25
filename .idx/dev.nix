{ pkgs, ... }: {
  channel = "stable-23.11"; # "stable-23.11" or "unstable"
  packages = [
    pkgs.flutter
    pkgs.nodePackages.firebase-tools
    pkgs.jdk17
  ];
  idx.extensions = [];
  idx.previews = {
    enable = true;
    previews = [
        {
            command = ["flutter" "run" "--machine" "-d" "android" "-d" "localhost:5555"];
            id = "android";
            manager = "flutter";
            cwd = "app";
        }
        {
            id = "ios";
            manager = "ios";
            cwd = "app";
        }
    ];
  };
}
