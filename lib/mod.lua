local mod  = require 'core/mods'
local hook = require 'core/hook' -- FIXME is this include necessary?
local nb   = require 'nb/lib/nb'
local s    = require 'sequins'
local TulpamancerVice = require 'tulpamancer/lib/tulpamancervice'

local SEPARATOR_NAME = "tulpamancer player"

local tulpa_seq   = s{}
local tulpa_clock = nil

mod.hook.register('script_post_init', 'tulpamancer post init', function()
  TulpamancerVice.binary_tulpa = "11110000" -- FIXME fake until I manage to deal with asynchronous calling
  TulpamancerVice:get_tulpa(true)
  nb:init()

  params:add_separator('tulpamancer_player', SEPARATOR_NAME)

  params:add_binary('nb_tulpamancer_play', "play", 'toggle')
  params:set_action('nb_tulpamancer_play', function(v)
    if v == 1 then
      if TulpamancerVice.tulpa_binary == '' then
        print("no tulpa")
        params:lookup_param('tulpamancer_player').name = "tulpa not found"
      else
        print("tulpa is "..TulpamancerVice.tulpa_binary)
        params:lookup_param('tulpamancer_player').name = "tulpa "..TulpamancerVice.tulpa_binary

        local trigs = {}
        TulpamancerVice.tulpa_binary:gsub(".", function(c) table.insert(trigs, tonumber(c)) end)
        tulpa_seq:settable(trigs)

        local p = params:lookup_param('nb_tulpamancer_voice'):get_player()

        tulpa_clock = clock.run(function()
          while true do
            clock.sync(1/16 * params:get('nb_tulpamancer_clock_div'))
            local step = tulpa_seq()
            if step == 1 then
              p:note_on(params:get('nb_tulpamancer_note'), 1)
                     -- TODO note off
            end
          end
        end)
      end
      -- TODO setup sequencer
      -- TODO start sequencer
    elseif v == 0 then
      params:lookup_param('tulpamancer_player').name = SEPARATOR_NAME
      clock.cancel(tulpa_clock)
      -- TODO kill all notes
    end
  end)

  nb:add_param('nb_tulpamancer_voice', "voice")
  params:add_control('nb_tulpamancer_note', 'note', controlspec.MIDINOTE)
  params:set('nb_tulpamancer_note', 64)
  params:lookup_param('nb_tulpamancer_note').formatter = function(p) return math.floor(params:get(p.id)) end
  params:add_number('nb_tulpamancer_clock_div', "clock div", 1, 16, 4) --, function(p) return "1/"..p.value end)
end)

-- Local Variables:
-- flycheck-luacheck-standards: ("lua51" "norns")
-- End:
