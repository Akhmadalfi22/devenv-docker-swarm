#!/usr/bin/env bash
set -e

echo "=== Installed Tools ==="
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker compose version)"
echo "Terraform: $(terraform --version | head -n 1)"
echo "AWS CLI: $(aws --version)"
echo "Go: $(go version)"

# Display container information if available
if command -v devcontainer-info &> /dev/null; then
    devcontainer-info
fi

# Aliases
touch ~/.bashrc

ALIASES=$(cat << 'EOF'

# Docker aliases
alias d='docker'
alias dc='docker compose'

# Terraform aliases
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfs='terraform show'
alias tfv='terraform validate'

EOF
)

# Add aliases, skipping duplicates
while IFS= read -r line; do
    if [[ $line =~ ^alias[[:space:]]+ ]]; then
        # Extract alias name
        name=$(echo "$line" | awk -F"[ =]" '{print $2}')
        # Check if alias already exists
        if ! grep -qE "^alias $name=" ~/.bashrc; then
            echo "$line" >> ~/.bashrc
            echo "Added alias: $name"
        else
            echo "Alias $name already exists, skipping."
        fi
    else
        # Keep comments or empty lines if missing
        if ! grep -Fxq "$line" ~/.bashrc; then
            echo "$line" >> ~/.bashrc
        fi
    fi
done <<< "$ALIASES"

# Reload ~/.bashrc
source ~/.bashrc