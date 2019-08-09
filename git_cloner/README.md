# Scripts clone set of git repositories

Scripts clone set of git repositories to the destination repository as branches



### Preparing

- download script files `git-cloner.sh`, `pilferer.sh`
- create file with source list `touch list.txt`
- fill source list file using pattern `ssh://git@SOURCE_GIT_SERVER/SOURCE_REPO_NAME.git;DESTINATION_BRANCH_NAME` (separator `;`)
  You should get smth like:
  ```bash
  ssh://git@SOURCE_GIT_SERVER/SOURCE_REPO_NAME_1.git;DESTINATION_BRANCH_NAME_1
  ssh://git@SOURCE_GIT_SERVER/SOURCE_REPO_NAME_2.git;DESTINATION_BRANCH_NAME_2
  <empty line>
  ```
- ending file empty line (**important**) and save

To avoid multi-asking ssh password run in terminal:
- `ssh-add ~/.ssh/xx_rsa` (where `xx_rsa` - identity file for source repo)
- `ssh-add ~/.ssh/yy_rsa` (where `yy_rsa` - identity file for destination repo)



### Run

```bash
./pilferer.sh -c git-cloner.sh -d git@DESTINATION_GIT_SERVER/DESTINATION_REPO_NAME.git -s list.txt
```
