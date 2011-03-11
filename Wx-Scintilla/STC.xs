/////////////////////////////////////////////////////////////////////////////
// Name:        ext/stc/STC.xs
// Purpose:     XS for Wx::STC
// Author:      Mattia Barbon
// Modified by:
// Created:     23/05/2002
// RCS-ID:      $Id: STC.xs 2935 2010-07-04 11:46:58Z mbarbon $
// Copyright:   (c) 2002-2004, 2006-2010 Mattia Barbon
// Licence:     This program is free software; you can redistribute it and/or
//              modify it under the same terms as Perl itself
/////////////////////////////////////////////////////////////////////////////

#define PERL_NO_GET_CONTEXT

#include "cpp/wxapi.h"

#undef THIS

MODULE=Wx__STC

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t ../../typemap.xsp XS/StyledTextCtrl.xsp

INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- -t ../../typemap.xsp XS/StyledTextEvent.xsp

#include "cpp/st_constants.cpp"

#  //FIXME//tricky
#if defined(__WXMSW__)
#undef XS
#define XS( name ) WXXS( name )
#endif

MODULE=Wx__STC
