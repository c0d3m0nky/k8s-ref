# A nix-shell setup you can run, just have it in the working directory and run without args
{ pkgs ? import <nixpkgs> {} }:
  
pkgs.mkShell {
  buildInputs = with pkgs; [
    kubernetes-helm
    minikube
    kubectl
  ];

  shellHook = ''
    # export VAR_NAME="VALUE"
  '';
}