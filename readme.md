# Environment

### Features

 - M1 vs Rosetta
   - See: eastwood theme to prepend env
   - [Dual modes of homebrew](https://seannicdao.com/2021/02/dual-install-homebrew-nvm-and-node-on-apple-m1/)
   - implemented in env.sh
 - zsh using bash completions for:
   - Hasura
   - Git
   - Docker
   - see: zshrc.sh
     - Run `rm ~/.zcompdum` to reset completions


some inspiration from, [CxGarcia](https://github.com/CxGarcia/setup)

##### Random Strings While Compling this

```
https://github.com/git/git/blob/master/contrib/completion/git-completion.zsh
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
plugins=(… zsh-completions)
autoload -U compinit && compinit
rm ~/.zcompdum
```