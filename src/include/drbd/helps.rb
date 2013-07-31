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

# File:	include/drbd/helps.ycp
# Package:	Configuration of drbd
# Summary:	Help texts of all the dialogs
# Authors:	xwhu <xwhu@novell.com>
#
# $Id: helps.ycp 27914 2006-02-13 14:32:08Z locilka $
module Yast
  module DrbdHelpsInclude
    def initialize_drbd_helps(include_target)
      textdomain "drbd"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"        => _(
          "<p><b><big>Initializing DRBD Configuration</big></b><br>\n</p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization:</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"       => _(
          "<p><b><big>Saving DRBD Configuration</big></b><br>\n</p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog informs whether it is safe to do so.\n" +
              "</p>\n"
          ),
        "start_conf"  => _("Start to configure DRBD."),
        "global_conf" => _(
          "<p><b><big>Global Configuration of DRBD</big></b></p>"
        ) +
          _(
            "<p>Check <b>\"Disable IP Verification\"</b> to disable one of drbdadm's sanity check</p>"
          ) +
          _(
            "<p><b>Dialog Refresh:</b> The user dialog counts and displays the seconds it waited so\n" +
              "                far. You might want to disable this if you have the console\n" +
              "                of your server connected to a serial terminal server with\n" +
              "                limited logging capacity.\n" +
              "                The Dialog will print the count each 'dialog-refresh' seconds,\n" +
              "                set it to 0 to disable redrawing completely. </p>"
          ) +
          _(
            "<p><b>Minor Count:</b>\n" +
              "Use this option if you want to define more resources later without reloading the\n" +
              "module. By default we load the module with exactly as many devices as\n" +
              "configured in this file.</p>\n"
          ),
        # Summary dialog help 1/3
        "summary"     => _(
          "<p><b><big>DRBD Configuration</big></b><br>\nConfigure DRBD here.<br></p>\n"
        ) +
          # Summary dialog help 2/3
          _(
            "<p><b><big>Adding a DRBD:</big></b><br>\n" +
              "Choose a DRBD from the list of detected DRBDs.\n" +
              "If your DRBD was not detected, use <b>Other (not detected)</b>.\n" +
              "Then press <b>Configure</b>.</p>\n"
          ) +
          # Summary dialog help 3/3
          _(
            "<p><b><big>Editing or Deleting:</big></b><br>\n" +
              "If you press <b>Edit</b>, an additional dialog in which to change\n" +
              "the configuration opens.</p>\n"
          ),
        # Ovreview dialog help 1/3
        "overview"    => _(
          "<p><b><big>DRBD Configuration Overview</big></b><br>\n" +
            "Obtain an overview of installed DRBDS. Additionally\n" +
            "edit their configurations.<br></p>\n"
        ) +
          # Ovreview dialog help 2/3
          _(
            "<p><b><big>Adding a DRBD:</big></b><br>\nPress <b>Add</b> to configure a DRBD.</p>\n"
          ) +
          # Ovreview dialog help 3/3
          _(
            "<p><b><big>Editing or Deleting:</big></b><br>\n" +
              "Choose a DRBD to change or remove.\n" +
              "Then press <b>Edit</b> or <b>Delete</b> as desired.</p>\n"
          ),
        # Configure1 dialog help 1/2
        "c1"          => _(
          "<p><b><big>Configuration Part One</big></b><br>\n" +
            "Press <b>Next</b> to continue.\n" +
            "<br></p>"
        ) +
          # Configure1 dialog help 2/2
          _(
            "<p><b><big>Selecting Something</big></b><br>\n" +
              "It is not possible. You must code it first. :-)\n" +
              "</p>"
          ),
        # Configure2 dialog help 1/2
        "c2"          => _(
          "<p><b><big>Configuration Part Two</big></b><br>\n" +
            "Press <b>Next</b> to continue.\n" +
            "<br></p>\n"
        ) +
          # Configure2 dialog help 2/2
          _(
            "<p><b><big>Selecting Something</big></b><br>\n" +
              "It is not possible. You must code it first. :-)\n" +
              "</p>"
          )
      } 

      # EOF
    end
  end
end
