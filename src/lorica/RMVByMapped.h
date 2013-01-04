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

#ifndef RMV_BY_MAPPED_H
#define RMV_BY_MAPPED_H

#include <ace/Mutex.h>
#include <ace/Condition_Thread_Mutex.h>
#include <ace/Task.h>

#include "Lorica_EvaluatorBase_Export.h"
#include "ReferenceMapValue.h"

namespace Lorica
{
	// Supports a "paged array" of ReferenceMapValues. A Paged Array is one
	// in which the array is allocated in fixed-size blocks. This gives
	// array-like semantics for efficient lookup with an unlimited capacity
	// and dynamic space allocation. If necessary, the array could be
	// "normalized" which reallocates multiple pages into a single large
	// contiguous block.

	class Lorica_EvaluatorBase_Export RMVByMapped : public ACE_Task_Base {
	public:
		RMVByMapped(time_t gc_period = 60, ACE_UINT32 page_size = 1024);

		virtual ~RMVByMapped(void);

		ACE_UINT32 next_index(void);

		bool bind(ACE_UINT32 index,
			  ReferenceMapValue *value);

		bool rebind(ACE_UINT32 index,
			    ReferenceMapValue *value);

		bool find(ACE_UINT32 index,
			  ReferenceMapValue *& value);

		bool unbind(ACE_UINT32 index,
			    ReferenceMapValue *& value);

		// The svc method overrides ACE_Task_Base::svc() to be the
		// thread function responsible for handling garbage collection.
		// Periodically (on a rate to be determined) the svc thread
		// will wake up and iterate over the list of values. It will
		// "ping" each native reference invoking the _non_existent()
		// method on each. If the result is true, or an exception,
		// the reference will be removed from the map.

		int svc (void);

	protected:
		ACE_UINT32 high_index_;
		ACE_Thread_Mutex high_index_lock_;

	private:
		ACE_Thread_Mutex gc_control_lock_;
		ACE_Condition_Thread_Mutex gc_terminate_;
		time_t gc_period_secs_;
		bool gc_terminated_;

		ACE_UINT32 page_size_;

		struct free_stack_node 
		{
			free_stack_node(ACE_UINT32 x, free_stack_node *n)
				: index_(x),
				  next_(n)
				{
				}

			free_stack_node *pop(void)
				{
					free_stack_node *rtn = this->next_;
					delete this;

					return rtn;
				}

			ACE_UINT32 index_;
			free_stack_node *next_;
		} *free_stack_;

		struct page_list_node 
		{
			page_list_node(ACE_UINT32 size)
				: next_(0)
				{
					page_ = new ReferenceMapValue *[size];
					ACE_OS::memset(page_,0,size * sizeof (ReferenceMapValue *));
				}

			~page_list_node(void)
				{
					delete [] page_;
					if (next_)
						delete next_;
				}

			void add_page(ACE_UINT32 size)
				{
					if (next_ == 0)
						next_ = new page_list_node(size);
					else
						next_->add_page(size);
				}

			ReferenceMapValue **find_page(ACE_UINT32 count)
				{
					return (count == 0) ? this->page_ : next_->find_page(count -1);
				}

			ReferenceMapValue **page_;
			page_list_node *next_;
		} *pages_;

		ACE_UINT32 num_pages_;
	};
}

#endif // RMV_BY_MAPPED_H
