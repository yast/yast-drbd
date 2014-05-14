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
      Yast.import "Popup"

      Yast.include include_target, "drbd/helps.rb"
      Yast.include include_target, "drbd/common.rb"
    end

    def update_conf_warning
      if Ops.greater_than(SCR.Read(path(".target.size"), "/etc/drbd.conf"), 0)
        if SCR.Execute(
            path(".target.bash"),
            "/usr/bin/grep '# YaST2 created seperated configuration file' /etc/drbd.conf"
          ) != 0
          return Popup.YesNo(
            _("Warning: YaST2 DRBD module will rename all\n") +
              _(
                "included files for DRBD into a supported schema.\n" +
                  "\n" +
                  "Do you want to continue?"
              )
          )
        end
      end
      true
    end

    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      ret = Drbd.Read
      if ret == false
        Popup.Error(
          Ops.add(
            _("Failed to read DRBD configuration file:\n"),
            Drbd.global_error
          )
        )
      end

      return :abort if update_conf_warning == false

      ret ? :next : :abort
    end

    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      ret = Drbd.Write
      if ret == false
        Popup.Error(
          Ops.add(
            _("Failed to write configuration to disk:\n"),
            Drbd.global_error
          )
        )
      end
      ret ? :next : :main
    end


    # Configure1 dialog
    # @return dialog result
    def Configure1Dialog
      # Drbd configure1 dialog caption
      caption = _("DRBD Configuration")

      # Drbd configure1 dialog contents
      contents = Label(_("First part of configuration of DRBD"))

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
      contents = Label(_("Second part of configuration of DRBD"))

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
