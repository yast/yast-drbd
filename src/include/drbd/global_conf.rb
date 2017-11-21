# encoding: utf-8

module Yast
  module DrbdGlobalConfInclude
    def initialize_drbd_global_conf(include_target)
      Yast.import "UI"
      textdomain "drbd"
      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Drbd"

      Yast.include include_target, "drbd/helps.rb"
      Yast.include include_target, "drbd/common.rb"

      @disipver = "false"
      @disiohin = "false"
      @udevusevnr = "true"
      @diagref = "0"
      @mc = "0"
    end

    def global_conf_Read
      @disipver = Ops.get_string(
        Drbd.global_config,
        "disable-ip-verification",
        "false"
      )
      @udevusevnr = Ops.get_string(
        Drbd.global_config,
        "udev-always-use-vnr",
        "true"
      )
      @diagref = Ops.get_string(Drbd.global_config, "dialog-refresh", "1")
      @mc = Ops.get_string(Drbd.global_config, "minor-count", "5")

      nil
    end

    def global_conf_GetDialog
      VBox(
        Frame(
          _("Global Configuration of DRBD"),
          HBox(
            VBox(
              Left(
                IntField(
                  Id("MinorCount"),
                  _("Minor Count"),
                  1,
                  20,
                  Builtins.tointeger(@mc)
                )
              ),
              Left(
                IntField(
                  Id("DialogRefresh"),
                  _("Dialog Refresh"),
                  0,
                  1000,
                  Builtins.tointeger(@diagref)
                )
              ),
              Left(
                CheckBox(
                  Id("UdevAlwaysUseVnr"),
                  Opt(:notify),
                  _("Udev Always Use VNR"),
                  @udevusevnr == "true"
                )
              ),
              Left(
                CheckBox(
                  Id("DisableIpVerification"),
                  Opt(:notify),
                  _("Disable IP Verification"),
                  @disipver == "true"
                )
              )
            )
          )
        ),
        VStretch()
      )
    end

    def global_conf_Write
      @disipver = Convert.to_boolean(
        UI.QueryWidget(Id("DisableIpVerification"), :Value)
      ) ? "true" : nil
      @udevusevnr = Convert.to_boolean(
        UI.QueryWidget(Id("UdevAlwaysUseVnr"), :Value)
      ) ? "true" : nil
      @diagref = Builtins.sformat(
        "%1",
        UI.QueryWidget(Id("DialogRefresh"), :Value)
      )
      @mc = Builtins.sformat("%1", UI.QueryWidget(Id("MinorCount"), :Value))

      Ops.set(Drbd.global_config, "disable-ip-verification", @disipver)
      Ops.set(Drbd.global_config, "udev-always-use-vnr", @udevusevnr)
      Ops.set(Drbd.global_config, "dialog-refresh", @diagref)
      Ops.set(Drbd.global_config, "minor-count", @mc)

      Drbd.modified = true

      true
    end

    def ConfigureGlobalDialog
      global_conf_Read

      my_SetContents("global_conf", global_conf_GetDialog)

      ret = nil
      while true
        Wizard.SelectTreeItem("global_conf")

        ret = UI.UserInput

        if ret == :help
          myHelp("global_conf")
          next
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if ret == "DialogRefresh" || ret == "MinorCount" ||
            ret == "DisableIpVerification"
          Drbd.modified = true
          next
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :next || ret == :back ||
            Builtins.contains(@DIALOG, Builtins.tostring(ret))
          next if !global_conf_Write

          if ret != :next && ret != :back
            ret = Builtins.symbolof(Builtins.toterm(ret))
          end

          break
        end
      end
      deep_copy(ret)
    end
  end
end
