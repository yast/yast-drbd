# encoding: utf-8

module Yast
  module DrbdLvmConfInclude
    def initialize_drbd_lvm_conf(include_target)
      textdomain "drbd"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Drbd"

      Yast.include include_target, "drbd/helps.rb"
      Yast.include include_target, "drbd/common.rb"

      @filter = ""
      @cache = true
      @lvmetad = false

    end

    def lvm_conf_Read
      @filter = Ops.get_string( Drbd.lvm_config, "filter", "" )
      lvmetad_str = Ops.get_string( Drbd.lvm_config, "use_lvmetad", "0" )
      if lvmetad_str == "0"
        @lvmetad = false
      else
        @lvmetad = true
      end

      cache_str = Ops.get_string( Drbd.lvm_config, "write_cache_state", "0" )
      if cache_str == "0"
        @cache = false
      else
        @cache = true
      end

      nil
    end

    def lvm_conf_GetDialog
      _Tfilter = Frame(
        _("LVM Filter Configuration of DRBD"),
        Left(
          VBox(
            VBox(
              Left(
                InputField(
                  Id(:Filter),
                  Opt(:hstretch),
                  _("Device Filter"),
                  @filter
                )
              )
            ),
          )
        )
      )

      _Tcache = Frame(
        _("Writing the LVM cache"),
        Left(
          HSquash(
            VBox(
              VBox(
                Left(
                  CheckBox(
                    Id(:LVMCache),
                    Opt(:notify),
                    _("Enable LVM Cache"),
                    @cache
                  )
                ),
                Left(Label(
                  _(
                    "Warning!  Should disable LVM cache for using drbd."
                  )
                )),
              ),
            )
          )
        )
      )

      _Tlvmetad = Frame(
        _("Use lvmetad for LVM"),
        Left(
          HSquash(
            VBox(
              VBox(
                Left(
                  CheckBox(
                    Id(:LVMetad),
                    Opt(:notify),
                    _("Use LVM metad"),
                    @lvmetad
                  )
                ),
                Left(Label(
                  _(
                    "Warning!  Should not use lvmetad for cluster."
                  )
                )),
              ),
            )
          )
        )
      )

      VBox(
        _Tfilter,
        VSpacing(1),
        _Tcache,
        VSpacing(1),
        _Tlvmetad,
        VStretch()
      )
    end

    def lvm_conf_Write
      @filter = UI.QueryWidget(Id(:Filter), :Value).to_s

      @cache = UI.QueryWidget(Id(:LVMCache), :Value)
      if @cache
        cache_str = "1"
      else
        cache_str = "0"
      end

      @lvmetad = UI.QueryWidget(Id(:LVMetad), :Value)
      if @lvmetad
        lvmetad_str = "1"
      else
        lvmetad_str = "0"
      end

      Ops.set(Drbd.lvm_config, "write_cache_state", cache_str)
      Ops.set(Drbd.lvm_config, "use_lvmetad", lvmetad_str)

      Ops.set(Drbd.lvm_config, "filter", @filter)

      Drbd.modified = true

      true
    end

    def ConfigureLVMDialog
      lvm_conf_Read

      my_SetContents("lvm_conf", lvm_conf_GetDialog)

      ret = nil
      while true
        Wizard.SelectTreeItem("lvm_conf")

        ret = UI.UserInput

        if ret == :help
          #myHelp("lvm_conf")
          next
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if ret == :Filter || ret == :LVMCache
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
          next if !lvm_conf_Write

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
