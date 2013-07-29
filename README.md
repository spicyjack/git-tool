git-tool
========
Copyright (c)2013 Brian Manning <brian at xaoc dot org>

License: GPL v2 (see licence blurb at the bottom of the `git-tool.sh` file)

Manage multiple git repos quicker and easier than doing it by hand ;)

If you name your Git repos with `*.git` extensions, then this tool can do
different checks on those repos.  For example, you can see if you have files
that need to be indexed/committed, or repos that need to be pushed to the
remote.  Can also do a "mass pull" of all of your Git repos (as `*.git`
directories) at one time.

This tool should work with any OS that has a copy of `bash`; note that the
Windows CLI version of Git does include it's own copy of `bash.exe` ;)

- Clone the script repo with:
  - `git clone https://github.com/spicyjack/git-tool.git`
- Script also can be obtained from:
  - https://github.com/spicyjack/git-tool/blob/master/git-tool.sh
- Get support and more info about this script at:
  - https://github.com/spicyjack/git-tool/issues

This tool is somewhat similar to what the `repo` (http://tinyurl.com/6pblfg4)
tool, sans the messy XML manifest bits needed that `repo` uses to do it's job.


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
