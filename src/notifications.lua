local lapis = require("lapis")
local notifications_app = lapis.Application()
local Model = require("lapis.db.model").Model

local notifications_table = Model:extend("notifications", {
    primary_key = "notification_id"
})

local 