# Git collection

Collection of Git-related snippets and commands



##### Git tags removement

1. Delete remote tags (before deleting local tags):

```shell script
git tag -l | xargs -n 1 git push --delete origin
```

2. Delete local tags:

```shell script
git tag | xargs git tag -d
```

