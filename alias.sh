#!/bin/zsh

alias ctxg="ctxslice graphistrygpt --ignore graphistrygpt/telemetry.py graphistrygpt/emitter.py graphistrygpt/core/run_context.py"
alias ctxae="ctxg --target graphistrygpt/agent/base.py"
alias ctxdf="ctxg --target graphistrygpt/models/element/df.py"
alias ctxam="ctxg --target graphistrygpt/app_core/account_manager.py"
alias ctxtools="ctxg --target graphistrygpt/tool/tools.py"