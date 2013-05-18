require 'travis/build/script/addons/cloud_foundry'
require 'travis/build/script/addons/dot_cloud'
require 'travis/build/script/addons/engine_yard'
require 'travis/build/script/addons/firefox'
require 'travis/build/script/addons/heroku'
require 'travis/build/script/addons/hosts'
require 'travis/build/script/addons/sauce_connect'

module Travis
  module Build
    class Script
      module Addons
        MAP = {
          cloud_foundry: CloudFoundry,
          dotcloud:      DotCloud,
          engine_yard:   EngineYard,
          firefox:       Firefox,
          heroku:        Heroku,
          hosts:         Hosts,
          sauce_connect: SauceConnect,
        }

        def run_addons(stage)
          addons.each do |addon|
            addon.send(stage) if addon.respond_to?(stage)
          end
        end

        def addons
          @addons ||= (config[:addons] || {}).map do |name, addon_config|
            init_addon(name, addon_config)
          end
        end

        def init_addon(name, config)
          MAP[name].new(self, config)
        end
      end
    end
  end
end
