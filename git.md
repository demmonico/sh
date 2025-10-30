# Git collection

Collection of Git-related snippets and commands


### Git tags

##### Git tags removement

1. Delete remote tags (before deleting local tags):

```shell script
git tag -l | xargs -n 1 git push --delete origin
```

2. Delete local tags:

```shell script
git tag | xargs git tag -d
```


### Git config

##### Git config - storing password in credentials helper

Storing the password for the whole day, so no need to log in with every push.

```shell script
git config credential.helper 'cache --timeout=86400'
```

##### Git config - verify username and email settings

```shell script
git config --local --list
```
