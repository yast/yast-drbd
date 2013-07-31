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

# File:	modules/Drbd.ycp
# Package:	Configuration of drbd
# Summary:	Drbd settings, input and output functions
# Authors:	xwhu <xwhu@novell.com>
#
# $Id: Drbd.ycp 27914 2006-02-13 14:32:08Z locilka $
#
# Representation of the configuration of drbd.
# Input and output routines.
require "yast"

module Yast
  class DrbdClass < Module
    def main
      textdomain "drbd"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Service"

      Yast.import "Mode"
      Yast.import "PackageSystem"

      @proposal_valid = false
      @modified = false
      @global_config = {}
      @resource_config = {}
      @drbd_dir = "/etc"
      @start_daemon = false
      @config_name = {
        "disk_s"  => ["on-io-error", "size"],
        "syncer"  => ["rate", "al-extents"],
        "net"     => [
          "timeout",
          "connect-int",
          "ping-int",
          "max-buffers",
          "unplug-watermark",
          "max-epoch-size",
          "sndbuf-size",
          "ko-count"
        ],
        "startup" => ["wfc-timeout", "degr-wfc-timeout"]
      }
    end

    def Read
      # DRBD read dialog caption
      caption = _("Initializing DRBD Configuration")

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        4,
        [
          _("Read global settings"),
          _("Read resources"),
          _("Read daemon status")
        ],
        [
          _("Reading global settings..."),
          _("Reading resources..."),
          _("Reading daemon status..."),
          _("Finished")
        ],
        ""
      )

      Progress.NextStage

      # check installed packages
      # find out which krbd-kmp-<arch> to be installed
      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "echo -n `uname -r|grep -Eo \"default|smp|bigsmp|pae|xen|xenpae|debug|ppc64|iseries64\"`"
        )
      )
      krbd_kmp_arch = Ops.get_string(out, "stdout", "default")

      if !Mode.test &&
          !PackageSystem.CheckAndInstallPackagesInteractive(
            ["drbd", Ops.add("drbd-kmp-", krbd_kmp_arch)]
          )
        return false
      end

      if Ops.greater_than(
          SCR.Read(path(".target.size"), Ops.add(@drbd_dir, "/drbd.conf")),
          0
        )
        Builtins.y2milestone("read drbd conf file: %1", @drbd_dir)

        #read global configs
        Builtins.foreach(
          ["disable-ip-verification", "minor-count", "dialog-refresh"]
        ) do |key|
          val = Convert.to_string(
            SCR.Read(Builtins.topath(Builtins.sformat(".drbd.global.%1", key)))
          )
          Ops.set(@global_config, key, val)
        end
        if Ops.get(@global_config, "minor-count") == nil
          Ops.set(@global_config, "minor-count", "5")
        end
        if Ops.get(@global_config, "dialog-refresh") == nil
          Ops.set(@global_config, "dialog-refresh", "1")
        end

        #read resources configs
        res_names = SCR.Dir(Builtins.topath(".drbd.resources"))
        Builtins.foreach(res_names) do |resname|
          config = {}
          res_configs = SCR.Dir(
            Builtins.topath(Builtins.sformat(".drbd.resources.%1", resname))
          )
          Builtins.foreach(["protocol"]) do |resconf|
            if Builtins.contains(res_configs, resconf)
              val = Convert.to_string(
                SCR.Read(
                  Builtins.topath(
                    Builtins.sformat(".drbd.resources.%1.%2", resname, resconf)
                  )
                )
              )
              Ops.set(config, resconf, val)
            end
          end
          Builtins.foreach(@config_name) do |r, l|
            if Builtins.contains(res_configs, r)
              cf = {}
              Builtins.foreach(l) do |k|
                v = Convert.to_string(
                  SCR.Read(
                    Builtins.topath(
                      Builtins.sformat(
                        ".drbd.resources.%1.%2.%3",
                        resname,
                        r,
                        k
                      )
                    )
                  )
                )
                if v != nil
                  Ops.set(cf, k, v)
                  Builtins.y2debug("%1 %2 %3 is %4", resname, r, k, v)
                end
              end
              Ops.set(config, r, cf) if Ops.greater_than(Builtins.size(cf), 0)
            end
          end
          if Builtins.contains(res_configs, "on")
            nodes = SCR.Dir(
              Builtins.topath(
                Builtins.sformat(".drbd.resources.%1.on", resname)
              )
            )
            nodescf = {}
            Builtins.foreach(nodes) do |n|
              nodecf = {}
              Builtins.foreach(["device", "disk", "meta-disk", "address"]) do |k|
                v = Convert.to_string(
                  SCR.Read(
                    Builtins.topath(
                      Builtins.sformat(
                        ".drbd.resources.%1.on.%2.%3",
                        resname,
                        n,
                        k
                      )
                    )
                  )
                )
                if v != nil
                  Ops.set(nodecf, k, v)
                  Builtins.y2debug("%1 on %2 %3 is %4", resname, n, k, v)
                end
              end
              if Ops.greater_than(Builtins.size(nodecf), 0)
                Ops.set(nodescf, n, nodecf)
              end
            end
            if Ops.greater_than(Builtins.size(nodescf), 0)
              Ops.set(config, "on", nodescf)
            end
          end
          if Ops.greater_than(Builtins.size(config), 0)
            Ops.set(@resource_config, resname, config)
          end
        end
      else
        Builtins.y2milestone("drbd conf file %1 not found", @drbd_dir)
      end

      Builtins.y2milestone("resource_config=%1", @resource_config)

      Progress.NextStage
      @start_daemon = Service.Enabled("drbd")

      Progress.NextStage

      @modified = false
      true
    end

    def recursive_write_map(cur_path, the_map)
      the_map = deep_copy(the_map)
      Builtins.foreach(the_map) do |key, val|
        if Ops.is_map?(val) && val != nil
          SCR.Write(Builtins.add(cur_path, key), nil)
          recursive_write_map(
            Builtins.add(cur_path, key),
            Convert.convert(val, :from => "any", :to => "map <string, any>")
          )
        else
          Builtins.y2debug(
            "write conf file: %1=%2",
            Builtins.add(cur_path, key),
            val
          )
          SCR.Write(Builtins.add(cur_path, key), val)
        end
      end

      nil
    end


    def del_empty_item(old_map)
      old_map = deep_copy(old_map)
      new_map = deep_copy(old_map)
      Builtins.foreach(
        Convert.convert(old_map, :from => "map", :to => "map <string, any>")
      ) do |key, val|
        if Ops.is_map?(val)
          Ops.set(new_map, key, del_empty_item(Convert.to_map(val))) #if (is(val, string))
        else
          if Builtins.size(Convert.to_string(val)) == 0
            Ops.set(new_map, key, nil)
          end 
          #new_map = remove(new_map, key);
        end
      end

      deep_copy(new_map)
    end


    def Write
      # DRBD write dialog caption
      caption = _("Writing DRBD Configuration")

      #if (!modified) return true;

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        4,
        [
          _("Write global settings"),
          _("Write resources"),
          _("Set daemon status")
        ],
        [
          _("Writing global settings..."),
          _("Writing resources..."),
          _("Setting daemon status..."),
          _("Finished")
        ],
        ""
      )

      #global config here
      Progress.NextStage
      Builtins.y2debug(
        "to write global config: global_config=%1",
        @global_config
      )
      Builtins.foreach(
        ["disable-ip-verification", "minor-count", "dialog-refresh"]
      ) do |key|
        if Ops.get(@global_config, key) != nil
          SCR.Write(
            Builtins.topath(Builtins.sformat(".drbd.global.%1", key)),
            Ops.get(@global_config, key)
          )
        end
      end
      Builtins.sleep(100)


      #resource config here
      Progress.NextStage
      @resource_config = del_empty_item(@resource_config)
      recursive_write_map(
        path(".drbd.resources"),
        Convert.convert(
          @resource_config,
          :from => "map",
          :to   => "map <string, any>"
        )
      )
      Builtins.y2debug(
        "to write resource config: resource_config=%1",
        @resource_config
      )

      SCR.Write(Builtins.topath(".drbd"), "")
      Builtins.sleep(100)


      Progress.NextStage
      if @start_daemon
        Service.Enable("drbd")
        if Service.Status("drbd") == 0
          Service.Restart("drbd")
        else
          Service.Start("drbd")
        end
      else
        Service.Disable("drbd")
        Service.Stop("drbd")
      end
      Progress.NextStage

      true
    end

    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :global_config, :type => "map"
    publish :variable => :resource_config, :type => "map"
    publish :variable => :drbd_dir, :type => "string"
    publish :variable => :start_daemon, :type => "boolean"
    publish :variable => :config_name, :type => "map <string, list <string>>"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
  end

  Drbd = DrbdClass.new
  Drbd.main
end
