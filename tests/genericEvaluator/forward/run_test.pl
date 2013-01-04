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

use Env (ACE_ROOT);
use Env (TAO_ROOT);
use Env (LORICA_ROOT);

use lib "$ENV{ACE_ROOT}/bin";
use PerlACE::Run_Test;

$status = 0;
$debug = '0';
$direct = 0;

foreach $i (@ARGV) {
    if ($i eq '-debug') {
        $debug = '10';
    }
    elsif ($i eq '-direct') {
        $direct = 1;
    }
}

unlink  ("ifr.cache");

$mappedfile = PerlACE::LocalFile ("mapped.ior");
unlink $mappedfile;

$origfile = PerlACE::LocalFile ("orig.ior");
unlink $origfile;

$pidfile = PerlACE::LocalFile ("lorica.pid");
unlink $pidfile;

unlink "client.log";
unlink "proxy.log";
unlink "server.log";

$ifrfile = "ifr.ior";

$PR = new PerlACE::Process ("$LORICA_ROOT/src/proxy/lorica", "-n -d -f test.conf -l 1");

$IDLC = new PerlACE::Process ("$TAO_ROOT/orbsvcs/IFR_Service/tao_ifr",
                              " -ORBInitRef InterfaceRepository=file://$ifrfile ".
                              " test.idl");

$SV = new PerlACE::Process ("server", " -ORBUseSharedProfile 1 -ORBdebuglevel $debug -o $origfile -m $mappedfile");

$source_key = "file://$mappedfile";
if ($direct == 1) {
    $source_key = "file://$origfile";
}

$CL = new PerlACE::Process ("client", "-ORBDebuglevel $debug -k $source_key -x");

print "forwarding test is started\n";

$proxy = $PR->Spawn ();
if (PerlACE::waitforfile_timed ($pidfile,
                        $PerlACE::wait_interval_for_process_creation) == -1) {
    print STDERR "ERROR: cannot find file <$pidfile>\n";
    $PR->Kill (); $PR->TimedWait (1);
    exit 1;
}

$idlc_ret = $IDLC->SpawnWaitKill (60);
if (($idlc_ret != 0) || ($? != 0)) {
  if ($idlc_ret == 0) { $idlc_ret = $?; }
  print STDERR "Error: IDL Compiler returned $idlc_ret\n";
  $status = 1;
}

$server = $SV->Spawn ();
if (PerlACE::waitforfile_timed ($mappedfile,
             $PerlACE::wait_interval_for_process_creation) == -1) {
    print STDERR "ERROR: cannot find file <$pidfile>\n";
    $SV->Kill (); $SV->TimedWait (1);
    $PR->Kill (); $PR->TimedWait (1);
    exit 1;
}

$client = $CL->SpawnWaitKill (30);

$server = $SV->Kill ();

$proxy = $PR->Kill ();

if ($proxy != 0) {
    print STDERR "ERROR: server returned $server\n";
    $status = 1;
}

unlink $mappedfile;
unlink $origfile;
unlink $pidfile;

exit $status;
