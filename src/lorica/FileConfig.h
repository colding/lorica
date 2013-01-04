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

#ifndef _FILECONFIG_
#define _FILECONFIG_

#include <map>
#include <iostream>

#include <ace/Singleton.h>
#include <ace/OS_NS_stdlib.h>

#include "ConfigBase.h"
#include "Lorica_EvaluatorBase_Export.h"

namespace Lorica
{

	class Lorica_EvaluatorBase_Export FileConfig : public Config {
		friend class ACE_Singleton<FileConfig,ACE_Recursive_Thread_Mutex>;
	public:
		class InitError {
		};

		virtual ~FileConfig(void);

		/// Return a singleton instance of this class.
		static FileConfig *instance(void);

		void init(const std::string & file_name,
			  int debug_level = 0)
			throw(InitError);

		/// Get associated configuration option.
		virtual std::string get_value(const std::string & token,
					      const std::string & def = "") const;
		virtual long get_long_value(const std::string & token,
					    long def = 0L) const;

		virtual bool get_bool_value(const std::string & token,
					    bool def = false) const;

		virtual int debug_level(void);

	private:
		/// Make sure only one instance is created.
		FileConfig(void);

		// trims characters in char_set from the end of str 
		// and return the result
		inline std::string rtrim(std::string const & str, 
					 char const *char_set);

		inline bool insert(const std::string & token,
				   const std::string & value);

		inline std::string extract(const std::string & token,
					   const std::string & def) const;

		/// Parse the given file
		bool load(void);

		/// reset the Configuration object
		bool unload(void);

		typedef int KEY_TYPE;
		typedef std::map<KEY_TYPE, std::string> Configs;

		// We need an iterator here for general traversal.
		Configs configs_;

		std::string file_name_;
		int debug_level_;

		const char COMMENT_CHAR;
	};
} /* namespace Lorica */

LORICA_EVALUATORBASE_SINGLETON_DECLARE (ACE_Singleton, Lorica::FileConfig, ACE_Recursive_Thread_Mutex)
typedef ACE_Singleton<Lorica::FileConfig, ACE_Recursive_Thread_Mutex> FILECONFIG;

#endif // _FILECONFIG_
