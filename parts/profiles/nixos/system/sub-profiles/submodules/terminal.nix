_: {
  environment = {
    enableAllTerminfo = true;
    pathsToLink = ["/share/zsh" "/libexec"];
  };

  programs = {
    bash.vteIntegration = true;
    zsh.vteIntegration = true;
  };
}
