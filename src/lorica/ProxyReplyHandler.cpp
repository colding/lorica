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

#include "ProxyMapper.h"
#include "EvaluatorBase.h"
#include "ProxyReplyHandler.h"
#include "debug.h"

#include <tao/AnyTypeCode/NVList.h>
#include <tao/AnyTypeCode/Any_Impl.h>
#include <tao/SystemException.h>


Lorica::ProxyReplyHandler::ProxyReplyHandler(ProxyMapper & pm,
					     const char *operation,
					     PortableServer::POA_ptr poa,
					     const Lorica::EvaluatorBase *eval,
					     CORBA::NVList_ptr out_args,
					     CORBA::NamedValue_ptr result,
					     TAO_AMH_DSI_Response_Handler_ptr resp)
	: mapper_(pm),
	  operation_(operation),
	  poa_ (PortableServer::POA::_duplicate(poa)),
	  evaluator_(eval),
	  out_args_(out_args), // take ownership of the param
	  result_(result), // take ownership of this too
	  response_handler_(TAO_AMH_DSI_Response_Handler::_duplicate(resp))
{
}

Lorica::ProxyReplyHandler::~ProxyReplyHandler(void)
{
}


// The code that actually processes the request message
void
Lorica::ProxyReplyHandler::handle_response_i(TAO_InputCDR & incoming)
{
	try {
		bool lazy_evaluation = true;

		if (this->result_)
			this->result_->value()->impl()->_tao_decode(incoming);

		if ((this->out_args_.ptr() == 0)
		    && (Lorica_debug_level > 0))
			ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%T) %N:%l - out args is null!\n")));
		else
			this->out_args_->_tao_incoming_cdr(incoming,
							   CORBA::ARG_OUT | CORBA::ARG_INOUT,
							   lazy_evaluation);
		PortableServer::POA_var op = mapper_.other_POA(poa_.in());
		this->evaluator_->evaluate_reply(this->operation_.c_str(),
						 op.in(),
						 this->out_args_.in(),
						 this->result_.in());
	}
	catch (CORBA::SystemException & ex) {
		TAO_AMH_DSI_Exception_Holder h(&ex);
		response_handler_->invoke_excep(&h);
	}
	catch (...) {
		ACE_ERROR((LM_ERROR,
			   "%N:%l - unknown exception\n"));
		CORBA::UNKNOWN ex;
		TAO_AMH_DSI_Exception_Holder h(&ex);
		response_handler_->invoke_excep(&h);
	}

	if (!CORBA::is_nil (response_handler_.in())) {
		response_handler_->invoke_reply (this->out_args_.in(),
						 this->result_.in());
	}
}

void
Lorica::ProxyReplyHandler::handle_excep_i(TAO_InputCDR & incoming,
					  CORBA::ULong reply_status)
{
	TAO_InputCDR for_reading (incoming);
	CORBA::String_var id;
	if ((for_reading >> id.inout()) == 0) {
		CORBA::MARSHAL ex(0,CORBA::COMPLETED_MAYBE);
		TAO_AMH_DSI_Exception_Holder h(&ex);
		response_handler_->invoke_excep(&h);

		return;
	}

	if (Lorica_debug_level > 0)
		ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%T) %N:%l - id = %s\n"), id.in()));

	if (reply_status == TAO_AMI_REPLY_USER_EXCEPTION) {
		TAO_OutputCDR encap;
		this->evaluator_->evaluate_exception(this->operation_.c_str(),
						     this->poa_.in(),
						     id.in(),
						     incoming,
						     encap);

		response_handler_->gateway_exception_reply(reply_status, encap);

		return;
	} else if (reply_status == TAO_AMI_REPLY_SYSTEM_EXCEPTION) {
		CORBA::ULong minor = 0;
		CORBA::ULong completion = 0;

		if (((for_reading >> minor) == 0)
		    || ((for_reading >> completion) == 0)) {
			CORBA::MARSHAL ex(0,CORBA::COMPLETED_MAYBE);
			TAO_AMH_DSI_Exception_Holder h(&ex);
			response_handler_->invoke_excep(&h);
			return;
		}

		if (Lorica_debug_level > 0) {
			ACE_DEBUG((LM_DEBUG,
				   ACE_TEXT("(%T) %N:%l - Got system exception: %s, minor = %d, completed = %d\n"),
				   id.in(),
				   minor,
				   completion));
		}

		CORBA::SystemException * ex = TAO::create_system_exception(id.in());

		ex->minor(minor);
		ex->completed (CORBA::CompletionStatus(completion));

		TAO_AMH_DSI_Exception_Holder h(ex);
		response_handler_->invoke_excep(&h);
		delete ex;
	} else {
		if (Lorica_debug_level > 0)
			ACE_DEBUG((LM_DEBUG, ACE_TEXT("(%T) %N:%l - ignoring reply_status %ul\n"), reply_status));
	}
}


void
Lorica::ProxyReplyHandler::handle_location_forward_i(TAO_InputCDR & incoming,
						     CORBA::ULong reply_status)
{
	TAO_InputCDR for_reading(incoming);
	CORBA::Object_var fwd;

	if ((for_reading >> fwd) == 0) {
		TAO_AMH_DSI_Exception_Holder h(new CORBA::MARSHAL(0, CORBA::COMPLETED_MAYBE));
		response_handler_->invoke_excep(&h);

		return;
	}

	PortableServer::POA_var op = mapper_.other_POA(poa_.in());
	if (!mapper_.mapped_for_native(fwd.inout(),op.in())) {
		TAO_AMH_DSI_Exception_Holder h(new CORBA::MARSHAL(0, CORBA::COMPLETED_MAYBE));
		response_handler_->invoke_excep(&h);

		return;
	}

	bool is_perm = reply_status == TAO_AMI_REPLY_LOCATION_FORWARD_PERM;
	response_handler_->invoke_location_forward(fwd, is_perm);

	return;
}
