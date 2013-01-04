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

#include "defines/build-system-defs.h"

#include "ReferenceMapValue.h"

Lorica::ReferenceMapValue::ReferenceMapValue(void)
	: ref_count_(1)
{
}

Lorica::ReferenceMapValue::~ReferenceMapValue(void)
{
}

void
Lorica::ReferenceMapValue::incr_refcount(void)
{
	++this->ref_count_;
}

long
Lorica::ReferenceMapValue::decr_refcount(void)
{
	if (--this->ref_count_ > 0)
		return this->ref_count_;

	ACE_ASSERT(this->ref_count_ == 0);

	delete this;

	return 0;
}

Lorica::ReferenceMapValue *
Lorica::ReferenceMapValue::reverse(void)
{
	Lorica::ReferenceMapValue *rtn = new Lorica::ReferenceMapValue();

	rtn->orig_ref_ = this->mapped_ref_;
	rtn->mapped_ref_ = this->orig_ref_;
	rtn->ior_table_name_ = "";
	rtn->require_secure_ = this->require_secure_;
	rtn->agent_ = Lorica::ServerAgent::_nil();

	return rtn;
}

long
Lorica::ReferenceMapValue::refcount(void) const
{
	return this->ref_count_;
}

Lorica::ReferenceMapValue_var::
ReferenceMapValue_var(ReferenceMapValue *rmv)
	: ptr_(rmv)
{
}

Lorica::ReferenceMapValue_var::
ReferenceMapValue_var(void)
	: ptr_(0)
{
}

Lorica::ReferenceMapValue_var::
ReferenceMapValue_var(const ReferenceMapValue_var & rmv)
	: ptr_(rmv.ptr_)
{
	if (this->ptr_ != 0)
		this->ptr_->incr_refcount();
}

Lorica::ReferenceMapValue_var::~ReferenceMapValue_var(void)
{
	if (this->ptr_ != 0)
		this->ptr_->decr_refcount();
}


Lorica::ReferenceMapValue_var &
Lorica::ReferenceMapValue_var::operator= (const ReferenceMapValue_var & rmv)
{
	if (this->ptr_ != 0)
		this->ptr_->decr_refcount();
	this->ptr_ = rmv.ptr_;
	if (this->ptr_ != 0)
		this->ptr_->incr_refcount();

	return *this;
}

Lorica::ReferenceMapValue_var &
Lorica::ReferenceMapValue_var::operator= (ReferenceMapValue *rmv)
{
	this->set(rmv);

	return *this;
}

void
Lorica::ReferenceMapValue_var::set(ReferenceMapValue *rmv)
{
	if (this->ptr_ != 0)
		this->ptr_->decr_refcount();
	this->ptr_ = rmv;
}

Lorica::ReferenceMapValue *&
Lorica::ReferenceMapValue_var::out(void)
{
	if (this->ptr_ != 0)
		this->ptr_->decr_refcount();
	this->ptr_ = 0;

	return this->ptr_;
}

Lorica::ReferenceMapValue *&
Lorica::ReferenceMapValue_var::inout(void)
{
	return this->ptr_;
}

const Lorica::ReferenceMapValue*
Lorica::ReferenceMapValue_var::in(void) const
{
	return this->ptr_;
}

Lorica::ReferenceMapValue*
Lorica::ReferenceMapValue_var::get(void) const
{
	return this->ptr_;
}

Lorica::ReferenceMapValue*
Lorica::ReferenceMapValue_var::release(void)
{
	ReferenceMapValue* rmv = this->ptr_;
	this->ptr_ = 0;
	return rmv;
}

const Lorica::ReferenceMapValue *
Lorica::ReferenceMapValue_var::operator-> (void) const
{
	return this->ptr_;
}

Lorica::ReferenceMapValue *
Lorica::ReferenceMapValue_var::operator-> (void)
{
	return this->ptr_;
}
