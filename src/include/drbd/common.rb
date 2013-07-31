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
  module DrbdCommonInclude
    def initialize_drbd_common(include_target)
      textdomain "drbd"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Drbd"
      Yast.import "Popup"
      Yast.import "CWM"

      @DIALOG = ["startup_conf", "global_conf", "resource_conf"]

      @PARENT = {}

      @NAME = {
        "startup_conf"  => _("Start-up Configuration"),
        "global_conf"   => _("Global Configuration"),
        "resource_conf" => _("Resource Configuration")
      }
    end

    def PollAbort
      UI.PollInput == :abort
    end

    def ReallyAbort
      #	    return !Heartbeat::Modified() || Popup::ReallyAbort(true);
      Popup.ReallyAbort(true)
    end

    def my_SetContents(conf, contents)
      contents = deep_copy(contents)
      Wizard.SetContents(
        Ops.add("DRBD - ", Ops.get_string(@NAME, conf, "")),
        contents,
        Ops.get_string(@HELPS, conf, ""),
        true,
        true
      )

      if UI.WidgetExists(Id(:wizardTree))
        #  UI::ChangeWidget(`id(`wizardTree), `CurrentItem, current_dialog);
        UI.SetFocus(Id(:wizardTree))
      end 

      #		if (Heartbeat::firstrun) {
      #			UI::ChangeWidget(`id(`back), `Enabled, conf != "node_conf");
      #			if (conf == "startup_conf") {
      #				UI::WizardCommand(`SetNextButtonLabel( Label::FinishButton() ) );
      #				Wizard::SetNextButton(`PushButton(`id(`next), `opt(`key_F10), Label::FinishButton()));
      #			} else {
      #				UI::WizardCommand(`SetNextButtonLabel( Label::NextButton() ) );
      #				Wizard::SetNextButton(`PushButton(`id(`next), `opt(`key_F10), Label::NextButton()));
      #			}
      #		}

      nil
    end

    def cmpList(a, b)
      a = deep_copy(a)
      b = deep_copy(b)
      same = true
      if Builtins.size(a) != Builtins.size(b)
        same = false 
        #TODO:
      end
      false
    end

    def myHelp(help)
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          VSpacing(16),
          VBox(
            HSpacing(60),
            VSpacing(0.5),
            RichText(Ops.get_string(@HELPS, help, "")),
            VSpacing(1.5),
            PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton)
          )
        )
      )

      UI.SetFocus(Id(:ok))
      UI.UserInput
      UI.CloseDialog

      nil
    end
  end
end
