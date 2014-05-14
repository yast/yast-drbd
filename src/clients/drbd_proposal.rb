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

# File:	clients/drbd_proposal.ycp
# Package:	Configuration of drbd
# Summary:	Proposal function dispatcher.
# Authors:	xwhu <xwhu@novell.com>
#
# $Id: drbd_proposal.ycp 27914 2006-02-13 14:32:08Z locilka $
#
# Proposal function dispatcher for drbd configuration.
# See source/installation/proposal/proposal-API.txt
module Yast
  class DrbdProposalClient < Client
    def main

      textdomain "drbd"

      Yast.import "Drbd"
      Yast.import "Progress"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("DRBD proposal started")

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # create a textual proposal
      if @func == "MakeProposal"
        @proposal = ""
        @warning = nil
        @warning_level = nil
        @force_reset = Ops.get_boolean(@param, "force_reset", false)

        if @force_reset || !Drbd.proposal_valid
          Drbd.proposal_valid = true
          @progress_orig = Progress.set(false)
          Drbd.Read
          Progress.set(@progress_orig)
        end
        #FIXME: implement Drbd::Summary
        #list sum = Drbd::Summary();
        @sum = []
        @proposal = Ops.get_string(@sum, 0, "")

        @ret = {
          "preformatted_proposal" => @proposal,
          "warning_level"         => @warning_level,
          "warning"               => @warning
        }
      # run the module
      elsif @func == "AskUser"
        #     map stored = Drbd::Export();
        #     symbol seq = (symbol) WFM::CallFunction("drbd", [.propose]);
        #     if(seq != `next) Drbd::Import(stored);
        #     y2debug("stored=%1",stored);
        #     y2debug("seq=%1",seq);
        #     ret = $[
        # "workflow_sequence" : seq
        #     ];
        @ret = {}
      # create titles
      elsif @func == "Description"
        @ret = {
          # Rich text title for Drbd in proposals
          "rich_text_title" => _("DRBD"),
          # Menu title for Drbd in proposals
          "menu_title"      => _("&DRBD"),
          "id"              => "drbd"
        }
      # write the proposal
      elsif @func == "Write"
        Drbd.Write
      else
        Builtins.y2error("unknown function: %1", @func)
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("DRBD proposal finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::DrbdProposalClient.new.main
