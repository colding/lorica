/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: t; c-basic-offset: 2 -*- */

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

/**
 * Definition of Lorica service. An instance of this class initializes the
 * ORB, gets the root POA, POA Manager Factory, IOR Table, and finally
 * runs the ORB.
 *
 */

#ifndef PROXY_H
#define PROXY_H

#include <string>
#include <ace/Task.h>
#include <tao/ORB.h>
#include <tao/PortableServer/POAC.h>
#include <tao/IORTable/IORTable.h>
#include <tao/PortableServer/POAManagerFactoryC.h>

namespace Lorica
{
	// Forward declarations.
	class Config;

/**
 *
 * The Proxy class contains all the base elements used to support the
 * application. It is based on ACE_Task_Base so that it may be easily
 * threaded.
 */

	class Proxy : public ACE_Task_Base {
	public:
		class InitError{};

		Proxy(const bool Debug);

		virtual ~Proxy(void);

		// load configuration based on supplied config file
		virtual void configure(Config & config,
													 const std::string &def_ior_file = "")
			throw (InitError);

		// ACE Task base generic initializer - args[0] is config file name
		virtual int open(void *args = 0);

		// ACE Task base executable method.
		virtual int svc(void);

		// this only shuts down the proxy's svc loop.
		void shutdown(void);
		
		// this causes the ORB to destroy its resources and clean up.
    void destroy(void);

	private:
		bool setup_shutdown_handler(void);

		static Proxy* this_;

		friend int signal_handler(int signum);

		CORBA::ORB_var orb_;
		PortableServer::POA_var root_poa_;
		PortableServer::POAManagerFactory_var pmf_;
		PortableServer::POAManager_var outside_pm_;
		PortableServer::POAManager_var inside_pm_;
		IORTable::Table_var iorTable_;
		PortableServer::POA_var admin_poa_;

		std::string ior_file_;

		bool must_shutdown_;
		bool debug_;
	};

	int signal_handler(int signum);

}  /* namespace Lorica */

#endif // PROXY_H
