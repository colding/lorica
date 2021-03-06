/* -*- Mode: C++; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */

/*
 *  Lorica source file.
 *  Copyright (C) 2007-2009 OMC Denmark ApS.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "Hello.h"
#include <ace/Get_Opt.h>
#include <ace/OS_NS_stdio.h>

ACE_RCSID (Hello,
	   server,
	   "$Id: server.cpp 1574 2007-03-05 02:48:36Z mesnierp $")

const char *ior_output_file = "test.ior";

int
parse_args (int argc, char *argv[])
{
	ACE_Get_Opt get_opts (argc, argv, "o:");
	int c;

	while ((c = get_opts ()) != -1)
		switch (c)
		{
		case 'o':
			ior_output_file = get_opts.opt_arg ();
			break;

		case '?':
		default:
			ACE_ERROR_RETURN ((LM_ERROR,
					   "usage:  %s "
					   "-o <iorfile>"
					   "\n",
					   argv [0]),
					  -1);
		}
	// Indicates sucessful parsing of the command line
	return 0;
}

int
main (int argc, char *argv[])
{
	try
	{
		CORBA::ORB_var orb =
			CORBA::ORB_init (argc, argv, "");

		CORBA::Object_var poa_object =
			orb->resolve_initial_references("RootPOA");

		PortableServer::POA_var root_poa =
			PortableServer::POA::_narrow (poa_object.in ());

		if (CORBA::is_nil (root_poa.in ()))
			ACE_ERROR_RETURN ((LM_ERROR,
					   " (%P|%t) Panic: nil RootPOA\n"),
					  1);

		PortableServer::POAManager_var poa_manager =
			root_poa->the_POAManager ();

		if (parse_args (argc, argv) != 0)
			return 1;

		Hello *hello_impl;
		ACE_NEW_RETURN (hello_impl,
				Hello (orb.in ()),
				1);
		PortableServer::ServantBase_var owner_transfer(hello_impl);

		Test::Hello_var hello =
			hello_impl->_this ();

		CORBA::String_var ior =
			orb->object_to_string (hello.in ());

		// Output the IOR to the <ior_output_file>
		FILE *output_file= ACE_OS::fopen (ior_output_file, "w");
		if (output_file == 0)
			ACE_ERROR_RETURN ((LM_ERROR,
					   "Cannot open output file for writing IOR: %s\n",
					   ior_output_file),
					  1);
		ACE_OS::fprintf (output_file, "%s", ior.in ());
		ACE_OS::fclose (output_file);

		poa_manager->activate ();

		orb->run ();

		ACE_DEBUG ((LM_DEBUG, "(%P|%t) server - event loop finished\n"));

		root_poa->destroy (1, 1);

		orb->destroy ();
	}
	catch (const CORBA::Exception& ex)
	{
		ex._tao_print_exception ("Exception caught:");
		return 1;
	}

	return 0;
}
