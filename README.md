# PwdlessGs

[Source Oauth](https://github.com/auth0-developer-hub/api_phoenix_elixir_hello-world/tree/basic-authorization)

[Rate limiting GenServer](https://akoutmos.com/post/rate-limiting-with-genservers/)

## Git: move modifications to a new branch

Create a new feature branch and move the uncommitted work to the new branch. Moreover, the master branch shouldn't be modified.

```bash
git switch -C new-branch
git status
# Changes not staged
git add . && git commit -m 'modifications'

# return to main
git switch main
git status
# nothing to commit !!!! YES !!
```
