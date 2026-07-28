{pkgs, ...}: {
  languages = {
    rust.enable = true;
    typst.enable = true;
  };
  packages = with pkgs; [
    rustlings
    codecrafters-cli
    bacon
  ];
}
