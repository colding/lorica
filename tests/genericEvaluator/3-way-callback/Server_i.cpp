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

#include "Server_i.h"

// Implementation skeleton constructor
Test_Server_i::Test_Server_i(CORBA::ORB_ptr orb,
			     int *success_count,
			     int *failure_count)
	: orb_(CORBA::ORB::_duplicate (orb)),
	  success_count_(success_count),
	  failure_count_(failure_count)
{
}

// Implementation skeleton destructor
Test_Server_i::~Test_Server_i(void)
{
}

::CORBA::Boolean
Test_Server_i::receive_call(::Test::CallBack_ptr cb)
{
	ACE_DEBUG((LM_DEBUG, "Remote invocation recieved\n"));

	static int ping_count = 0;
	::Test::CallBack_var call_back = cb;

	ping_count++;
	if (2 < ping_count) {
		orb_->shutdown();
                return (::CORBA::Boolean)1;
	}
	try {
		call_back->ping();
		(*success_count_)++;
	}
        catch (const CORBA::Exception &e) {
                ACE_DEBUG((LM_CRITICAL, ACE_TEXT("%N:%l - %s\n"), e._info().c_str()));
		(*failure_count_)++;
                return (::CORBA::Boolean)0;
        }
        catch (...) {
                ACE_DEBUG((LM_CRITICAL, ACE_TEXT("%N:%l - Unknown C++ exception\n")));
		(*failure_count_)++;
                return (::CORBA::Boolean)0;
        }
	
	return (::CORBA::Boolean)1;
}

