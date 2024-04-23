-- balamod apis
local joker = require("joker")
local consumable = require("consumable")
local utils = require("utils")

-- configs
local configs = {
    remove_other_jokers = false,
}
----------------------
-- helper functions --
----------------------
-- card is the card that had its effect procced, eval is calculate_joker return
-- i think im just gonna ditch this and have each card do card_eval_status_text on its own
local function sap_effects(card, eval)
    if eval.message then
        local extra = {
            message = eval.message,
            colour = eval.colour
        }
        card_eval_status_text(card, 'extra', nil, nil, nil, extra)
    end
end

-- change "card"s SAP chips value by "value", then start an eval step
local function ease_sap_chips(card, value, from_eval)
    card.ability.arachnei_sap.chips = card.ability.arachnei_sap.chips + value
    for i=1, #G.jokers.cards do
        local eval = G.jokers.cards[i]:calculate_joker{ease_chips = {value=value}, individual=true, other_card=card, from_eval=from_eval}
        if eval then
            -- sap_effects(G.joker.cards[i], eval)
        end
    end
end
-- change "card"s SAP mult value by "value", then start an eval step
local function ease_sap_mult(card, value, from_eval)
    card.ability.arachnei_sap.mult = card.ability.arachnei_sap.mult + value
    for i=1, #G.jokers.cards do
        local eval = G.jokers.cards[i]:calculate_joker{ease_mult = {value=value}, individual=true, other_card=card, from_eval=from_eval}
        if eval then
            -- sap_effects(G.joker.cards[i], eval)
        end
    end
end
-- change "card"s SAP xmult value by "value", then start an eval step
local function ease_sap_xmult(card, value, from_eval)
    card.ability.arachnei_sap.xmult = card.ability.arachnei_sap.xmult + value
    for i=1, #G.jokers.cards do
        local eval = G.jokers.cards[i]:calculate_joker{ease_xmult = {value=value}, individual=true, other_card=card, from_eval=from_eval}
        if eval then
            -- sap_effects(G.joker.cards[i], eval)
        end
    end
end
local function ease_sap_xp(card, value, from_eval)
    local old_xp = card.ability.arachnei_sap.xp
    card.ability.arachnei_sap.xp = card.ability.arachnei_sap.xp + value
    local new_xp = card.ability.arachnei_sap.xp
    if (old_xp < 3 and new_xp >= 3) then
        card_eval_status_text(card, 'extra', nil, nil, nil, {
            message = localize("k_level_up_ex")
        })
        play_sound('polychrome1')
        for i=1, #G.jokers.cards do
            G.jokers.cards[i]:calculate_joker({level_up = true, other_card = card})
        end
    end
    if (old_xp < 6 and new_xp >= 6) then
        card_eval_status_text(card, 'extra', nil, nil, nil, {
            message = localize("k_level_up_ex")
        })
        play_sound('polychrome1')
        for i=1, #G.jokers.cards do
            G.jokers.cards[i]:calculate_joker({level_up = true, other_card = card})
        end
    end
    for i=1, #G.jokers.cards do
        G.jokers.cards[i]:calculate_joker({xp_gained = true, other_card = G.jokers.cards[i]})
    end
end
----------------------
-- button callbacks --
----------------------
G.FUNCS.can_absorb_card = function(e)
    for i=1, #G.jokers.cards do
        if G.jokers.cards[i].unique_val == e.config.ref_table.unique_val then
            if G.jokers.cards[i+1] and G.jokers.cards[i+1].config.center.key == e.config.ref_table.config.center.key then
                e.config.colour = G.C.PURPLE
                e.config.button = 'absorb_card'
            else
                e.config.colour = G.C.UI.BACKGROUND_INACTIVE
                e.config.button = nil
            end
            break
        end
    end
end
G.FUNCS.absorb_card = function(e)
    local card = e.config.ref_table
    for i=1, #G.jokers.cards do
        if G.jokers.cards[i].unique_val == card.unique_val then
            card:juice_up(0.8, 0.8)
            G.jokers.cards[i+1]:start_dissolve({G.C.GOLD}, true)
            local xp_gain = G.jokers.cards[i+1].ability.arachnei_sap.xp
            G.jokers:remove_card(G.jokers.cards[i+1])
            ease_sap_xp(card, xp_gain)
            break
        end
    end
end
-------------------------
-- decorator functions --
-------------------------
local function decorate()
    local card_set_ability = Card.set_ability
    function Card:set_ability(center, initial, delay_sprites)
        -- if changing edition, save the old sap stats
        local old_sap_stats = self.ability and self.ability.arachnei_sap
        
        card_set_ability(self, center, initial, delay_sprites)

        -- if set_ability is being called for changing the edition of a card, use old_sap_stats instead
        if old_sap_stats then
            self.ability.arachnei_sap = old_sap_stats
        elseif center.set ~= "Enhanced" and (self.config.center.set == "Joker" or self.config.center.set == "Default") then
            -- not sure if this section ever gets reached, but gonna keep it since it MIGHT break something on removal
            if self.config.center.config.base_stats then
                self.ability.arachnei_sap = self.config.center.config.base_stats
                self.config.center.arachnei_sap = self.ability.arachnei_sap
            else
                self.ability.arachnei_sap = {chips=0, mult=0, xmult=1, xp=1}
                self.config.center.arachnei_sap = self.ability.arachnei_sap
            end
        end
    end

    -- add mod specific parameters to jokers+playing cards
    local card_init = Card.init
    function Card:init(X, Y, W, H, card, center, params)
        card_init(self, X, Y, W, H, card, center, params)
        if self.config.center.set == "Joker" or self.config.center.set == "Default" then
            if self.config.center.config.base_stats then
                self.ability.arachnei_sap = self.config.center.config.base_stats
                self.config.center.arachnei_sap = self.ability.arachnei_sap
            else
                self.ability.arachnei_sap = {chips=0, mult=0, xmult=1}
                if self.config.center.set == "Joker" then
                    self.ability.arachnei_sap.xp = 1
                end
                self.config.center.arachnei_sap = self.ability.arachnei_sap
            end
        end
    end

    ----------------------------
    -- playing card sap stats --
    local card_get_chip_mult = Card.get_chip_mult
    function Card:get_chip_mult()
        local old_return = card_get_chip_mult(self)
        old_return = old_return + self.ability.arachnei_sap.mult
        return old_return
    end
    local card_get_chip_x_mult = Card.get_chip_x_mult
    function Card:get_chip_x_mult(context)
        local old_return = card_get_chip_x_mult(self, context)
        old_return = old_return + self.ability.arachnei_sap.xmult
        if old_return == 1 then
            old_return = 0
        end
        return old_return
    end
    local card_get_chip_bonus = Card.get_chip_bonus
    function Card:get_chip_bonus()
        local old_return = card_get_chip_bonus(self)
        old_return = old_return + self.ability.arachnei_sap.chips
        return old_return
    end
    ----------------------------

    local card_generate_uibox_ability_table = Card.generate_UIBox_ability_table
    function Card:generate_UIBox_ability_table()
        local old_return = card_generate_uibox_ability_table(self)
        -- if hovered card is a joker or a playing card,
        -- prepend SAP tooltip to info
        if self.config.center.set == "Joker" or self.config.center.set == "Default" or self.config.center.set == "Enhanced" and 
        G.STATE ~= G.STATES.MENU and G.STATE ~= G.STATES.TUTORIAL then
            sap_stats_node = {name="SAP Stats"}
            localize{type='other', key="sap_stats_loc", nodes=sap_stats_node, vars={self.ability.arachnei_sap.chips,self.ability.arachnei_sap.mult,self.ability.arachnei_sap.xmult,self.ability.arachnei_sap.xp}}
            table.insert(old_return.info, 1, sap_stats_node)
        end
        return old_return
    end
    
    local card_calculate_joker = Card.calculate_joker
    function Card:calculate_joker(context)
        local old_return = card_calculate_joker(self, context)
        if self.ability.set == "Joker" and context.joker_main and context.cardarea == G.jokers and not context.before and not context.after and not context.blueprint then
            -------------------------
            -- calculate SAP stats --
            if self.ability.arachnei_sap.chips > 0 then
                hand_chips = mod_chips(hand_chips + self.ability.arachnei_sap.chips)
                update_hand_text({delay = 0.2}, {chips = hand_chips})
                card_eval_status_text(self, 'extra', nil, nil, nil, {
                    message = localize{type='variable', key='a_chips', vars = {self.ability.arachnei_sap.chips}},
                    colour = G.C.CHIPS
                })
            end
            if self.ability.arachnei_sap.mult > 0 then
                mult = mod_mult(self.ability.arachnei_sap.mult + mult)
                update_hand_text({delay = 0.2}, {mult = mult})
                card_eval_status_text(self, 'extra', nil, nil, nil, {
                    message = localize{type='variable', key='a_mult', vars = {self.ability.arachnei_sap.mult}},
                    colour = G.C.MULT
                })
            end
            if self.ability.arachnei_sap.xmult ~= 1 then
                mult = mod_mult(mult * self.ability.arachnei_sap.xmult)
                update_hand_text({delay = 0.2}, {mult = mult})
                card_eval_status_text(self, 'extra', nil, nil, nil, {
                    message = localize{type='variable', key='a_xmult', vars = {self.ability.arachnei_sap.xmult}},
                    colour = G.C.XMULT
                })
            end
            -------------------------
        end
        return old_return
    end

    local card_add_to_deck = Card.add_to_deck
    function Card:add_to_deck(from_debuff)
        local old_return = card_add_to_deck(self, from_debuff)
        -- depreciated, using absorb button now ----------------------------- read this line
        --------------------------------
        -- handling buying duplicates --
        -- if self.children.buy_button then -- adding to deck from shop
        --     for i=1, #G.jokers.cards do
        --         if self.config.center.key == G.jokers.cards[i].config.center.key then -- duplicate bought
        --             G.jokers.cards[i].ability.arachnei_sap.xp = G.jokers.cards[i].ability.arachnei_sap.xp + 1
        --             G.jokers.cards[i]:juice_up(0.8, 0.8)
        --             self:juice_up(0.8, 0.8)
        --             self:start_dissolve({G.C.GOLD}, true)
        --             if G.jokers.cards[i].ability.arachnei_sap.xp == 3 or G.jokers.cards[i].ability.arachnei_sap.xp == 6 then
        --                 card_eval_status_text(G.jokers.cards[i], 'extra', nil, nil, nil, {
        --                     message = localize("k_level_up_ex")
        --                 })
        --                 play_sound('polychrome1')
        --                 G.jokers.cards[i]:calculate_joker({self_level = true})
        --                 for k=1, #G.jokers.cards do
        --                     G.jokers.cards[k]:calculate_joker({ally_level = true, other_card = G.jokers.cards[i]})
        --                 end
        --             end
        --             G.jokers.cards[i]:calculate_joker({gained_xp = true})
        --             for k=1, #G.jokers.cards do
        --                 G.jokers.cards[k]:calculate_joker({ally_xp = true, other_card = G.jokers.cards[i]})
        --             end
        --             break
        --         end
        --     end
        -- end
        --------------------------------
        return old_return
    end

    -- allow duplicates to spawn
    local misc_find_joker = find_joker
    function find_joker(name, non_debuff)
        if name == "Showman" then
            return {true}
        end
        return misc_find_joker(name, non_debuff)
    end

    local uidef_use_and_sell_buttons = G.UIDEF.use_and_sell_buttons
    function G.UIDEF.use_and_sell_buttons(card)
        local old_return = uidef_use_and_sell_buttons(card)
        if card.area and card.area.config.type == 'joker' then
            table.insert(old_return.nodes[1].nodes, {n=G.UIT.R, config={align='cl'}, nodes={
                {n=G.UIT.C, config={align = "cr"}, nodes={
                    {n=G.UIT.C, config={ref_table = card, align = "cr",padding = 0.1, r=0.08, minw = 1.25, hover = true, shadow = true, colour = G.C.UI.BACKGROUND_INACTIVE, one_press = true, button = 'sell_card', func = 'can_absorb_card'}, nodes={
                        {n=G.UIT.B, config = {w=0.1,h=0.6}},
                        {n=G.UIT.T, config={text = "Absorb",colour = G.C.UI.TEXT_LIGHT, scale = 0.55, shadow = true}}
                    }}
                }}
            }})
        end
        return old_return
    end

    local game_start_run = Game.start_run
    function Game:start_run(args)
        game_start_run(self, args)
        if not G.GAME.arachnei_sap then
            G.GAME.arachnei_sap = {permanent_shop_buff={chips=0, mult=0, xmult=0}}
        end
    end
end
---------------
-- card data --
---------------
-- level breakpoints --
local tier_1_pets = {
    {
        id = "j_ant_arachnei",
        name = "Ant",
        desc = {
            "On the {C:attention}first hand{} played, {C:inactive}#3#{}{C:attention}#4#{}{C:inactive}#5#{}",
            "random cards in hand permanently gains",
            "{C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult"
        },
        loc_vars = function(card)
            local loc_vars = {card.ability.extra.chips, card.ability.extra.mult}
            -- level vars
            if card.ability.arachnei_sap.xp >= 6 then       -- level 3
                loc_vars[3] = "1/2/"
                loc_vars[4] = "3"
                loc_vars[5] = ""
            elseif card.ability.arachnei_sap.xp >= 3 then   -- level 2
                loc_vars[3] = "1/"
                loc_vars[4] = "2"
                loc_vars[5] = "/3"
            else                                            -- level 1
                loc_vars[3] = ""
                loc_vars[4] = "1"
                loc_vars[5] = "/2/3"
            end
            return loc_vars
        end,
        cost = 4,
        rarity = 1,
        config = {extra={chips=1, mult=1}},
        calculate_joker_effect = function(card, context)
            -- first hand played effect
            if card.ability.name == "Ant" and G.GAME.current_round.hands_played == 0 and context.cardarea == G.jokers and context.before then 
                local level = math.min(math.floor(card.ability.arachnei_sap.xp/3)+1, 3)
                for i=1, level do
                    local upgrade_card = pseudorandom_element(G.hand.cards, pseudoseed(G.GAME.round..i..'sapets_ant_proc'))
                    ease_sap_chips(upgrade_card, card.ability.extra.chips, true)
                    card_eval_status_text(upgrade_card, 'extra', nil, nil, nil, {
                        message = localize('k_upgrade_ex'),
                        colour = G.C.CHIPS
                    })
                    ease_sap_mult(upgrade_card, card.ability.extra.mult, true)
                    card_eval_status_text(upgrade_card, 'extra', nil, nil, nil, {
                        message = localize('k_upgrade_ex'),
                        colour = G.C.MULT
                    })
                end
            end
            -- visual effect for first hand
            if card.ability.name == "Ant" and context.first_hand_drawn and not context.blueprint then
                local eval = function() return G.GAME.current_round.hands_played == 0 end
                juice_card_until(card, eval, true)
            end
        end,
        yes_pool_flag = nil,
    }, 
    {
        id = "j_beaver_arachnei",
        name = "Beaver",
        desc = {
            "Whenever you buy a {C:attention}Beaver{},",
            "including this one, give all cards",
            "in your deck +{C:inactive}#1#{}{C:chips}#2#{}{C:inactive}#3#{} Chips"
        },
        loc_vars = function(card)
            loc_vars = {}
            if card.ability.arachnei_sap.xp >= 6 then       -- level 3
                loc_vars[1] = "1/2/"
                loc_vars[2] = "3"
                loc_vars[3] = ""
            elseif card.ability.arachnei_sap.xp >= 3 then   -- level 2
                loc_vars[1] = "1/"
                loc_vars[2] = "2"
                loc_vars[3] = "/3"
            else                                            -- level 1
                loc_vars[1] = ""
                loc_vars[2] = "1"
                loc_vars[3] = "/2/3"
            end
            return loc_vars
        end,
        cost = 4,
        rarity = 1,
        config = {extra={chips=1}},
        add_to_deck_effect = function(card, from_debuff)
            if card.ability.name == "Beaver" then
                for i=1, #G.jokers.cards do
                    if G.jokers.cards[i].config.center.key == "j_beaver_arachnei" then
                        G.jokers.cards[i]:juice_up(0.8, 0.8)
                        card_eval_status_text(G.jokers.cards[i], 'extra', nil, nil, nil, {
                            message = localize('k_upgrade_ex'),
                            colour = G.C.CHIPS
                        })
                        for k=1, #G.deck.cards do
                            ease_sap_chips(G.deck.cards[k], G.jokers.cards[i].ability.extra.chips * math.min(math.floor(G.jokers.cards[i].ability.arachnei_sap.xp/3)+1, 3))
                        end
                    end
                end
                card:juice_up(0.8, 0.8)
                card_eval_status_text(card, 'extra', nil, nil, nil, {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.CHIPS
                })
                for k=1, #G.deck.cards do
                    ease_sap_chips(G.deck.cards[k], card.ability.extra.chips * math.min(math.floor(card.ability.arachnei_sap.xp/3)+1, 3))
                end
            end
        end
    },
    "j_cricket_arachnei", 
    "j_duck_arachnei", 
    {
        id = "j_fish_arachnei",
        name = "Fish",
        desc = {
            "Whenever this levels up,",
            "give another Joker +{C:inactive}#1#{}{C:mult}#2#{}{C:inactive}#3#{} Mult"
        },
        loc_vars = function(card)
            loc_vars = {}
            if card.ability.arachnei_sap.xp >= 6 then       -- level 3
                loc_vars[1] = "1/2/"
                loc_vars[2] = "3"
                loc_vars[3] = ""
            elseif card.ability.arachnei_sap.xp >= 3 then   -- level 2
                loc_vars[1] = "1/"
                loc_vars[2] = "2"
                loc_vars[3] = "/3"
            else                                            -- level 1
                loc_vars[1] = ""
                loc_vars[2] = "1"
                loc_vars[3] = "/2/3"
            end
            return loc_vars
        end,
        cost = 4,
        rarity = 1,
        config = {extra={mult=1}},
        calculate_joker_effect = function(card, context)
            if context.level_up and context.other_card.unique_val == card.unique_val then
                local candidates = {}
                for i=1, #G.jokers.cards do
                    if card.unique_val ~= G.jokers.cards[i].unique_val then
                        table.insert(candidates, i)
                    end
                end
                logger:info("a")
                if #candidates == 0 then
                    for i=1, #G.jokers.cards do
                        table.insert(candidates, i)
                    end
                end
                logger:info("b")
                local chosen = pseudorandom_element(candidates, pseudoseed("arachneifishproc"..G.GAME.round))
                logger:info("chosen: ".. chosen)
                ease_sap_mult(G.jokers.cards[chosen], card.ability.extra.mult * math.min(math.floor(card.ability.arachnei_sap.xp/3)+1, 3), true)
            end
        end,
    }, 
    "j_horse_arachnei", 
    "j_mosquito_arachnei", 
    "j_otter_arachnei", 
    "j_pig_arachnei", 
    "j_pigeon_arachnei", 
    "j_baku_arachnei", 
    "j_axehandle_hound_arachnei", 
    "j_barghest_arachnei", 
    "j_tsuchinoko_arachnei", 
    "j_murmel_arachnei", 
    "j_alchemedes_arachnei", 
    "j_warg_arachnei", 
    "j_bunyip_arachnei", 
    "j_sneaky_egg_arachnei", 
    "j_cuddle_toad_arachnei", 
    {
        id="j_basilisk_arachnei"
    }, 
    "j_bulldog_arachnei", 
    "j_chipmunk_arachnei", 
    "j_groundhog_arachnei", 
    "j_cone_snail_arachnei", 
    "j_goose_arachnei", 
    "j_pied_tamarin_arachnei", 
    "j_opossum_arachnei", 
    "j_silkmoth_arachnei", 
    "j_magpie_arachnei", 
    "j_cockroach_arachnei", 
    "j_duckling_arachnei", 
    "j_frog_arachnei", 
    "j_hummingbird_arachnei", 
    "j_kiwi_arachnei", 
    "j_marmoset_arachnei", 
    "j_mouse_arachnei", 
    "j_pillbug_arachnei", 
    "j_seahorse_arachnei", 
    "j_beetle_arachnei", 
    "j_blue_bird_arachnei", 
    "j_chinchilla_arachnei", 
    "j_ferret_arachnei", 
    "j_gecko_arachnei", 
    "j_ladybug_arachnei", 
    "j_moth_arachnei", 
    "j_frilled_dragon_arachnei", 
    "j_sloth_arachnei",
}
local tier_2_pets = {
    "j_crab_arachnei", "j_flamingo_arachnei", "j_hedgehog_arachnei", "j_kangaroo_arachnei", "j_peacock_arachnei", "j_rat_arachnei", 
    "j_snail_arachnei", "j_spider_arachnei", "j_swan_arachnei", "j_worm_arachnei", "j_ghost_kitten_arachnei", "j_frost_wolf_arachnei", 
    "j_mothman_arachnei", "j_drop_bear_arachnei", "j_jackalope_arachnei", "j_lucky_cat_arachnei", "j_ogopogo_arachnei", "j_thunderbird_arachnei", 
    "j_gargoyle_arachnei", "j_bigfoot_arachnei", "j_nightcrawler_arachnei", "j_sphinx_arachnei", "j_chupacabra_arachnei", "j_golden_beetle_arachnei", 
    "j_african_penguin_arachnei", "j_black_necked_stilt_arachnei", "j_door_head_ant_arachnei", "j_gazelle_arachnei", "j_hercules_beetle_arachnei", "j_lizard_arachnei", 
    "j_sea_turtle_arachnei", "j_sea_urchin_arachnei", "j_squid_arachnei", "j_stoat_arachnei", "j_atlantic_puffin_arachnei", "j_dove_arachnei", 
    "j_guinea_pig_arachnei", "j_iguana_arachnei", "j_jellyfish_arachnei", "j_koala_arachnei", "j_panda_arachnei", "j_salamander_arachnei", 
    "j_stork_arachnei", "j_yak_arachnei", "j_bat_arachnei", "j_beluga_sturgeon_arachnei", "j_dromedary_arachnei", "j_frigatebird_arachnei", 
    "j_lemur_arachnei", "j_mandril_arachnei", "j_robin_arachnei", "j_shrimp_arachnei", "j_tabby_cat_arachnei", "j_toucan_arachnei", 
    "j_wombat_arachnei", 
}
local tier_3_pets = {
    "j_badger_arachnei", "j_camel_arachnei", "j_dodo_arachnei", "j_dog_arachnei", "j_dolphin_arachnei", 
    "j_elephant_arachnei", "j_giraffe_arachnei", "j_ox_arachnei", "j_rabbit_arachnei", "j_sheep_arachnei", "j_skeleton_dog_arachnei", 
    "j_mandrake_arachnei", "j_fur-bearing_trout_arachnei", "j_mana_hound_arachnei", "j_calygreyhound_arachnei", "j_brain_cramp_arachnei", "j_minotaur_arachnei", 
    "j_wyvern_arachnei", "j_ouroboros_arachnei", "j_griffin_arachnei", "j_foo_dog_arachnei", "j_tree_ent_arachnei", "j_slime_arachnei", 
    "j_pegasus_arachnei", "j_deer_lord_arachnei", "j_baboon_arachnei", "j_betta_fish_arachnei", "j_flea_arachnei", "j_flying_fish_arachnei", 
    "j_guineafowl_arachnei", "j_meerkat_arachnei", "j_musk_ox_arachnei", "j_osprey_arachnei", "j_royal_flycatcher_arachnei", "j_surgeon_fish_arachnei", 
    "j_weasel_arachnei", "j_anteater_arachnei", "j_capybara_arachnei", "j_cassowary_arachnei", "j_eel_arachnei", "j_leech_arachnei", 
    "j_okapi_arachnei", "j_pug_arachnei", "j_toad_arachnei", "j_woodpecker_arachnei", "j_flying_squirrel_arachnei", "j_gold_fish_arachnei", 
    "j_hare_arachnei", "j_hatching_chick_arachnei", "j_hoopoe_bird_arachnei", "j_mole_arachnei", "j_owl_arachnei", "j_pangolin_arachnei", 
    "j_puppy_arachnei", "j_tropical_fish_arachnei", "j_aardvark_arachnei", "j_bear_arachnei", "j_emperor_tamarin_arachnei", "j_porcupine_arachnei", 
    "j_wasp_arachnei", 
}
local tier_4_pets = {
    "j_bison_arachnei", "j_blowfish_arachnei", "j_deer_arachnei", "j_hippo_arachnei", "j_parrot_arachnei", 
    "j_penguin_arachnei", "j_skunk_arachnei", "j_squirrel_arachnei", "j_turtle_arachnei", "j_whale_arachnei", "j_unicorn_arachnei", 
    "j_kraken_arachnei", "j_visitor_arachnei", "j_tiger_bug_arachnei", "j_tatzelwurm_arachnei", "j_cyclops_arachnei", "j_chimera_arachnei", 
    "j_roc_arachnei", "j_worm_of_sand_arachnei", "j_abomination_arachnei", "j_fairy_arachnei", "j_rootling_arachnei", "j_anubis_arachnei", 
    "j_old_mouse_arachnei", "j_hippocampus_arachnei", "j_cockatoo_arachnei", "j_cuttlefish_arachnei", "j_falcon_arachnei", "j_manatee_arachnei", 
    "j_manta_ray_arachnei", "j_poison_dart_frog_arachnei", "j_saiga_antelope_arachnei", "j_sealion_arachnei", "j_secretary_bird_arachnei", "j_slug_arachnei", 
    "j_vaquita_arachnei", "j_blobfish_arachnei", "j_clownfish_arachnei", "j_crow_arachnei", "j_donkey_arachnei", "j_hawk_arachnei", 
    "j_orangutan_arachnei", "j_pelican_arachnei", "j_platypus_arachnei", "j_praying_mantis_arachnei", "j_starfish_arachnei", "j_buffalo_arachnei", 
    "j_caterpillar_arachnei", "j_chameleon_arachnei", "j_doberman_arachnei", "j_gharial_arachnei", "j_llama_arachnei", "j_lobster_arachnei", 
    "j_microbe_arachnei", "j_tahr_arachnei", "j_whale_shark_arachnei", "j_dragonfly_arachnei", "j_jerboa_arachnei", "j_lynx_arachnei", 
    "j_seagull_arachnei", 
}
local tier_5_pets = {
    "j_armadillo_arachnei", "j_cow_arachnei", "j_crocodile_arachnei", "j_monkey_arachnei", "j_rhino_arachnei", 
    "j_rooster_arachnei", "j_scorpion_arachnei", "j_seal_arachnei", "j_shark_arachnei", "j_turkey_arachnei", "j_red_dragon_arachnei", 
    "j_vampire_bat_arachnei", "j_loveland_frogman_arachnei", "j_salmon_of_knowledge_arachnei", "j_jersey_devil_arachnei", "j_pixiu_arachnei", "j_kitsune_arachnei", 
    "j_nessie_arachnei", "j_bad_dog_arachnei", "j_werewolf_arachnei", "j_boitata_arachnei", "j_kappa_arachnei", "j_mimic_arachnei", 
    "j_nurikabe_arachnei", "j_tandgnost_arachnei", "j_tandgrisner_arachnei", "j_beluga_whale_arachnei", "j_blue_ringed_octopus_arachnei", "j_crane_arachnei", 
    "j_egyptian_vulture_arachnei", "j_emu_arachnei", "j_fire_ant_arachnei", "j_macaque_arachnei", "j_nurse_shark_arachnei", "j_nyala_arachnei", 
    "j_silver_fox_arachnei", "j_wolf_arachnei", "j_fox_arachnei", "j_hamster_arachnei", "j_lion_arachnei", "j_polar_bear_arachnei", 
    "j_shoebill_arachnei", "j_siberian_husky_arachnei", "j_sword_fish_arachnei", "j_triceratops_arachnei", "j_vulture_arachnei", "j_zebra_arachnei", 
    "j_axolotl_arachnei", "j_chicken_arachnei", "j_eagle_arachnei", "j_goat_arachnei", "j_mosasaurus_arachnei", "j_panther_arachnei", 
    "j_poodle_arachnei", "j_snapping_turtle_arachnei", "j_sting_ray_arachnei", "j_stonefish_arachnei", "j_alpaca_arachnei", "j_hyena_arachnei", 
    "j_moose_arachnei", "j_raccoon_arachnei",
} 
local tier_6_pets = { 
    "j_boar_arachnei", "j_cat_arachnei", "j_dragon_arachnei", "j_fly_arachnei", 
    "j_gorilla_arachnei", "j_leopard_arachnei", "j_mammoth_arachnei", "j_snake_arachnei", "j_tiger_arachnei", "j_wolverine_arachnei", 
    "j_manticore_arachnei", "j_phoenix_arachnei", "j_quetzalcoatl_arachnei", "j_team_spirit_arachnei", "j_sleipnir_arachnei", "j_sea_serpent_arachnei", 
    "j_yeti_arachnei", "j_cerberus_arachnei", "j_hydra_arachnei", "j_behemoth_arachnei", "j_great_one_arachnei", "j_leviathan_arachnei", 
    "j_questing_beast_arachnei", "j_cockatrice_arachnei", "j_bird_of_paradise_arachnei", "j_catfish_arachnei", "j_cobra_arachnei", "j_german_shephard_arachnei", 
    "j_grizzly_bear_arachnei", "j_highland_cow_arachnei", "j_oyster_arachnei", "j_pteranodon_arachnei", "j_warthog_arachnei", "j_wildebeest_arachnei", 
    "j_hammerhead_shark_arachnei", "j_komodo_arachnei", "j_orca_arachnei", "j_ostrich_arachnei", "j_piranha_arachnei", "j_reindeer_arachnei", 
    "j_sabertooth_tiger_arachnei", "j_spinosaurus_arachnei", "j_stegosaurus_arachnei", "j_velociraptor_arachnei", "j_anglerfish_arachnei", "j_elephant_seal_arachnei", 
    "j_lionfish_arachnei", "j_mantis_shrimp_arachnei", "j_mongoose_arachnei", "j_octopus_arachnei", "j_puma_arachnei", "j_sauropod_arachnei", 
    "j_tyrannosaurus_arachnei", "j_lioness_arachnei", "j_tapir_arachnei", "j_walrus_arachnei", "j_white_tiger_arachnei", "j_good_dog_arachnei", 
}
local tier_1_foods = {
    "c_apple_arachnei", "c_honey_arachnei", "c_water_of_youth_arachnei", "c_love_potion_arachnei", "c_egg_arachnei", "c_peach_arachnei", 
    "c_strawberry_arachnei", "c_bacon_arachnei", "c_blueberry_arachnei", "c_cookie_arachnei",
    "c_cupcake_arachnei", "c_meatbone_arachnei", 
}
local tier_2_foods = {
    "c_sleeping_pill_arachnei", "c_wall_chicken_arachnei", "c_fairy_dust_arachnei", "c_health_potion_arachnei", "c_cherry_arachnei", "c_chocolate_cake_arachnei", 
    "c_broccoli_arachnei", "c_fried_shrimp_arachnei", "c_rice_arachnei", 
}
local tier_3_foods = {
    "c_garlic_arachnei", "c_salad_arachnei", "c_gingerbread_man_arachnei", 
    "c_easter_egg_arachnei", "c_just-right_porridge_arachnei", "c_fig_arachnei", "c_lettuce_arachnei", "c_avocado_arachnei", "c_cucumber_arachnei", 
    "c_lollipop_arachnei", "c_croissant_arachnei", "c_pineapple_arachnei", 
}
local tier_4_foods = {
    "c_canned_food_arachnei", "c_pear_arachnei", "c_banana_arachnei", 
    "c_potato_arachnei", "c_waffle_arachnei", "c_cheese_arachnei", "c_grapes_arachnei", "c_pie_arachnei", "c_salt_arachnei", 
    "c_donut_arachnei", "c_fortune_cookie_arachnei", 
}
local tier_5_foods = {
    "c_chili_arachnei", "c_chocolate_arachnei", "c_sushi_arachnei", "c_yggdrasil_fruit_arachnei", 
    "c_mana_potion_arachnei", "c_durian_arachnei", "c_onion_arachnei", "c_carrot_arachnei", "c_pepper_arachnei", "c_stew_arachnei", 
    "c_taco_arachnei", "c_lasagna_arachnei", "c_lemon_arachnei", "c_eggplant_arachnei", 
}
local tier_6_foods = {
    "c_melon_arachnei", "c_mushroom_arachnei", 
    "c_pizza_arachnei", "c_steak_arachnei", "c_konpeito_arachnei", "c_peach_of_immortality_arachnei", "c_cornucopia_arachnei", "c_pita_bread_arachnei", 
    "c_pretzel_arachnei", "c_tomato_arachnei", "c_hotdog_arachnei", "c_orange_arachnei", "c_popcorn_arachnei", "c_pancakes_arachnei", 
    "c_chicken_leg_arachnei", "c_soft_ice_arachnei", 
}
local special_foods = {
    "c_bread_crumbs_arachnei", "c_rambutan_arachnei", "c_golden_egg_arachnei", "c_milk_arachnei", 
    "c_skewer_arachnei", "c_peg_leg_arachnei", "c_coconut_arachnei", "c_peanut_arachnei", "c_holy_water_arachnei", 
}
local tier_1_toys = { "t_balloon_arachnei", "t_tennis_ball_arachnei" }
local tier_2_toys = { "t_radio_arachnei", "t_garlic_press_arachnei" }
local tier_3_toys = { "t_toilet_paper_arachnei", "t_oven_mitts_arachnei" }
local tier_4_toys = { "t_melon_helmet_arachnei", "t_foam_sword_arachnei", "t_toy_gun_arachnei" }
local tier_5_toys = { "t_flashlight_arachnei", "t_stinky_sock_arachnei" }
local tier_6_toys = { "t_television_arachnei", "t_peanut_jar_arachnei", "t_air_palm_tree_arachnei" }
local witch_toys = { "t_witch_broom_arachnei", "t_magic_wand_arachnei", "t_crystal_ball_arachnei" }
local adventurous_toys = { "t_magic_carpet_arachnei", "t_magic_lamp_arachnei" }
local treasure_toys = { "t_treasure_map_arachnei", "t_treasure_chest_arachnei" }
local wondrous_toys = { "t_nutcracker_arachnei", "t_tinder_box_arachnei" }
local nostalgic_toys = { 
    "t_candelabra_arachnei", "t_glass_shoes_arachnei", "t_golden_harp_arachnei", "t_lock_of_hair_arachnei", 
    "t_magic_mirror_arachnei", "t_pickaxe_arachnei", "t_red_cape_arachnei", "t_rosebud_arachnei" 
}
local chaos_toys = { "t_pandoras_box_arachnei", "t_evil_book_arachnei" }
local king_toys = { "t_excalibur_arachnei", "t_holy_grail_arachnei" }

local all_cards = {
    {name="tier_1_pets", data=tier_1_pets},
    {name="tier_2_pets", data=tier_2_pets},
    {name="tier_3_pets", data=tier_3_pets},
    {name="tier_4_pets", data=tier_4_pets},
    {name="tier_5_pets", data=tier_5_pets},
    {name="tier_6_pets", data=tier_6_pets},
    {name="tier_1_foods", data=tier_1_foods},
    {name="tier_2_foods", data=tier_2_foods},
    {name="tier_3_foods", data=tier_3_foods},
    {name="tier_4_foods", data=tier_4_foods},
    {name="tier_5_foods", data=tier_5_foods},
    {name="tier_6_foods", data=tier_6_foods},
    {name="special_foods", data=special_foods},
    {name="tier_1_toys", data=tier_1_toys},
    {name="tier_2_toys", data=tier_2_toys},
    {name="tier_3_toys", data=tier_3_toys},
    {name="tier_4_toys", data=tier_4_toys},
    {name="tier_5_toys", data=tier_5_toys},
    {name="tier_6_toys", data=tier_6_toys},
    {name="witch_toys", data=witch_toys},
    {name="adventurous_toys", data=adventurous_toys},
    {name="treasure_toys", data=treasure_toys},
    {name="wondrous_toys", data=wondrous_toys},
    {name="nostalgic_toys", data=nostalgic_toys},
    {name="chaos_toys", data=chaos_toys},
    {name="king_toys", data=king_toys},
}


local function on_enable()
    local sap_stats_loc = {
        name = "SAP Stats",
        text = {
            "Chips: {C:chips}+#1#",
            "Mult: {C:mult}+#2#",
            "XMult: {X:mult,C:white}X#3#",
            "Experience: {C:purple}#4#"
        },
        name_parsed = {},
        text_parsed = {}
    }
    for _, line in ipairs(sap_stats_loc.text) do
        sap_stats_loc.text_parsed[#sap_stats_loc.text_parsed+1] = loc_parse_string(line)
    end
    G.localization.descriptions.Other.sap_stats_loc = sap_stats_loc
    -- must decorate in on_enable to get proper stack
    decorate()
    for i=1, #all_cards do
        local pool_name = all_cards[i].name
        local pool_data = all_cards[i].data
        for j=1, #pool_data do
            local card_data = pool_data[j]
            if type(card_data) == "table" then
                card_data.mod_id = "arachnei_sapets"
                if not card_data.consumable then
                    joker.add(card_data)
                else
                    consumable.add(card_data)
                end
            elseif type(card_data) == "string" then
                -- logger:info(card_data.." unimplemented. skipping...")
            end
        end
    end
end

return {
    on_enable = on_enable
}