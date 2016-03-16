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

      Yast.import "Popup"
      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Service"
      Yast.import "SuSEFirewall"
      Yast.import "SuSEFirewallServices"

      Yast.import "Mode"
      Yast.import "PackageSystem"

      @proposal_valid = false
      @modified = false
      @global_config = {}
      @lvm_config = {}
      @auto_lvm_filter = true
      @resource_config = {}
      @drbd_dir = "/etc"
      @start_daemon = false
      @config_name = {
        "disk_s"  => ["on-io-error", "size", "md-flushes", "al-extents"],
        "syncer"  => ["rate", "al-extents"],
        "net"     => [
          "timeout",
          "connect-int",
          "ping-int",
          "max-buffers",
          "unplug-watermark",
          "max-epoch-size",
          "sndbuf-size",
          "ko-count",
          "protocol",
          "verify-alg"
        ],
        "startup" => ["wfc-timeout", "degr-wfc-timeout"],
        "options" => ["cpu-mask", "on-no-data-accessible"]
      }
      @local_hostname = ""
      @local_ports = []
      @local_disks_ori = []
      @local_disks_added = []

      @global_error = ""
    end

    def prepare_conf_file
      merge_script = Ops.add(
        Ops.add("\n\t\tpushd ", @drbd_dir),
        " > /dev/null 2>&1\n" +
          "\t\tcat drbd.conf | while read line; do\n" +
          "\t\t\ts=`echo $line | awk '{print $1}'`;\n" +
          "\t\t\tif [[ x$s =~ xinclude ]]; then\n" +
          "\t\t\t\tFNAME=`echo $line | sed 's/include//; s/;//g; s/\"//g'`;\n" +
          "\t\t\t\tls $FNAME >/dev/null 2>&1 && cat $FNAME;\n " +
          "\t\t\telse\n" +
          "\t\t\t\techo $line;\n" +
          "\t\t\tfi\n" +
          "\t\tdone > drbd.conf.YaST2prepare \n" +
          "\t\tpopd > /dev/null 2>&1\n" +
          "\t"
      )

      if SCR.Execute(
          path(".target.bash"),
          Ops.add(
            Ops.add("/usr/bin/grep '^[ \t]*include' ", @drbd_dir),
            "/drbd.conf"
          )
        ) == 0
        out = Convert.to_map(
          SCR.Execute(path(".target.bash_output"), merge_script)
        )
        if Ops.get_integer(out, "exit", 0) != 0 ||
            Builtins.size(Ops.get_string(out, "stderr", "")) != 0
          @global_error = Ops.add(
            _("Failed to merge separated DRBD conf files\n"),
            Ops.get_string(out, "stderr", "")
          )
          Builtins.y2error(
            "Failed to merge separated DRBD conf files:\n%1",
            out
          )
          return false
        end
      else
        r = SCR.Execute(
          path(".target.bash"),
          Ops.add(
            Ops.add(
              Ops.add(Ops.add("/bin/cp ", @drbd_dir), "/drbd.conf "),
              @drbd_dir
            ),
            "/drbd.conf.YaST2prepare"
          )
        )
        if r != 0
          Builtins.y2error("Failed to write drbd.conf.YaST2prepare")
          @global_error = _("Failed to write drbd.conf.YaST2prepare")
          return false
        end
      end

      true
    end

    def finding_local(section)
      # Get hostname to find out the local disk/port/IP
      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "echo -n `uname -n|cut -d '.' -f 1`"
        )
      )
      # strip is necessary
      @local_hostname = Ops.get_string(out, "stdout", "")
      Builtins.y2milestone("Local hostname is %1", @local_hostname)

      # Find all disks and ports of local node
      @resource_config.each do |resname, resconfig|
        Builtins.y2debug("Resconf %1 has config %2 ",
          resname, resconfig)

        next if resconfig == nil || resconfig == {}

        resconfig["on"].each do |nodename, conf|
          if @local_hostname == nodename
            if section == "disk"
              disk = conf["disk"]
              Builtins.y2debug("Using local disk %1 for DRBD.", disk)
              if !@local_disks_ori.include?(disk)
                @local_disks_ori.push(disk)
              end

            elsif section == "port"
              port = conf["address"].split(":")[1]
              Builtins.y2debug("Using port %1 for DRBD.", port)
              if !@local_ports.include?(port)
                @local_ports.push(port)
              end
            end

            break
          end
        end

      end

      nil
    end

    def Read
      # DRBD read dialog caption
      caption = _("Initializing DRBD Configuration")

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        5,
        [
          _("Read global settings"),
          _("Read resources"),
          _("Read LVM configurations"),
          _("Read daemon status"),
          _("Read SuSEFirewall Settings")
        ],
        [
          _("Reading global settings..."),
          _("Reading resources..."),
          _("Reading LVM configurations..."),
          _("Reading daemon status..."),
          _("Read SuSEFirewall Settings"),
          _("Finished")
        ],
        ""
      )

      Progress.NextStage

      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "echo -n `uname -r|grep -Eo \"default|smp|bigsmp|desktop|pae|xen|xenpae|debug|ppc64|iseries64\"`"
        )
      )
      krbd_kmp_arch = Ops.get_string(out, "stdout", "default")

      # BSC#939338, change back to use kmp package and drbd-utils for user space
      if !Mode.test &&
          !PackageSystem.CheckAndInstallPackagesInteractive(
            ["drbd", Ops.add("drbd-kmp-", krbd_kmp_arch), "drbd-utils"]
          )
        return false
      end

      if Ops.greater_than(
          SCR.Read(path(".target.size"), Ops.add(@drbd_dir, "/drbd.conf")),
          0
        )
        Builtins.y2milestone("DRBD conf file is %1/drbd.conf", @drbd_dir)

        return false if prepare_conf_file == false

        # 		//merge include file
        # 		if (SCR::Execute(.target.bash, "/usr/bin/grep '^[ \t]*include' " + drbd_dir + "/drbd.conf") == 0)
        # 		{
        # 			if (Popup::YesNo(_("Warning: YaST2 DRBD module will rename all included files ") +
        # 				_(" for DRBD into a supported schema. Do you want to continue?")))
        # 			{
        # 				string merge_script = "
        #                        pushd " + drbd_dir + " > /dev/null 2>&1
        #                        cat drbd.conf | while read line; do
        #                          s=`echo $line | awk '{print $1}'`;
        #                          if [[ x$s =~ xinclude ]]; then
        #                             cat `echo $line | sed 's/include//' | sed 's/;//g' | sed 's/\"//g'`;
        #                          else
        #                             echo $line;
        #                          fi
        #                        done > drbd.conf.YaST2prepare
        #                        popd > /dev/null 2>&1
        # 				";
        # 				map out = (map) SCR::Execute(.target.bash_output, merge_script);
        # 				if (out["exit"]:0 != 0 || size(out["stderr"]:"") != 0)
        # 				{
        # 					y2error("Failed to merge separated configuration files:\n	exit code = %1\n	stderr = %2", out["exit"]:0, out["stderr"]:"");
        # 					Popup::Error(_("Failed to merge separated configuration files."));
        # 					return false;
        # 				}
        # 			}
        # 			else
        # 			{
        # 				return false;
        # 			}
        # 		}
        # 		else
        # 		{
        # 			map out = (map)SCR::Execute(.target.bash, "/bin/cp " + drbd_dir + "/drbd.conf " + drbd_dir + "/drbd.conf.YaST2prepare");
        # 			if (out["exit"]:0 != 0) {
        # 				y2error("Failed to prepare drbd.conf for reading");
        # 				return false;
        # 			}
        # 		}
        #
        # 		map out = (map)SCR::Execute(.target.bash_output, "/bin/mkdir -p " + drbd_dir + "/drbd.d");
        # 		if (out["exit"]:0 != 0) {
        # 			y2error("Failed to prepare the directory for DRBD");
        # 			return false;
        # 		}

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

        #read LVM configs via /etc/lvm/lvm.conf
        #Disable use_lvmetad when using yast drbd to avoid lvmetad
        #in cluster environment, but it may also effect regular usage
        #Manually enable use_lvmetad in this case
        val = Convert.to_string(
            SCR.Read(Builtins.topath(Builtins.sformat(".drbd_lvm.value.global.%1",
                     "use_lvmetad")))
          )
        Ops.set(@lvm_config, "use_lvmetad", val)
        y2debug("drbd_lvm.global.%1 is %2", "use_lvmetad", val)

        #All of them under "devices" section
        ["filter", "write_cache_state", "cache_dir"].each do |key|
          val = Convert.to_string(
            SCR.Read(Builtins.topath(Builtins.sformat(".drbd_lvm.value.devices.%1", key)))
          )
          Ops.set(@lvm_config, key, val)
          Builtins.y2debug("drbd_lvm.devices.%1 is %2", key, val)
        end

        if Ops.get(@lvm_config, "filter") == nil
          # The default value is get from HA doc
          Ops.set(@lvm_config, "filter", "[ \"r|/dev/sda.*|\" ]")
        end
        if Ops.get(@lvm_config, "write_cache_state") == nil
          Ops.set(@lvm_config, "write_cache_state", "0")
        end
        if Ops.get(@lvm_config, "cache_dir") == nil
          Ops.set(@lvm_config, "cache_dir", "/etc/lvm/cache")
        end

        #read resources configs
        res_names = SCR.Dir(Builtins.topath(".drbd.resources"))
        Builtins.foreach(res_names) do |resname|
          config = {}
          res_configs = SCR.Dir(
            Builtins.topath(Builtins.sformat(".drbd.resources.%1", resname))
          )
          # "protocol" should outdate since it move to net section
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
        SCR.Execute(path(".target.bash"), "rm /etc/drbd.conf.YaST2prepare")
        Builtins.y2milestone("DRBD conf file %1/drbd.conf not found", @drbd_dir)
      end

      Builtins.y2milestone("read resource_config=%1", @resource_config)

      # Find all info like disks belong to local node
      finding_local("disk")

      Progress.NextStage
      @start_daemon = Service.Enabled("drbd")

      Progress.NextStage

      # read the SuSEfirewall2
      SuSEFirewall.Read

      # Progress finished
      Progress.NextStage

      Progress.Finish
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

    def restore_yast_save_files
      SCR.Execute(
        path(".target.bash"),
        "/bin/mv /etc/drbd.conf.YaST2save /etc/drbd.conf"
      )
      SCR.Execute(
        path(".target.bash"),
        "/usr/bin/rename .YaST2save '' /etc/drbd.d/*.YaST2save"
      )

      nil
    end

    def validate_configure
      out = {}


      if Ops.less_than(SCR.Read(path(".target.size"), "/etc/drbd.conf"), 0)
        return true
      end

      out = Convert.to_map(
        SCR.Execute(
          path(".target.bash_output"),
          "/bin/cp /etc/drbd.conf /etc/drbd.conf.bak"
        )
      )
      if Ops.get_integer(out, "exit", 0) != 0
        @global_error = _("Failed to backup drbd.conf")
        Builtins.y2error("Failed to backup drbd.conf\n %1", out)
        return false
      end

      out = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), "/bin/echo>/etc/drbd.conf")
      )
      if Ops.get_integer(out, "exit", 0) != 0
        @global_error = _("Failed to clean drbd.conf for drbdadm test")
        Builtins.y2error("Failed to clean drbd.conf for drbdadm test\n%1", out)
        return false
      end

      Builtins.y2milestone("drbdadm res=%1", @resource_config)
      r = Builtins.foreach(
        Convert.convert(
          @resource_config,
          :from => "map",
          :to   => "map <string, any>"
        )
      ) do |key, val|
        out = Convert.to_map(
          SCR.Execute(
            path(".target.bash_output"),
            Ops.add(
              Ops.add("/sbin/drbdadm -t /etc/drbd.d/", key),
              ".res sh-nop"
            )
          )
        )
        if Ops.get_integer(out, "exit", 0) != 0
          @global_error = Builtins.sformat(
            _("Invalid configuration of resource %1\n%2"),
            key,
            Ops.get_string(out, "stderr", "")
          )
          Builtins.y2error("Invalid configuration of resource %1\n%2", key, out)
          next false
        end
      end

      return false if r == false

      if Ops.greater_or_equal(
          SCR.Read(path(".target.size"), "/etc/drbd.conf.bak"),
          0
        ) &&
          SCR.Execute(
            path(".target.bash"),
            "/bin/mv /etc/drbd.conf.bak /etc/drbd.conf"
          ) != 0
        @global_error = _("Failed to bring drbd.conf back")
        Builtins.y2error("Failed to bring drbd.conf back")
        return false
      end

      true
    end

    def format_lvm_filter()
      Builtins.y2milestone("Change LVM filter automatically.")

      filter_list = []
      r_format = "\"r|%s|\""
      reject_list = [ "\"r|/dev/block/.*|\"", "\"r|/dev/.*/by-path/.*|\"",
                      "\"r|/dev/.*/by-id/.*|\"" ]
      filter_ori = Ops.get(@lvm_config, "filter").to_s.strip()
      Builtins.y2debug("Original filter is %1", filter_ori)

      # Remove the [] and convert string to list to check
      temp_length = filter_ori.length - 2
      if temp_length < 1
        # Should at least including "[]"
        filter_str = ""
      else
        filter_str = filter_ori[1,temp_length]
      end

      filter_list_tmp = filter_str.split(",")

      # Remove the extra space in filter field
      # [].push is FIFO, insert(0,x) is stack
      filter_list_tmp.each do |field|
        filter_list.push(field.strip())
      end

      reject_list.each do |regular|
        if !filter_list.include?(regular)
          filter_list.insert( 0, regular )
        end
      end
      Builtins.y2debug("Temp filter list is %1", filter_list)

      @local_disks_added.each do |newdisk|
        # Reject always need to be added in the first
        filter_list.insert( 0, r_format % newdisk )
      end

      filters = "[ " + filter_list.join(", ") + " ]"
      Builtins.y2debug("Modified filter is %1", filters)
      Ops.set(@lvm_config, "filter", filters)

      nil
    end

    def Write
      # DRBD write dialog caption
      caption = _("Writing DRBD Configuration")

      # Comment code below due to change the "booting" status
      # won't change modified flag
      #return true if !@modified

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        5,
        [
          _("Write global settings"),
          _("Write resources"),
          _("Write LVM configurations"),
          _("Set daemon status"),
          _("Write the SuSEfirewall settings")
        ],
        [
          _("Writing global settings..."),
          _("Writing resources..."),
          _("Writing LVM configurations..."),
          _("Setting daemon status..."),
          _("Writing the SuSEFirewall settings"),
          _("Finished")
        ],
        ""
      )


      if SCR.Execute(
          path(".target.bash"),
          Ops.add(Ops.add("/bin/mkdir -p ", @drbd_dir), "/drbd.d")
        ) != 0
        @global_error = _("Failed to make directory /etc/drbd.d")
        Builtins.y2error("Failed to make directory /etc/drbd.d")
        return false
      end

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

      #LVM config here
      #http://docserv.suse.de/documents/SLE-HA11/SLE-ha-nfs-quick/html/
      #art_ha_quick_nfs.html#sec_ha_quick_nfs_initial_lvm_config
      Progress.NextStage
      Builtins.y2debug(
        "to write lvm config: lvm_config=%1",
        @lvm_config
      )

      # Change(add reject rules) filter automatically
      if @auto_lvm_filter && !@local_disks_added.empty?
        format_lvm_filter
      end

      ["filter", "write_cache_state"].each do |key|
        if Ops.get(@lvm_config, key) != nil
          SCR.Write(
            Builtins.topath(Builtins.sformat(".drbd_lvm.value.devices.%1", key)),
            Ops.get(@lvm_config, key)
          )
        end
      end

      if Ops.get(@lvm_config, "use_lvmetad") != nil
        SCR.Write(
          Builtins.topath(Builtins.sformat(".drbd_lvm.value.global.%1", "use_lvmetad")),
          Ops.get(@lvm_config, "use_lvmetad")
        )
      end

      if Ops.get(@lvm_config, "write_cache_state") == "0"
        SCR.Execute(
          path(".target.bash"),
          Builtins.sformat("/bin/rm -r %1/.cache >/dev/null 2>&1",
          Ops.get(@lvm_config, "cache_dir"))
        )
      end

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

      if validate_configure == false
        restore_yast_save_files
        return false
      end

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

      # open all local ports
      finding_local("port")

      # DRBD only use TCP port
      SuSEFirewallServices.SetNeededPortsAndProtocols(
        "service:drbd",
        { "tcp_ports" => @local_ports }
      )

      SuSEFirewall.Write

      # Progress finished
      Progress.NextStage
      Progress.Finish
      true
    end

    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :modified, :type => "boolean"
    publish :variable => :global_config, :type => "map"
    publish :variable => :lvm_config, :type => "map"
    publish :variable => :auto_lvm_filter, :type => "boolean"
    publish :variable => :resource_config, :type => "map"
    publish :variable => :drbd_dir, :type => "string"
    publish :variable => :start_daemon, :type => "boolean"
    publish :variable => :config_name, :type => "map <string, list <string>>"
    publish :variable => :local_hostname, :type => "string"
    publish :variable => :local_ports, :type => "list <string>"
    publish :variable => :local_disks_ori, :type => "list <string>"
    publish :variable => :local_disks_added, :type => "list <string>"
    publish :variable => :global_error, :type => "string"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
  end

  Drbd = DrbdClass.new
  Drbd.main
end
