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

# File:	include/drbd/dialogs.ycp
# Package:	Configuration of drbd
# Summary:	Dialogs definitions
# Authors:	xwhu <xwhu@novell.com>
#
# $Id: dialogs.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module DrbdDialogsInclude
    def initialize_drbd_dialogs(include_target)
      Yast.import "UI"

      textdomain "drbd"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Drbd"

      Yast.include include_target, "drbd/helps.rb"
      Yast.include include_target, "drbd/common.rb"
    end

    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      ret = Drbd.Read
      ret ? :next : :abort
    end

    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      ret = Drbd.Write
      ret ? :next : :abort
    end


    # Configure1 dialog
    # @return dialog result
    def Configure1Dialog
      # Drbd configure1 dialog caption
      caption = _("DRBD Configuration")

      # Drbd configure1 dialog contents
      contents = Label(_("First part of DRBD configuration"))

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "c1", ""),
        Label.BackButton,
        Label.NextButton
      )

      ret = nil
      while true
        ret = UI.UserInput

        # abort?
        if ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next || ret == :back
          break
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      deep_copy(ret)
    end

    # Configure2 dialog
    # @return dialog result
    def Configure2Dialog
      # Drbd configure2 dialog caption
      caption = _("DRBD Configuration")

      # Drbd configure2 dialog contents
      contents = Label(_("Second part of DRBD configuration"))

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "c2", ""),
        Label.BackButton,
        Label.NextButton
      )

      ret = nil
      while true
        ret = UI.UserInput

        # abort?
        if ret == :abort || ret == :cancel
          if ReallyAbort()
            break
          else
            next
          end
        elsif ret == :next || ret == :back
          break
        else
          Builtins.y2error("unexpected retcode: %1", ret)
          next
        end
      end

      deep_copy(ret)
    end
  end
end
