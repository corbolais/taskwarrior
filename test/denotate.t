#! /usr/bin/perl
################################################################################
## taskwarrior - a command line task list manager.
##
## Copyright 2006 - 2011, Paul Beckingham, Federico Hernandez.
## All rights reserved.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation; either version 2 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, write to the
##
##     Free Software Foundation, Inc.,
##     51 Franklin Street, Fifth Floor,
##     Boston, MA
##     02110-1301
##     USA
##
################################################################################

use strict;
use warnings;
use Test::More tests => 32;

# Create the rc file.
if (open my $fh, '>', 'denotate.rc')
{
  # Note: Use 'rrr' to guarantee a unique report name.  Using 'r' conflicts
  #       with 'recurring'.
  print $fh "data.location=.\n",
            "confirmation=off\n",
            "report.rrr.description=rrr\n",
            "report.rrr.columns=id,description\n",
            "report.rrr.sort=id+\n";
  close $fh;
  ok (-r 'denotate.rc', 'Created denotate.rc');
}

# Add four tasks, annotate one three times, one twice, one just once and one none.
qx{../src/task rc:denotate.rc add one};
qx{../src/task rc:denotate.rc 1 annotate Ernie};
qx{../src/task rc:denotate.rc 1 annotate Bert};
qx{../src/task rc:denotate.rc 1 annotate Bibo};
qx{../src/task rc:denotate.rc 1 annotate Kermit the frog};
qx{../src/task rc:denotate.rc 1 annotate Kermit the frog};
qx{../src/task rc:denotate.rc 1 annotate Kermit};
qx{../src/task rc:denotate.rc 1 annotate Kermit and Miss Piggy};

my $output = qx{../src/task rc:denotate.rc rrr};
like ($output, qr/1 one/,   'task 1');
like ($output, qr/one.+\d{1,2}\/\d{1,2}\/\d{4} Ernie/ms,                    'first   annotation');
like ($output, qr/Ernie.+\d{1,2}\/\d{1,2}\/\d{4} Bert/ms,                   'second  annotation');
like ($output, qr/Bert.+\d{1,2}\/\d{1,2}\/\d{4} Bibo/ms,                    'third   annotation'); # 5
like ($output, qr/Bibo.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms,         'fourth  annotation');
like ($output, qr/frog.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms,         'fifth   annotation');
like ($output, qr/frog.+\d{1,2}\/\d{1,2}\/\d{4} Kermit/ms,                  'sixth   annotation');
like ($output, qr/Kermit.+\d{1,2}\/\d{1,2}\/\d{4} Kermit and Miss Piggy/ms, 'seventh annotation');
like ($output, qr/1 task/, 'count');      # 10

qx{../src/task rc:denotate.rc 1 denotate Ernie};
$output = qx{../src/task rc:denotate.rc rrr};
unlike ($output, qr/one.+\d{1,2}\/\d{1,2}\/\d{4} Ernie/ms, 'Delete annotation');
like ($output, qr/one.+\d{1,2}\/\d{1,2}\/\d{4} Bert/ms, 'Bert now first annotationt');

qx{../src/task rc:denotate.rc 1 denotate Bi};
$output = qx{../src/task rc:denotate.rc rrr};
unlike ($output, qr/Bert.+\d{1,2}\/\d{1,2}\/\d{4} Bibo/ms, 'Delete partial match');
like ($output, qr/Bert.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms, 'Kermit the frog now second annotation');

qx{../src/task rc:denotate.rc 1 denotate BErt};
$output = qx{../src/task rc:denotate.rc rrr};
like ($output, qr/one.+\d{1,2}\/\d{1,2}\/\d{4} Bert/ms, 'Denotate is case sensitive'); # 15
like ($output, qr/Bert.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms, 'Kermit the frog still second annoation');

qx{../src/task rc:denotate.rc 1 denotate Kermit};
$output = qx{../src/task rc:denotate.rc rrr};
like ($output, qr/one.+\d{1,2}\/\d{1,2}\/\d{4} Bert/ms,                   'Exact match deletion - Bert');
like ($output, qr/Bert.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms,       'Exact match deletion - Kermit the frog');
like ($output, qr/frog.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms,       'Exact match deletion - Kermit the frog');
like ($output, qr/frog.+\d{1,2}\/\d{1,2}\/\d{4} Kermit and Miss Piggy/ms, 'Exact match deletion - Kermit and Miss Piggy'); # 20

qx{../src/task rc:denotate.rc 1 denotate Kermit the};
$output = qx{../src/task rc:denotate.rc rrr};
like ($output, qr/one.+\d{1,2}\/\d{1,2}\/\d{4} Bert/ms,                   'Delete just one annotation - Bert');
like ($output, qr/Bert.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms,       'Delete just one annotation - Kermit the frog');
like ($output, qr/frog.+\d{1,2}\/\d{1,2}\/\d{4} Kermit and Miss Piggy/ms, 'Delete just one annotation - Kermit and Miss Piggy');

$output = qx{../src/task rc:denotate.rc 1 denotate Kermit a};
$output = qx{../src/task rc:denotate.rc rrr};
like ($output, qr/one.+\d{1,2}\/\d{1,2}\/\d{4} Bert/ms,                   'Delete partial match - Bert');
like ($output, qr/Bert.+\d{1,2}\/\d{1,2}\/\d{4} Kermit the frog/ms,       'Delete partial match - Kermit the frog'); # 25
unlike ($output, qr/frog.+\d{1,2}\/\d{1,2}\/\d{4} Kermit and Miss Piggy/ms, 'Delete partial match - Kermit and Miss Piggy');

# Cleanup.
unlink 'pending.data';
ok (!-r 'pending.data', 'Removed pending.data');

unlink 'completed.data';
ok (!-r 'completed.data', 'Removed completed.data');

unlink 'undo.data';
ok (!-r 'undo.data', 'Removed undo.data');

unlink 'backlog.data';
ok (!-r 'backlog.data', 'Removed backlog.data');

unlink 'synch.key';
ok (!-r 'synch.key', 'Removed synch.key');

unlink 'denotate.rc';
ok (!-r 'denotate.rc', 'Removed denotate.rc');

exit 0;
