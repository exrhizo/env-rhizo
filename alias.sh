#!/bin/zsh

alias ctxg="ctxslice graphistrygpt --ignore graphistrygpt/telemetry.py graphistrygpt/emitter.py graphistrygpt/core/run_context.py"
alias ctxae="ctxg --target graphistrygpt/agent/base.py"
alias ctxdf="ctxg --target graphistrygpt/models/element/df.py"
alias ctxam="ctxg --target graphistrygpt/app_core/account_manager.py"
alias ctxtools="ctxg --target graphistrygpt/tool/tools.py"

# Graphistry related
alias ssh-dev="ssh -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem ubuntu@louie-dev.grph.xyz"
alias ssh-prod="ssh -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem ubuntu@den.louie.ai"
alias ssh-precog="ssh -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem ubuntu@louie-precog.grph.xyz"
alias scp-dev="scp -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem"
alias scp-prod="scp -i ~/.ssh/dev-team-shared-louie-dev-us-east-1.pem"

alias mymy="fswatch -o --exclude '.*cache.*' graphistrygpt | while read -r; do MYPY_OUTPUT=\$(mypy --config-file graphistrygpt/mypy.ini graphistrygpt 2>&1); RUFF_OUTPUT=\$(ruff check ./graphistrygpt 2>&1); reset; echo \"\$MYPY_OUTPUT\"; echo \"\$RUFF_OUTPUT\"; done"
alias lupg='(set -a; source system.env; set +a; echo "postgresql://${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}"; PGPASSWORD=$POSTGRES_PASSWORD psql "postgresql://${POSTGRES_USER}@${POSTGRES_HOST}:${POSTGRES_PORT:-5432}")'
export PYTEST_DC=./dcc

alias conda-lu="$ENVDIR/setup/conda_louie.sh"
alias danger-claude="claude --dangerously-skip-permissions"
alias usevenv='export PATH="$(git rev-parse --show-toplevel 2>/dev/null || printf %s "$PWD")/.venv/bin:$PATH"; hash -r'
