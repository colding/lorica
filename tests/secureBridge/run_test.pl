#
#  A part of Lorica.
#  Copyright (C) 2007-2009 OMC Denmark ApS.
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program. If not, see <http://www.gnu.org/licenses/>.


eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}'
     & eval 'exec perl -S $0 $argv:q'
     if 0;

use Env (LORICA_ROOT);
use lib "$ENV{ACE_ROOT}/bin";
use PerlACE::Run_Test;

$status = 0;
$debug_level = '0';

foreach $i (@ARGV) {
    if ($i eq '-debug') {
        $debug_level = '10';
    }
}

$mappedfile = PerlACE::LocalFile ("mapped.ior");
unlink $mappedfile;

$origfile = PerlACE::LocalFile ("orig.ior");
unlink $origfile;

$epidfile = PerlACE::LocalFile ("east_lorica.pid");
unlink $epidfile;

$wpidfile = PerlACE::LocalFile ("west_lorica.pid");
unlink $wpidfile;

$EAST = new PerlACE::Process ("$LORICA_ROOT/src/proxy/lorica", "-n -d -f east.conf");
$WEST = new PerlACE::Process ("$LORICA_ROOT/src/proxy/lorica", "-n -d -f west.conf");

$SV = new PerlACE::Process ("server", " -ORBUseSharedProfile 1 -ORBdebuglevel $debug_level -o $origfile -m $mappedfile -l -ORBEndpoint iiop://:22022");

$CL = new PerlACE::Process ("client", "-p corbaloc::localhost:10961/lorica_reference_mapper -k file://$mappedfile -ORBLogfile client.log");

print "Starting East proxy\n";

$east = $EAST->Spawn ();
if (PerlACE::waitforfile_timed ($epidfile,
				$PerlACE::wait_interval_for_process_creation) == -1) {
    print STDERR "ERROR: cannot find file <$epidfile>\n";
    $EAST->Kill (); $EAST->TimedWait (60);
    exit 1;
}

print "Starting West proxy\n";

$west = $WEST->Spawn ();
if (PerlACE::waitforfile_timed ($wpidfile,
				$PerlACE::wait_interval_for_process_creation) == -1) {
    print STDERR "ERROR: cannot find file <$wpidfile>\n";
    $WEST->Kill (); $WEST->TimedWait (1);
    exit 1;
}

print "Starting server\n";

$server = $SV->Spawn ();

if (PerlACE::waitforfile_timed ($mappedfile,
				$PerlACE::wait_interval_for_process_creation) == -1) {
    print STDERR "ERROR: cannot find file <$mappedfile>\n";
    $SV->Kill (); $SV->TimedWait (1);
    $EAST->Kill (); $EAST->TimedWait (1);
    $WEST->Kill (); $WEST->TimedWait (1);
    exit 1;
}

print "Starting client\n";

$client = $CL->SpawnWaitKill (300);

$server = $SV->Kill ();

$east = $EAST->Kill ();
$west = $WEST->Kill ();
if ($east != 0 || $west != 0) {
    print STDERR "ERROR: server returned $server\n";
    $status = 1;
}

unlink $mappedfile;
unlink $origfile;
unlink $eastfile;
unlink $westfile;

exit $status;
