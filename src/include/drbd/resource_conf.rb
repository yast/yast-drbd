# encoding: utf-8

module Yast
  module DrbdResourceConfInclude
    def initialize_drbd_resource_conf(include_target)
      Yast.import "UI"

      textdomain "drbd"

      Yast.import "Popup"
      Yast.import "Sequencer"
      Yast.import "Report"
      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Service"
      Yast.import "IP"
      Yast.import "Drbd"

      Yast.include include_target, "drbd/helps.rb"
      Yast.include include_target, "drbd/common.rb"
    end

    def res_list_get_dialog
      table_items = []

      Builtins.foreach(
        Convert.convert(
          Drbd.resource_config,
          :from => "map",
          :to   => "map <string, map <string, any>>"
        )
      ) do |resname, resconfig|
        next if Ops.get(Drbd.resource_config, resname) == nil
        node_number = 0
        items = Item(Id(resname))
        items = Builtins.add(items, resname)
        Builtins.foreach(Ops.get_map(resconfig, "on", {})) do |nodename, nodeconfig|
          node_number += 1
          if node_number > 2
            items = Builtins.add(items, "...")
            break
          end
          items = Builtins.add(items, nodename)
        end
        table_items = Builtins.add(table_items, items)
      end

      VBox(
        Opt(:hvstretch),
        VBox(
          Opt(:hvstretch),
          Table(
            Id(:res_list_table),
            Header("Resource      ", "Node-1       ", "Node-2       ", "More...       "),
            table_items
          )
        ),
        Left(
          HBox(
            PushButton(Id(:add), "Add"),
            PushButton(Id(:edit), "Edit"),
            PushButton(Id(:delete), "Delete")
          )
        )
      )
    end

    def resource_conf_Write
      true
    end

    def ResListDialog
      my_SetContents("resource_conf", res_list_get_dialog)

      ret = nil
      while true
        Wizard.SelectTreeItem("resource_conf")

        hasRes = false

        Drbd.resource_config.each do |resname, conf|
          next if Ops.get(Drbd.resource_config, resname) == nil
          hasRes = true
          break
        end

        UI.ChangeWidget(Id(:edit), :Enabled, hasRes)
        UI.ChangeWidget(Id(:delete), :Enabled, hasRes)

        ret = UI.UserInput

        Builtins.y2debug("on ResListDialog(), UserInput ret=%1", ret)

        if ret == :help
          myHelp("global_conf")
          next
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if ret == "resource_conf" || ret == "DialogRefresh" ||
            ret == "MinorCount" ||
            ret == "DisableIpVerification"
          next
        end

        if ret == :delete
          resname = Convert.to_string(
            UI.QueryWidget(Id(:res_list_table), :CurrentItem)
          )
          Ops.set(Drbd.resource_config, Builtins.sformat("%1", resname), nil)
          ret = :list
          break
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :next || ret == :back || ret == :edit || ret == :add ||
            Builtins.contains(@DIALOG, Builtins.tostring(ret))
          next if !resource_conf_Write

          if ret != :next && ret != :back && ret != :edit && ret != :add
            ret = Builtins.symbolof(Builtins.toterm(ret))
          end

          break
        end
      end
      deep_copy(ret)
    end

    def res_basic_config_get_dialog(resname)
      VBox(
        TextEntry(
          Id(:resname),
          _("Resource Name"),
          resname
        ),
        Frame(
          "Nodes Configurations",
          HBox(
            VBox(
              SelectionBox(Id(:node_box), _("Nodes")),
              Left(
                HBox(
                  PushButton(Id(:node_add), _("Add")),
                  PushButton(Id(:node_edit), _("Edit")),
                  PushButton(Id(:node_del), _("Delete"))
                )
              )
            ),
            VBox(
              MarginBox(
                1,
                1,
                Frame(
                  "Node",
                  VBox(
                    TextEntry(Id(:n_name), "Name"),
                    TextEntry(
                      Id(:n_addr),
                      "Address:Port"
                    ),
                    TextEntry(
                      Id(:n_devc),
                      "Device"
                    ),
                    TextEntry(
                      Id(:n_disk),
                      "Disk"
                    ),
                    TextEntry(
                      Id(:n_meta),
                      "Meta-disk"
                    )
                  )
                )
              ),
              Right(
                PushButton(Id(:node_save), _("Save")),
              )
            )
          )
        ),
        VStretch(),
        Bottom(
          HBox(
            PushButton(Id(:advance), "Advanced Config"),
            PushButton(Id(:cancel_inner), "Ca&ncel"),
            PushButton(Id(:ok), "OK")
          )
        )
      )
    end

    def update_add_disk_list(node_list)
      # Update new add disk used of drbd res for LVM filter
      # Ignore the removed disk
      disk = nil
      local_hname = Drbd.local_hostname

      node_list.each do |node|
        if local_hname == node
          disk =node
          break
        end
      end

      if disk
        Builtins.y2debug("Add %1 to add disk list.", disk)
      else
        Builtins.y2error("Disk is not belong to local. localhost is %1,
          nodes are %2.", local_hname, node_list)
      end

      if disk && !Drbd.local_disks_ori.include?(disk) &&
        !Drbd.local_disks_added.include?(disk)
        Drbd.local_disks_added.push(disk)
      end

      nil
    end

    def save_basic_config(res_config)
      res_config = deep_copy(res_config)
      if UI.QueryWidget(Id(:resname), :Value) == nil
        return deep_copy(res_config)
      end

      Ops.set(
        res_config,
        "resname",
        Convert.to_string(UI.QueryWidget(Id(:resname), :Value))
      )

      if ! res_config.has_key?("on")
        res_config["on"] = {}
      end

      # Since n_name can't be edit, so set direct is OK
      Ops.set(
        res_config,
        ["on", Convert.to_string(UI.QueryWidget(Id(:n_name), :Value))],
        {
            "address"   => Convert.to_string(
              UI.QueryWidget(Id(:n_addr), :Value)
            ),
            "device"    => Convert.to_string(
              UI.QueryWidget(Id(:n_devc), :Value)
            ),
            "disk"      => Convert.to_string(
              UI.QueryWidget(Id(:n_disk), :Value)
            ),
            "meta-disk" => Convert.to_string(
              UI.QueryWidget(Id(:n_meta), :Value)
            )
        }
      )

      deep_copy(res_config)
    end



    def res_advance_config_get_dialog(res_config)
      res_config = deep_copy(res_config)
      VBox(
        Frame(
          "Startup",
          HBox(
            TextEntry(
              Id(:wfc_timeout),
              "wfc-timeout",
              Ops.get_string(res_config, ["startup", "wfc-timeout"], "")
            ),
            TextEntry(
              Id(:degr_wfc_timeout),
              "degr-wfc-timeout",
              Ops.get_string(res_config, ["startup", "degr-wfc-timeout"], "")
            )
          )
        ),
        Frame(
          "Disk",
          HBox(
            ComboBox(
              Id(:on_io_error),
              "on-io-error",
              ["detach", "call-local-io-error", "pass_on"]
            ),
            HSpacing(),
            TextEntry(
              Id(:size),
              "size",
              Ops.get_string(res_config, ["disk_s", "size"], "")
            ),
            HSpacing(),
            TextEntry(
              Id(:al_extents),
              "al-extents",
              Ops.get_string(res_config, ["disk_s", "al-extents"]) ||
              Ops.get_string(res_config, ["syncer", "al-extents"], "")
            ),
            HSpacing(),
            TextEntry(
              Id(:resync_rate),
              "resync_rate",
              Ops.get_string(res_config, ["disk_s", "resync-rate"], "")
            )
          )
        ),
        Frame(
          "Net",
          VBox(
            HBox(
              TextEntry(
                Id(:sndbuf_size),
                "sndbuf-size",
                Ops.get_string(res_config, ["net", "sndbuf-size"], "")
              ),
              TextEntry(
                Id(:max_buffers),
                "max-buffers",
                Ops.get_string(res_config, ["net", "max-buffers"], "")
              )
            ),
            HBox(
              ComboBox(Id(:protocol), _("Protocol"), ["A", "B", "C"]),
              TextEntry(
                Id(:timeout),
                "timeout",
                Ops.get_string(res_config, ["net", "timeout"], "")
              ),
              TextEntry(
                Id(:connect_int),
                "connect-int",
                Ops.get_string(res_config, ["net", "connect-int"], "")
              ),
              TextEntry(
                Id(:ping_int),
                "ping-int",
                Ops.get_string(res_config, ["net", "ping-int"], "")
              )
            ),
            HBox(
              TextEntry(
                Id(:max_epoch_size),
                "max-epoch-size",
                Ops.get_string(res_config, ["net", "max-epoch-size"], "")
              ),
              TextEntry(
                Id(:ko_count),
                "ko-count",
                Ops.get_string(res_config, ["net", "ko-count"], "")
              )
            )
          )
        ),
        VStretch(),
        Bottom(
          HBox(
            PushButton(Id(:basic), "Basic Config"),
            PushButton(Id(:cancel_inner), "Cancel"),
            PushButton(Id(:ok), "OK")
          )
        )
      )
    end

    def save_advance_config(res_config)
      res_config = deep_copy(res_config)

      # If don't click the advance button
      if UI.QueryWidget(Id(:protocol), :Value) == nil
        # Move "protocol" to the "net" section
        if Ops.get(res_config, ["net", "protocol"]) == nil
          if Ops.get(res_config, "protocol") == nil
            Ops.set(
              res_config, "net", { "protocol" => "C" }
            )
          else
            Ops.set(
              res_config, "net", { "protocol" => Ops.get(
               res_config, "protocol") }
            )
          end
        end
        Ops.set(res_config, "protocol", nil)

        # Move "al-extents" to the "disk" section
        if Ops.get(res_config, ["disk_s", "al-extents"]) == nil
          Ops.set(res_config, "disk_s", {"al-extents" => Ops.get_string(
           res_config, ["syncer", "al-extents"])})
        end

        if Ops.get(res_config, ["disk_s", "on-io-error"]) == nil
          Ops.set(res_config, "disk_s", {
                 "on-io-error" => "pass_on" ,
                 "al-extents" => Ops.get_string(res_config, ["disk_s", "al-extents"])
                 })
        end
        return deep_copy(res_config)
      end

      # "protocol" option within net section
      # reset the protocol in resource section
      Ops.set(res_config, "protocol", nil)

      Ops.set(
        res_config,
        "startup",
        {
          "wfc-timeout"      => Convert.to_string(
            UI.QueryWidget(Id(:wfc_timeout), :Value)
          ),
          "degr-wfc-timeout" => Convert.to_string(
            UI.QueryWidget(Id(:degr_wfc_timeout), :Value)
          )
        }
      )

      Ops.set(
        res_config,
        "disk_s",
        {
          "on-io-error" => Convert.to_string(
            UI.QueryWidget(Id(:on_io_error), :Value)
          ),
          "al-extents" => Convert.to_string(
            UI.QueryWidget(Id(:al_extents), :Value)
          ),
          "resync-rate" => Convert.to_string(
            UI.QueryWidget(Id(:resync_rate), :Value)
          ),
          "size"        => Convert.to_string(UI.QueryWidget(Id(:size), :Value))
        }
      )

      Ops.set(
        res_config,
        "net",
        {
          "sndbuf-size"    => Convert.to_string(
            UI.QueryWidget(Id(:sndbuf_size), :Value)
          ),
          "timeout"        => Convert.to_string(
            UI.QueryWidget(Id(:timeout), :Value)
          ),
          "connect-int"    => Convert.to_string(
            UI.QueryWidget(Id(:connect_int), :Value)
          ),
          "ping-int"       => Convert.to_string(
            UI.QueryWidget(Id(:ping_int), :Value)
          ),
          "max-buffers"    => Convert.to_string(
            UI.QueryWidget(Id(:max_buffers), :Value)
          ),
          "max-epoch-size" => Convert.to_string(
            UI.QueryWidget(Id(:max_epoch_size), :Value)
          ),
          "ko-count"       => Convert.to_string(
            UI.QueryWidget(Id(:ko_count), :Value)
          ),
          "protocol"       => Convert.to_string(
            UI.QueryWidget(Id(:protocol), :Value)
          ),
          "verify-alg"     => Ops.get_string(
            res_config, ["net", "verify-alg"], ""),
          "use-rle"     => Ops.get_string(
            res_config, ["net", "use-rle"], ""),
        }
      )

      Builtins.y2debug("ret = %1", res_config)
      deep_copy(res_config)
    end


    def del_empty_item(old_map)
      old_map = deep_copy(old_map)
      new_map = deep_copy(old_map)
      Builtins.foreach(
        Convert.convert(old_map, :from => "map", :to => "map <string, any>")
      ) do |key, val|
        if Ops.is_map?(val)
          Ops.set(new_map, key, del_empty_item(Convert.to_map(val)))
        else
          if Builtins.size(Convert.to_string(val)) == 0
            Ops.set(new_map, key, nil)
          end
        end
      end

      deep_copy(new_map)
    end

    def fill_nodes_entries(node_list)
      i = current = 0
      items = []
      node_list.each do |name|
        items = items.push(Item(Id(i), name))
        i += 1
      end
      # Using current to make sure back to original posion after click
      # CurrentItem initial as 0
      current = UI.QueryWidget(:node_box, :CurrentItem).to_i
      current = i-1 if current >= i
      UI.ChangeWidget(:node_box, :Items, items)
      UI.ChangeWidget(:node_box, :CurrentItem, current)

      nil
    end

    def fill_node_info(res_config, node_name)
      UI.ChangeWidget(Id(:n_name), :Value, node_name)
      UI.ChangeWidget(Id(:n_addr), :Value,
         Ops.get_string(res_config,
                      ["on", node_name, "address"],
                      ""))
      UI.ChangeWidget(Id(:n_devc), :Value,
         Ops.get_string(res_config,
                      ["on", node_name, "device"],
                      ""))
      UI.ChangeWidget(Id(:n_disk), :Value,
         Ops.get_string(res_config,
                      ["on", node_name, "disk"],
                      ""))
      UI.ChangeWidget(Id(:n_meta), :Value,
         Ops.get_string(res_config,
                      ["on", node_name, "meta-disk"],
                      "internal"))

      # Do not allowed to modify node name. Add/Delete only.
      UI.ChangeWidget(Id(:n_name), :Enabled, false)

      nil
    end

    # return `cancel or a string
    def node_name_input_dialog(title, value)
      ret = nil

      UI.OpenDialog(
        MarginBox(
          1,
          1,
          VBox(
            MinWidth(100, InputField(Id(:text), Opt(:hstretch), title, value)),
            VSpacing(1),
            Right(
              HBox(
                PushButton(Id(:ok), _("OK")),
                PushButton(Id(:cancel), _("Cancel"))
              )
            )
          )
        )
      )
      while true
        ret = UI.UserInput
        if ret == :ok
          val = Convert.to_string(UI.QueryWidget(:text, :Value))
          if val.size != 0
            ret = val
            break
          else
            Popup.Message(_("Node name can not be empty."))
          end
        end
        break if ret == :cancel
      end
      UI.CloseDialog
      deep_copy(ret)
    end

    def switchButtonsOn(frame)
      if frame == "Right"
        enable = false
      else
        enable = true
      end
      disable = !enable

      UI.ChangeWidget(Id(:node_box), :Enabled, enable)
      UI.ChangeWidget(Id(:node_add), :Enabled, enable)
      UI.ChangeWidget(Id(:node_edit), :Enabled, enable)
      UI.ChangeWidget(Id(:node_del), :Enabled, enable)

      UI.ChangeWidget(Id(:n_name), :Enabled, disable)
      UI.ChangeWidget(Id(:n_addr), :Enabled, disable)
      UI.ChangeWidget(Id(:n_devc), :Enabled, disable)
      UI.ChangeWidget(Id(:n_disk), :Enabled, disable)
      UI.ChangeWidget(Id(:n_meta), :Enabled, disable)
      UI.ChangeWidget(Id(:node_save), :Enabled, disable)
    end

    def autoGenerateNodeID(res_config)
      res_config = deep_copy(res_config)

      node_id = 0
      Builtins.foreach(Ops.get_map(res_config, "on", {})) do |name, val|
        res_config["on"][name]["node-id"] = node_id
        node_id += 1
      end

      deep_copy(res_config)
    end

    def ValidIPaddress
      addressField = Convert.to_string(UI.QueryWidget(Id(:n_addr), :Value))

      if addressField.include?("ipv6")
        # eg. ipv6 [fd01:2345:6789:abcd::1]:7800
        if ! (addressField.include?("[") and addressField.include?("]"))
          Popup.Warning(_("IPv6 address must be placed inside brackets."))
          return false
        end

        # IPv6 should including port
        if addressField.split("]")[1] and addressField.split("]")[1].include?(":")
          ip = addressField.split("]")[0].split("[")[1]
        else
          Popup.Warning(_("IP/port should use 'addr:port' combination."))
          return false
        end
      else
        if ! addressField.include?(":")
          Popup.Warning(_("IP/port should use 'addr:port' combination."))
          return false
        end

        ip = addressField.split(":")[0]
      end

      if IP.Check(ip) != true
        Popup.Message(_("Please enter a valid IP address."))
        return false
      end

      # Checking the port is number
      if addressField.split(":").size == 1 or
         addressField.split(":")[-1].to_i == 0
        Popup.Message(_("Please enter a valid port number."))
        return false
      end

      true
    end

    def ResDialog(resname)
      current = 0
      ret = nil
      # No need to empty all field if value not invalid
      invalid = false
      cur_page = :basic
      orires = resname

      res_config = Ops.get_map(Drbd.resource_config, orires, {})
      # New create a res and delete the old res after finished
      Ops.set(res_config, "resname", orires)

      my_SetContents("basic_conf", res_basic_config_get_dialog(orires))
      #Popup::Warning(resname);
      switchButtonsOn("Left")

      node_list = []
      Builtins.foreach(Ops.get_map(res_config, "on", {})) do |name, val|
        node_list = Builtins.add(node_list, name)
      end

      Wizard.DisableNextButton
      Wizard.DisableAbortButton

      while true
        Wizard.SelectTreeItem("resource_conf")

        # May need to check only when cur_page == :basic
        if invalid == false
          fill_nodes_entries(node_list)

          if node_list.empty?
            fill_node_info(res_config, "")
            switchButtonsOn("Right")
          else
            current = UI.QueryWidget(:node_box, :CurrentItem).to_i
            fill_node_info(res_config, node_list[current])
          end
        end

        # Select box disable notify by default
        UI.ChangeWidget(Id(:node_box), :Notify, true)
        invalid = false

        ret = UI.UserInput
        Builtins.y2debug("in ResDialog(), UserInput ret=%1", ret)

        if ret == :help
          #myHelp("basic_conf");
          next
        end

        if ret == :wizardTree
          next
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        next if Builtins.contains(@DIALOG, Builtins.tostring(ret))

        if ret == :advance || ret == :node_save || ret == :ok && cur_page == :basic
          if UI.QueryWidget(Id(:n_name), :Value).to_s.include?(".")
            Popup.Warning(_('Node names must not include "." , using the local hostname.'))

            UI.SetFocus(Id(:n_name))
            invalid = true
            ret = nil
            next
          end

          Builtins.foreach(
            [
              :resname,
              :n_addr,
              :n_name,
              :n_devc,
              :n_disk,
              :n_meta
            ]
          ) do |the_id|
            str = Convert.to_string(UI.QueryWidget(Id(the_id), :Value))
            if str == nil || Builtins.size(str) == 0
              Popup.Warning(_("Please fill out all fields."))
              invalid = true
              ret = nil
              raise Break
            end
          end

          if ! ValidIPaddress()
              invalid = true
              ret = nil
              next
          end

          if ret == :ok
            if node_list.size < 2
              Popup.Warning(_("Please configure at least two nodes."))
              invalid = true
              ret = nil
              next
            end
          end

          Drbd.modified = true

          next if ret == nil
        end

        if ret == :node_box
          # No need to check integrity since it will disabled when configuring
          res_config = save_basic_config(res_config)
          next
        end

        if ret == :node_save
          res_config = save_basic_config(res_config)

          # Need to refresh the node_list when initial resource
          if node_list.empty?
            Builtins.foreach(Ops.get_map(res_config, "on", {})) do |name, val|
              node_list = Builtins.add(node_list, name)
            end
          end

          switchButtonsOn("Left")
          next
        end

        if ret == :node_add
          # No need to check integrity since it will disabled when configuring
          ret = node_name_input_dialog(
            _("Enter the node name:"),
            ""
          )
          next if ret == :cancel

          if node_list.include?(ret.to_s)
            Popup.Warning(_("Node name must be different."))
            ret = nil
            next
          end

          Ops.set(res_config, ["on", ret.to_s], {})
          node_list.push(ret.to_s)

          # Point to the new add node
          # Need to point after updating the node_box
          fill_nodes_entries(node_list)
          UI.ChangeWidget(:node_box, :CurrentItem, node_list.size - 1)
          switchButtonsOn("Right")
          UI.ChangeWidget(Id(:node_del), :Enabled, true)

          ret = nil
          next
        end

        if ret == :node_edit
          switchButtonsOn("Right")
          UI.ChangeWidget(Id(:n_name), :Enabled, false)
          next
        end

        if ret == :node_del
          current = UI.QueryWidget(:node_box, :CurrentItem).to_i

          res_config["on"].delete(node_list[current])
          node_list.delete_at(current)

          switchButtonsOn("Left")
          ret = nil
          next
        end

        if ret == :advance
          cur_page = :advance

          res_config = save_basic_config(res_config)
          Builtins.y2debug("res_config = %1", res_config)

          my_SetContents(
            "advance_conf",
            res_advance_config_get_dialog(res_config)
          )

          UI.ChangeWidget(
            Id(:protocol),
            :Value,
            # First using the protocol in net section.
            # Ops.get() including the logical of has_key
            # otherwise will use like:
            # (res_config.has_key?("net") &&
            # res_config["net"].has_key?("protocol") &&
            # Ops.get_string(res_config["net"], "protocol", "C")) ||
            Ops.get_string(res_config, ["net", "protocol"]) ||
            Ops.get_string(res_config, "protocol", "C")
          )
          UI.ChangeWidget(
            Id(:on_io_error),
            :Value,
            Ops.get_string(res_config, ["disk_s", "on-io-error"], "pass_on")
          )

          Wizard.DisableNextButton
          Wizard.DisableAbortButton

          next
        end

        if ret == :basic
          cur_page = :basic

          res_config = save_advance_config(res_config)
          my_SetContents("basic_conf", res_basic_config_get_dialog(
            Ops.get_string(res_config, "resname")))

          switchButtonsOn("Left")

          Wizard.DisableNextButton
          Wizard.DisableAbortButton

          next
        end

        break if ret == :cancel_inner

        if ret == :ok
          res_config = save_basic_config(res_config)
          res_config = save_advance_config(res_config)

          Builtins.y2debug("res_config=%1", res_config)

          # For change LVM filter automatically
          update_add_disk_list(node_list)

          if Ops.greater_than(Builtins.size(orires), 0)
            # Remove the original res configuration
            Drbd.resource_config = Builtins.remove(
              Drbd.resource_config,
              orires
            )
            #Ops.set(Drbd.resource_config, orires, nil)
          else
            Builtins.y2debug("add new resouce")
          end

          # Set the new res configuration
          newres = Ops.get_string(res_config, "resname", "")
          Builtins.y2debug("resname=%1", newres)

          if Ops.greater_than(Builtins.size(newres), 0)
            res_config = Builtins.remove(res_config, "resname")
            # Generate node-id section
            res_config = autoGenerateNodeID(res_config)
            # Generate connection-mesh section in Write function
            # Since may 'Finish' in 'global' dialog

            Ops.set(Drbd.resource_config, newres, res_config)
            Builtins.y2debug("new resname = %1", newres)
            Builtins.y2debug(
              "mcdebug drbd::resource_config = %1",
              Drbd.resource_config
            )
          end

          break
        end
      end

      Wizard.EnableNextButton
      Wizard.EnableAbortButton
      deep_copy(ret)
    end


    def ResAddDialog
      ret = nil
      ret = ResDialog("")
      deep_copy(ret)
    end


    def ResEditDialog
      ret = nil
      resname = Convert.to_string(
        UI.QueryWidget(Id(:res_list_table), :CurrentItem)
      )
      ret = ResDialog(resname)

      deep_copy(ret)
    end


    def ResourceSequence
      aliases = { "list" => lambda { ResListDialog() }, "add" => lambda do
        ResAddDialog()
      end, "edit" => lambda(
      ) do
        ResEditDialog()
      end }

      sequence = {
        "ws_start" => "list",
        "list"     => {
          :startup_conf => :startup_conf,
          :global_conf  => :global_conf,
          :lvm_conf     => :lvm_conf,
          :add          => "add",
          :edit         => "edit",
          :list         => "list",
          :abort        => :abort,
          :next         => :next
        },
        "add"      => {
          :abort        => :abort,
          :ok           => "list",
          :cancel_inner => "list"
        },
        "edit"     => {
          :ok           => "list",
          :abort        => :abort,
          :cancel_inner => "list"
        }
      }

      ret = Sequencer.Run(aliases, sequence)

      deep_copy(ret)
    end
  end
end
