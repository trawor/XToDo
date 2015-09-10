#!/bin/sh

#  find.sh
#  XToDo
#
#  Created by Travis on 13-11-28.
#  Copyright (c) 2013 fir.im  All rights reserved.

KEYWORDS="$1"

# New matching strategy handles colon noise more gracefully, supports keywords in multi-line comments, supports mid-line keywords, and generally leaves less clean-up work for Obj-C
xargs -0 egrep --with-filename --line-number --only-matching "^.*?[^\"]($KEYWORDS)(\!?).*?\$" | perl -p -e "s/^*(.+?):(.+?):.*($KEYWORDS)(\!?)[: \t]*(.*?)[: \t]*$/\$1:\$2:\$3:\$4:\$5/gm"
