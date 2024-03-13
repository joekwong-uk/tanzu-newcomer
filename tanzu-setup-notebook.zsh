# Install Home Brew
export HOMEBREW_NO_INSTALL_FROM_API=1
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
# Install Visual Studio Code and shell notebook extension
brew install --cask visual-studio-code
code --install-extension tylerleonhardt.shell-runner-notebooks
# Now try to close this file and open again in a notebook format
# Docker Desktop and install k8s
# https://docs.docker.com/desktop/install/mac-install/
# brew install k8s related tools
# kubectl kubectx k9s
brew install kubectl kubectx k9s jq wget curl
curl -sS https://webi.sh/kubens | sh
# Cloud CLI
# AWS / Google Cloud / Azure
brew install awscli
brew install azure-cli
brew install --cask google-cloud-sdk
# EKSCTL
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
# Tanzu CLI - Powerful cli tools help you to setup and control Tanzu environment
brew install vmware-tanzu/tanzu/tanzu-cli
# (Alternative installation) Or download and install it using pivnet cli
pivnet download-product-files --product-slug='tanzu-application-platform' --release-version='1.8.0' --product-file-id=1730650   
# Install latest plugin for Tanzu CLI
tanzu plugin install --group vmware-tkg/default
# Auto Completion! Productivity gain!! - Add lines to .zshrc for autocomplete
autoload -Uz compinit && compinit
autoload bashcompinit && bashcompinit
# kubectl autocompletion
compinit
source <(kubectl completion zsh)
# gcloud auto complete
source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
# aws auto complete
complete -C '/usr/local/bin/aws_completer' aws
# EKSCTL
source <(eksctl completion zsh)
# azure auto complete
source $(brew --prefix)/etc/bash_completion.d/az
# tanzu auto complete
source <(tanzu completion zsh)
compdef _tanzu tanzu
# Install Carvel Tools
brew tap vmware-tanzu/carvel
brew install kapp ytt kbld imgpkg vendir kctrl
