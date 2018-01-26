# encoding: utf-8

# Package:	Configuration of heartbeat
# Authors:	Martin Lazar <mlazar@suse.cz>
#
# $Id: startup_conf.ycp 30707 2006-05-04 13:19:08Z lslezak $
module Yast
  module DrbdStartupConfInclude
    def initialize_drbd_startup_conf(include_target)
      Yast.import "UI"

      textdomain "drbd"

      Yast.import "Report"
      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Service"
      Yast.import "Drbd"
      Yast.import "CWMFirewallInterfaces"

      Yast.include include_target, "drbd/helps.rb"
      Yast.include include_target, "drbd/common.rb"
    end

    def ConfigureStartUpDialog
      boot = Drbd.start_daemon

      _Tbooting = Frame(
        _("Booting"),
        Left(
          RadioButtonGroup(
            Id("server_type"),
            VBox(
              Left(
                RadioButton(
                  Id("on"),
                  _("On -- Start DRBD Server when Booting")
                )
              ),
              Left(
                RadioButton(Id("off"), _("Off -- Server Only Starts Manually"))
              ),
              VSpacing(1)
            )
          )
        )
      )

      _Tonoff = Frame(
        _("Switch On and Off"),
        Left(
          HSquash(
            VBox(
              HBox(
                Label(_("Current Status: ")),
                ReplacePoint(Id("status_rp"), Empty()),
                HStretch()
              ),
              PushButton(
                Id("start_now"),
                Opt(:hstretch),
                _("Start DRBD Server Now")
              ),
              PushButton(
                Id("stop_now"),
                Opt(:hstretch),
                _("Stop DRBD Server Now")
              )
            )
          )
        )
      )

      # Just a dialog
      firewall_widget = CWMFirewallInterfaces.CreateOpenFirewallWidget(
        {
          #drbd is the name of /usr/lib/firewalld.d/services/drbd.xml
          "services"        => [
            "drbd"
          ],
          "display_details" => true
        }
      )
      Builtins.y2milestone("%1", firewall_widget)
      # firewall_layout is just a dialog
      firewall_layout = Ops.get_term(firewall_widget, "custom_widget", VBox())

      _Tpropagate = Frame(
        _("Propagate Configuration"),
        Left(
          HSquash(
            VBox(
              VBox(
                Left(
                  Label(
                    _(
                      "To propagate this configuration ,\ncopy the configuration file '/etc/drbd.conf' to the rest of nodes manually."
                    )
                  )
                )
              )
            )
          )
        )
      )

      contents = Empty()
      #    if (Heartbeat::firstrun) {
      #	contents = `VBox (Tbooting, `VSpacing(1), Tpropagate, `VStretch() );
      #    } else {
      contents = VBox(
        _Tbooting,
        VSpacing(1),
        _Tonoff,
        VSpacing(1),
        firewall_layout,
        VSpacing(1),
        _Tpropagate,
        VStretch()
      )
      #    }


      my_SetContents("startup_conf", contents)

      UI.ChangeWidget(Id("server_type"), :CurrentButton, boot ? "on" : "off")
      CWMFirewallInterfaces.OpenFirewallInit(firewall_widget, "")
      event = {}

      ret = nil
      while true
        status = Service.Status("drbd")

        UI.ChangeWidget(Id("start_now"), :Enabled, status != 0)
        UI.ChangeWidget(Id("stop_now"), :Enabled, status == 0)

        UI.ReplaceWidget(
          Id("status_rp"),
          Label(
            status == 0 ?
              _("DRBD server is running.") :
              _("DRBD server is not running.")
          )
        )

        # add event
        event = UI.WaitForEvent
        ret = Ops.get(event, "ID")

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :next || ret == :back
          CWMFirewallInterfaces.OpenFirewallStore(firewall_widget, "", event)
          break
        end

        if ret == "start_now"
          if !Service.Start("drbd")
            #Report::Error ( Service::Error());
            Report.Error(_("Start DRBD service failed"))
          end
          next
        end

        if ret == "stop_now"
          if !Service.Stop("drbd")
            #Report::Error ( Service::Error() );
            Report.Error(_("Stop DRBD service failed"))
          end
          next
        end

        #if ret == :help
        #  myHelp("startup_conf")
        #  next
        #end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          break
        end

        CWMFirewallInterfaces.OpenFirewallHandle(firewall_widget, "", event)

        Builtins.y2error("unexpected retcode: %1", ret)
      end

      boot1 = Convert.to_string(
        UI.QueryWidget(Id("server_type"), :CurrentButton)
      )
      if boot1 == "off" && boot || boot1 == "on" && !boot
        #	Drbd::start_daemon_modified = true;
        Drbd.start_daemon = !boot
      end

      deep_copy(ret)
    end
  end
end
