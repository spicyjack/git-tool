git-tool
========

Manage multiple git repos quicker and easier than doing it by hand ;)

View script usage with `git-tool.sh --help`, and view examples of script usage
with `git-tool.sh --examples` (reproduced below).

## git-tool.sh Examples ##

    # get the status of all *.git dirs in /path/to/src/tree,
    # exclude /path/to/tree/dirA, /path/to/src/tree/dirB
    git-tool.sh --path=/path/to/src/tree --exclude="dirA|dirB" repostat

    # check to see if you've forgotten to push to a remote repo
    # does not need to access the network, so faster than 'git push --dry-run'
    git-tool.sh --path=/path/to/src/tree --exclude="dirA|dirB" refchk

    # check to see if you need to pull from remote repos to local repos
    # ** needs network access **
    git-tool.sh --path=/path/to/src/tree --exclude="dirA|dirB" inchk

    # check to see if you need to push to remote repos from local repos
    # ** needs network access **
    git-tool.sh --path=/path/to/src/tree --exclude="dirA|dirB" outchk

vim: filetype=markdown tabstop=2 shiftwidth=2
