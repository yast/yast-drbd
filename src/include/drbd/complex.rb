# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/drbd/complex.ycp
# Package:	Configuration of drbd
# Summary:	Dialogs definitions
# Authors:	xwhu <xwhu@novell.com>
#
# $Id: complex.ycp 29363 2006-03-24 08:20:43Z mzugec $
module Yast
  module DrbdComplexInclude
    def initialize_drbd_complex(include_target)

      textdomain "drbd"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Wizard"
      Yast.import "Confirm"
      Yast.import "Drbd" 


      #include "drbd/helps.ycp";
    end
  end
end
