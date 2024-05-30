# Install Home Brew
export HOMEBREW_NO_INSTALL_FROM_API=1
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

# Install Visual Studio Code and shell notebook extension
brew install --cask visual-studio-code
#  shell notebook extension fail behind some firewall, you might need to search this extension using code UI
code --install-extension tylerleonhardt.shell-runner-notebooks

# Now try to close this file and open again in a notebook format
# Docker Desktop and install k8s
# https://docs.docker.com/desktop/install/mac-install/
# brew install k8s related tools
# kubectl kubectx k9s
brew install kubectl kubectx k9s jq wget curl
curl -sS https://webi.sh/kubens | sh

# Cloud CLI
# AWS 
brew install awscli
# Azure
brew install azure-cli
# Google Cloud 
brew install --cask google-cloud-sdk

# EKSCTL
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Pivotal Net Cli - Help download binaries or code from tanzu netework (fomerly know as pivotal Net)
brew install pivotal/tap/pivnet-cli

# Tanzu CLI - Powerful cli tools help you to setup and control Tanzu environment
brew install vmware-tanzu/tanzu/tanzu-cli

# Install latest plugin for Tanzu CLI / you may be prompted for EULA/CIP 
tanzu plugin install --group vmware-tkg/default
tanzu plugin install --group vmware-tanzu/platform-engineer
# Install Carvel Tools
brew tap vmware-tanzu/carvel
brew install kapp ytt kbld imgpkg vendir kctrl

# Auto Completion! Productivity gain!! - Add lines to .zshrc for autocomplete
touch  ~/.zshrc
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc && source ~/.zshrc
echo 'autoload bashcompinit && bashcompinit' >> ~/.zshrc && source ~/.zshrc

# kubectl autocompletion
echo 'compinit' >> ~/.zshrc && source ~/.zshrc
echo 'source <(kubectl completion zsh)' >> ~/.zshrc && source ~/.zshrc

# gcloud auto complete
echo 'source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"' >> ~/.zshrc && source ~/.zshrc
echo 'source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"' >> ~/.zshrc && source ~/.zshrc

# aws auto complete
echo 'complete -C '/usr/local/bin/aws_completer' aws' >> ~/.zshrc && source ~/.zshrc

# EKSCTL
echo 'source <(eksctl completion zsh)' >> ~/.zshrc && source ~/.zshrc

# azure auto complete
echo 'source $(brew --prefix)/etc/bash_completion.d/az' >> ~/.zshrc && source ~/.zshrc

# tanzu auto complete
echo 'source <(tanzu completion zsh)' >> ~/.zshrc && source ~/.zshrc
echo 'compdef _tanzu tanzu' >> ~/.zshrc && source ~/.zshrc
