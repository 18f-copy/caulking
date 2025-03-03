#! /bin/bash -euo pipefail

MAXDEPTH=5

# MAXDEPTH 5 assumes a home directory structure that's no deeper than this:
#       $HOME/(projects)/(organization)/(repository)/(another_dir)/(yet_another_dir)
# Depth 0   / 1         / 2           / 3           / 4           / 5 

fail() {
    echo $@
    echo "Usage: $0 root_dir (check_precommit_hook | check_hooks_gitleak)"
    exit 2
}

[ $# = 2 ] || fail "need two args" 
if [ ! -d $1 ]; then 
    fail "first argument must be a directory"
else
    root=$1
fi 

case $2 in 
   check_hooks_gitleaks|check_precommit_hook) 
        option=$2
        :;;
   *) fail "invalid second argument";;
esac

exit_status=0

check_hooks_gitleaks() {
    hooks_gitleak=$(cd $gitrepo; git config --bool hooks.gitleaks)
    if [ $hooks_gitleak = "true" ]; then
        return 0
    else
        return 1
    fi
}

check_precommit_hook() {
    set -xv
    if [ -f $gitrepo/hooks/pre-commit ]; then
      pcregrep -q '^((?!#).)*gitleaks\s.*$' $gitrepo/hooks/pre-commit
      return $?
    fi
    return 0
}

# read gitrepo list from `find` using Process Substitution
# so exit_status isn't in a subshell
while read gitrepo; do 
    if eval $option $gitrepo; then
        :
    else
        echo "  $0 Fail $option: $gitrepo"
        exit_status=1
    fi
done <<< "$( find $root -name '.git' -type d -maxdepth $MAXDEPTH 2>/dev/null )"

exit $exit_status 
