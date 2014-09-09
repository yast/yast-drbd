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
        items = Item(Id(resname))
        items = Builtins.add(items, resname)
        Builtins.foreach(Ops.get_map(resconfig, "on", {})) do |nodename, nodeconfig|
          items = Builtins.add(items, nodename)
        end
        table_items = Builtins.add(table_items, items)
        0
      end

      VBox(
        Opt(:hvstretch),
        VBox(
          Opt(:hvstretch),
          Table(
            Id(:res_list_table),
            Header("Resource      ", "Node-1       ", "Node-2       "),
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

    def res_basic_config_get_dialog(res_config)
      res_config = deep_copy(res_config)
      node_name = []

      Builtins.foreach(Ops.get_map(res_config, "on", {})) do |name, val|
        node_name = Builtins.add(node_name, name)
      end

      VBox(
        TextEntry(
          Id(:resname),
          _("Resource Name"),
          Ops.get_string(res_config, "resname", "")
        ),
        Frame(
          "Nodes Configurations",
          HBox(
            MarginBox(
              1,
              1,
              Frame(
                "Node 1",
                VBox(
                  TextEntry(Id(:n1_name), "Name", Ops.get(node_name, 0, "")),
                  TextEntry(
                    Id(:n1_addr),
                    "Address:Port",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 0, ""), "address"],
                      ""
                    )
                  ),
                  TextEntry(
                    Id(:n1_devc),
                    "Device",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 0, ""), "device"],
                      ""
                    )
                  ),
                  TextEntry(
                    Id(:n1_disk),
                    "Disk",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 0, ""), "disk"],
                      ""
                    )
                  ),
                  TextEntry(
                    Id(:n1_meta),
                    "Meta-disk",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 0, ""), "meta-disk"],
                      "internal"
                    )
                  )
                )
              )
            ),
            MarginBox(
              1,
              1,
              Frame(
                "Node 2",
                VBox(
                  TextEntry(Id(:n2_name), "Name", Ops.get(node_name, 1, "")),
                  TextEntry(
                    Id(:n2_addr),
                    "Address:Port",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 1, ""), "address"],
                      ""
                    )
                  ),
                  TextEntry(
                    Id(:n2_devc),
                    "Device",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 1, ""), "device"],
                      ""
                    )
                  ),
                  TextEntry(
                    Id(:n2_disk),
                    "Disk",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 1, ""), "disk"],
                      ""
                    )
                  ),
                  TextEntry(
                    Id(:n2_meta),
                    "Meta-disk",
                    Ops.get_string(
                      res_config,
                      ["on", Ops.get(node_name, 1, ""), "meta-disk"],
                      "internal"
                    )
                  )
                )
              )
            )
          )
        ),
        VStretch(),
        Bottom(
          HBox(
            PushButton(Id(:advance), "Advanced Config"),
            PushButton(Id(:cancel_inner), "Cancel"),
            PushButton(Id(:ok), "OK")
          )
        )
      )
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
      Ops.set(
        res_config,
        "on",
        {
          Convert.to_string(UI.QueryWidget(Id(:n1_name), :Value)) => {
            "address"   => Convert.to_string(
              UI.QueryWidget(Id(:n1_addr), :Value)
            ),
            "device"    => Convert.to_string(
              UI.QueryWidget(Id(:n1_devc), :Value)
            ),
            "disk"      => Convert.to_string(
              UI.QueryWidget(Id(:n1_disk), :Value)
            ),
            "meta-disk" => Convert.to_string(
              UI.QueryWidget(Id(:n1_meta), :Value)
            )
          },
          Convert.to_string(UI.QueryWidget(Id(:n2_name), :Value)) => {
            "address"   => Convert.to_string(
              UI.QueryWidget(Id(:n2_addr), :Value)
            ),
            "device"    => Convert.to_string(
              UI.QueryWidget(Id(:n2_devc), :Value)
            ),
            "disk"      => Convert.to_string(
              UI.QueryWidget(Id(:n2_disk), :Value)
            ),
            "meta-disk" => Convert.to_string(
              UI.QueryWidget(Id(:n2_meta), :Value)
            )
          }
        }
      )

      deep_copy(res_config)
    end


    def res_advance_config_get_dialog(res_config)
      res_config = deep_copy(res_config)
      VBox(
        HBox(
          ComboBox(Id(:protocol), _("Protocol"), ["A", "B", "C"]),
          HSpacing()
        ),
        Frame(
          "Startup",
          HBox(
            TextEntry(
              Id(:wfc_timeout),
              "wfc-timeout",
              Ops.get_string(res_config, "wfc-timeout", "")
            ),
            TextEntry(
              Id(:degr_wfc_timeout),
              "degr-wfc-timeout",
              Ops.get_string(res_config, "degr-wfc-timeout", "")
            )
          )
        ),
        Frame(
          "Disk",
          HBox(
            ComboBox(
              Id(:on_io_error),
              "on-io-error",
              ["detach", "panic", "pass_on"]
            ),
            HSpacing(),
            TextEntry(
              Id(:size),
              "size",
              Ops.get_string(res_config, ["disk_s", "size"], "")
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
        Frame(
          "Syncer",
          HBox(
            TextEntry(
              Id(:rate),
              "Rate",
              Ops.get_string(res_config, ["syncer", "rate"], "")
            ),
            TextEntry(
              Id(:al_extents),
              "Al-extents",
              Ops.get_string(res_config, ["syncer", "al-extents"], "")
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
      if UI.QueryWidget(Id(:protocol), :Value) == nil
        if Ops.get(res_config, "protocol") == nil
          Ops.set(res_config, "protocol", "C")
        end
        if Ops.get(res_config, ["disk_s", "on-io-error"]) == nil
          Ops.set(res_config, "disk_s", { "on-io-error" => "pass_on" })
        end
        return deep_copy(res_config)
      end


      Ops.set(
        res_config,
        "protocol",
        Convert.to_string(UI.QueryWidget(Id(:protocol), :Value))
      )

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
          )
        }
      )

      Ops.set(
        res_config,
        "syncer",
        {
          "al-extents" => Convert.to_string(
            UI.QueryWidget(Id(:al_extents), :Value)
          ),
          "rate"       => Convert.to_string(UI.QueryWidget(Id(:rate), :Value))
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


    def ResDialog(resname)
      ret = nil
      cur_page = :basic
      res_config = Ops.get_map(Drbd.resource_config, resname, {})
      Ops.set(res_config, "resname", resname)

      my_SetContents("basic_conf", res_basic_config_get_dialog(res_config))
      #Popup::Warning(resname);

      Wizard.DisableNextButton
      Wizard.DisableAbortButton

      while true
        Wizard.SelectTreeItem("resource_conf")
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


        if ret == :advance || ret == :ok && cur_page == :basic
          if Convert.to_string(UI.QueryWidget(Id(:n1_name), :Value)) ==
              Convert.to_string(UI.QueryWidget(Id(:n2_name), :Value))
            Popup.Warning(_("Node names must be different."))
            ret = nil
            next
          end

          Drbd.modified = true

          Builtins.foreach(
            [
              :resname,
              :n1_addr,
              :n1_name,
              :n1_devc,
              :n1_disk,
              :n1_meta,
              :n2_name,
              :n2_addr,
              :n2_devc,
              :n2_disk,
              :n2_meta
            ]
          ) do |the_id|
            str = Convert.to_string(UI.QueryWidget(Id(the_id), :Value))
            if str == nil || Builtins.size(str) == 0
              Popup.Warning(_("Please fill out all fields."))
              ret = nil
              raise Break
            end
          end
          next if ret == nil
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
          my_SetContents("basic_conf", res_basic_config_get_dialog(res_config))

          Wizard.DisableNextButton
          Wizard.DisableAbortButton

          next
        end

        break if ret == :cancel_inner

        if ret == :ok
          res_config = save_basic_config(res_config)
          res_config = save_advance_config(res_config)

          Builtins.y2debug("res_config=%1", res_config)

          if Ops.greater_than(Builtins.size(resname), 0)
            Drbd.resource_config = Builtins.remove(
              Drbd.resource_config,
              resname
            )
            Ops.set(Drbd.resource_config, resname, nil)
            resname = Ops.get_string(res_config, "resname", "")
            Builtins.y2debug("resname=%1", resname)
            if Ops.greater_than(Builtins.size(resname), 0)
              res_config = Builtins.remove(res_config, "resname")
              Ops.set(Drbd.resource_config, resname, res_config)
              Builtins.y2debug("new resname = %1", resname)
              Builtins.y2debug(
                "mcdebug drbd::resource_config = %1",
                Drbd.resource_config
              )
            end
          else
            Builtins.y2debug("add new resouce")
            resname = Ops.get_string(res_config, "resname", "")
            if Ops.greater_than(Builtins.size(resname), 0)
              res_config = Builtins.remove(res_config, "resname")
              Ops.set(Drbd.resource_config, resname, res_config)
            end
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
