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

# File:	include/drbd/wizards.ycp
# Package:	Configuration of drbd
# Summary:	Wizards definitions
# Authors:	xwhu <xwhu@novell.com>
#
# $Id: wizards.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module DrbdWizardsInclude
    def initialize_drbd_wizards(include_target)
      Yast.import "UI"

      textdomain "drbd"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "drbd/complex.rb"
      Yast.include include_target, "drbd/dialogs.rb"
      Yast.include include_target, "drbd/startup_conf.rb"
      Yast.include include_target, "drbd/global_conf.rb"
      Yast.include include_target, "drbd/resource_conf.rb"
    end

    def TabSequence
      _Aliases = {
        "startup_conf"  => lambda { ConfigureStartUpDialog() },
        "global_conf"   => lambda { ConfigureGlobalDialog() },
        "resource_conf" => lambda { ResourceSequence() }
      }

      anywhere = { :abort => :abort, :next => :next }
      Builtins.foreach(@DIALOG) do |key|
        anywhere = Builtins.add(
          anywhere,
          Builtins.symbolof(Builtins.toterm(key)),
          key
        )
      end

      sequence = { "ws_start" => Ops.get(@DIALOG, 0, "") }
      Builtins.foreach(@DIALOG) do |key|
        sequence = Builtins.add(sequence, key, anywhere)
      end

      # UI initialization
      Wizard.OpenTreeNextBackDialog

      tree = []
      Builtins.foreach(@DIALOG) do |key|
        tree = Wizard.AddTreeItem(
          tree,
          Ops.get_string(@PARENT, key, ""),
          Ops.get_string(@NAME, key, ""),
          key
        )
      end

      Wizard.CreateTree(tree, "DRBD")
      Wizard.SetDesktopTitleAndIcon("drbd")

      # Buttons redefinition
      Wizard.SetNextButton(:next, Label.FinishButton)

      if UI.WidgetExists(Id(:wizardTree))
        Wizard.SetBackButton(:help_button, Label.HelpButton)
        Wizard.SetAbortButton(:abort, Label.CancelButton)
      else
        UI.WizardCommand(term(:SetNextButtonLabel, Label.FinishButton))
        UI.WizardCommand(term(:SetAbortButtonLabel, Label.CancelButton))
        Wizard.HideBackButton
      end

      Wizard.SelectTreeItem(Ops.get_string(sequence, "ws_start", ""))

      ret = Sequencer.Run(_Aliases, sequence)
      Wizard.CloseDialog
      deep_copy(ret)
    end

    def MainSequence
      #    if (Heartbeat::firstrun) {
      #    return FirstRunSequence();
      #    } else {
      #    return TabSequence();
      #    }
      TabSequence()
    end

    def DrbdSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog

      ret = Sequencer.Run(aliases, sequence)

      UI.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of heartbeat but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def DrbdAutoSequence
      # Initialization dialog caption
      caption = _("Heartbeat Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = TabSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
