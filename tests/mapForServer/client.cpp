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

#include "TestC.h"
#include <ace/Get_Opt.h>

ACE_RCSID(Hello, client, "$Id: client.cpp 1626 2007-03-19 01:42:06Z mesnierp $")

const char *ior = "file://mapped.ior";

int
parse_args (int argc, char *argv[])
{
	ACE_Get_Opt get_opts (argc, argv, "k:");
	int c;

	while ((c = get_opts ()) != -1)
		switch (c)
		{
		case 'k':
			ior = get_opts.opt_arg ();
			break;

		case '?':
		default:
			ACE_ERROR_RETURN ((LM_ERROR,
					   "usage:  %s "
					   "-k <ior> "
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

		if (parse_args (argc, argv) != 0)
			return 1;

		CORBA::Object_var tmp = orb->string_to_object(ior);
		Test::Hello_var hello =
			Test::Hello::_narrow(tmp.in ());

		if (CORBA::is_nil (hello.in ()))
		{
			ACE_ERROR_RETURN ((LM_DEBUG,
					   "Nil Test::Hello reference <%s>\n",
					   ior),
					  1);
		}

		CORBA::String_var the_string =
			hello->get_string ();

		ACE_DEBUG ((LM_DEBUG, "(%P|%t) - string returned <%s>\n",
			    the_string.in ()));
		hello->shutdown ();

		orb->destroy ();
	}
	catch (const CORBA::Exception& ex)
	{
		ex._tao_print_exception ("Exception caught:");
		return 1;
	}

	return 0;
}
