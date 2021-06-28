---
tags: git soen tutorial
---

# Git Hooks - Automatic Git Pulls

## A Lazy Person Innovates

Innovations arise when we encounter inconvenience, when some task becomes repetitive and tedious. Now whether or not this really qualifies as an innovation depends on how you see it 😉, but it is something that I expect to save me quite a bit of time in the future.

## The Inconvenience That I Faced
Allow me to first describe the problem, or rather the inconvenience that I found myself facing, basic familiarity with Git is assumed of the reader. Throughout the course of my day, I checkout various branches of the repository that I am working on. Needless to say, others are also doing the same thing, and every so often a collaborator will `merge/push` a change to a branch that I am also working on. Hence, before I do anything with the branch that I've just checked out, I would most likely want to `pull` the new changes.

I might not always notice the new commits that have been pushed to that branch, i.e. I might just forget to run `git pull` 😅

## Automating This Using Git Hooks!
Wouldn't it be nice if I no long have to be on the lookout for such a scenario? Here's where we can use a Git hook to make life slightly easier for us. In any Git repository, there would be a hidden `.git` folder in the root directory, within it there is a particular folder called `hook` which will contain all of our Git hooks for that particular repository! Running the `ls` command should yield us many example files already present in that folder (which is populated when we first run `git init`).

```
$ ls .git/hooks
applypatch-msg.sample
commit-msg.sample
fsmonitor-watchman.sample
post-update.sample
pre-applypatch.sample
pre-commit.sample
pre-merge-commit.sample
pre-push.sample
pre-rebase.sample
pre-receive.sample
prepare-commit-msg.sample
update.sample
```

To make any of them work, you just have to remove the `.sample` extension. And to find out more about these hooks, [this](https://git-scm.com/docs/githooks) would be a good start.

### post-checkout

In my case, I am going to write my own version of `post-checkout`. Basically, I would like to check after checking out a branch if the `HEAD` of my local version of the branch is the same as the `HEAD` of the remote version of this branch. Suppose that they are different, I would then need to check if the remote `HEAD` is a descendant of my local `HEAD`, if it is then it would make sense to just run `git pull`. That's all I would like to achieve for now, and it can be easily done using a **bash script**.

The `post-checkout` script will receive three arguments when it is run. The ref of the previous `HEAD`, the ref of the new `HEAD` (which may or may not have changed), and a flag indicating whether **the checkout was a branch checkout** (changing branches, flag=1) or a file checkout (retrieving a file from the index, flag=0)[^1]. 

So my `post-checkout` file looks something like that

```
#!/bin/sh
currentbranch=`git branch --show-current`
if [[ !$(git branch -a | egrep 'remotes/origin/${current_branch}$') ]] 
then
    exit
fi

originsha=$(git rev-parse origin/$currentbranch)
currentsha=$2

isdescendant=$(git merge-base --is-ancestor $currentsha $originsha; echo $?)

if [ $3 -eq 1 ] && [ $originsha != $currentsha ] && [ $isdescendant = 0 ]; then
    echo 'Fetching changes from remote...'
    git pull
fi
```

To those new to Git commands on the CLI (and bash scripts), I will briefly describe what's happening here. 

```
currentbranch=`git branch --show-current`
```
We first find out the name of our current branch and assign it to a variable, this should be pretty self-explanatory.

```
if [[ !$(git branch -a | egrep 'remotes/origin/${current_branch}$') ]] 
then
    exit
fi
```
This part serves to check whether or not this branch exists in the remote, imagine if you just check ran `git checkout -b 'new-branch-name'`, `new-branch-name` would not exist in the remote and we would like to exit at this point.

```
originsha=$(git rev-parse origin/$currentbranch)
currentsha=$2
```
Each commit on Git has a `code` of sorts, which are called **SHA** of commits. We first find out what is the **SHA** of the commit of the remote `HEAD`, at the same time we can access the **SHA** of our local head via the second parameter passed to this script (as mentioned before).

```
isdescendant=$(git merge-base --is-ancestor $currentsha $originsha; echo $?)
```

Now that we have the SHA of the remote `HEAD` and the local `HEAD`, we can run a Git command to find out if the remote `HEAD` is a descendant of ours, a positive response will be signified by a **0** (by convention, a zero represents a successful resolution of a command). Why do we check for this? It is possible that the local and remote version of this branch has diverged, i.e. the branches look a little like the below[^2].

```
... o ---- o ---- A ---- B  origin/branch_xxx (upstream work)
                   \
                    C  branch_xxx (your work)
```

If this is the situation, we may or may not want to pull (which will result in a merge).


```
if [ $3 -eq 1 ] && [ $originsha != $currentsha ] && [ $isdescendant = 0 ]; then
    echo 'Fetching changes from remote...'
    git pull origin $currentbranch
fi
```
Finally, we first check if the current `checkout` operation corresponds to the checking out of a branch (we could have been checking out a file!), and as mentioned before the 3rd parameter is a flag that indicates what sort of checkout we are dealing with. Next, we also check if the local and remote HEADs have different **SHAs**, if they are already the same there is no point in doing anything further. And suppose that they are not equal, we would then check if the remote `HEAD` is a descendant of our local one. Given that the above conditions are fulfilled, we would want this `git pull` to be executed.

Before this file can be used, we need to allow it be executed by running the following
```
chmod +x .git/hooks/post-checkout
```

## Global Hooks
Of course, it would be a real pain if one needed to copy this file to every other repository that one works with. It is also possible to set up a `global` hook, i.e. one that would work for all of our repositories.

First, create a folder to store these `global hooks`, personally I created a folder at this directory `~/.githooks`. And, within this folder store of all the hooks that we wish to use globally, i.e. put a copy of the `post-checkout` file in this directory as well.

And lastly, we need to change a config to make Git run all hooks in this directory.
```
git config --global core.hooksPath ~/.githooks
```

## The End
That was a pretty simple use case of a Git hook, we can do many other things by leveraging Git hooks, just let your imagination run wild!


[^1]: https://git-scm.com/docs/githooks.
[^2]: http://serebrov.github.io/html/2012-02-13-git-branches-have-diverged.html
