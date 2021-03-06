#
# Copyright 2014 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

module Actions
  module Staypuft
    module Host

      class WaitUntilReady < Actions::Base

        STARTUP_GRACE_PERIOD = 60
        TIMEOUT = 1800

        middleware.use Actions::Staypuft::Middleware::Timeout
        middleware.use Actions::Staypuft::Middleware::AsCurrentUser
        include Dynflow::Action::Polling

        def plan(host)
          plan_self host_id: host.id
        end

        def external_task
          output[:status]
        end

        def done?
          external_task
        end

        private

        def invoke_external_task
          nil
        end

        def external_task=(external_task_data)
          output[:status] = external_task_data
        end

        def poll_external_task
          if !output[:ssh_port_open_at] && check_ssh_port_open
            output[:ssh_port_open_at] ||= Time.now.to_i
          end

          if output[:ssh_port_open_at]
            Time.now.to_i - output[:ssh_port_open_at] > STARTUP_GRACE_PERIOD
          else
            false
          end
        end

        def poll_interval
          5
        end

        def check_ssh_port_open
          host = ::Host.find input.fetch(:host_id)
          host.send :ssh_open?, host.ip
        end

      end
    end
  end
end
