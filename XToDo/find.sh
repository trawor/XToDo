#!/bin/sh

#  find.sh
#  XToDo
#
#  Created by Travis on 13-11-28.
#  Copyright (c) 2013年 Plumn LLC. All rights reserved.

KEYWORDS="$1"

xargs -0 egrep --with-filename --line-number --only-matching "//\ {0,2}($KEYWORDS).*\$" | perl -p -e "s/($KEYWORDS)/:\$1/"

