#!/bin/sh

#  find.sh
#  XToDo
#
#  Created by Travis on 13-11-28.
#  Copyright (c) 2013年 Plumn LLC. All rights reserved.

KEYWORDS="$2"

find "$1" \( -name "*.h" -or -name "*.hpp" -or -name "*.m" -or -name "*.mm" -or -name "*.c" -or -name "*.cpp" -or -name "*.cc"    \) -print0 | xargs -0 egrep --with-filename --line-number --only-matching "//\ {0,2}($KEYWORDS).*\$" | perl -p -e "s/($KEYWORDS)/:\$1/"
