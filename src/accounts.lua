local lapis = require("lapis")
local Model = require("lapis.db.model").Model

local uuid = require("lua-uuid")
local bcrypt = require("bcrypt")

local accounts_app = lapis.Application()

local sessions_table = Model:extend("sessions", {
    primary_key = "session_id"
})
local users_table = Model:extend("users", {
    primary_key = "user_id"
})

accounts_app:get("login", "/login", function(self)
    return { render = "login" }
end)

accounts_app:post("login", "/login", function(self)
    local account = users_table:find({
        username = self.params.username,
    })

    if account then
        if bcrypt.verify(self.params.password, account.password) then
            self.session.current_user = account.username
            self.session.current_user_id = account.user_id
            return { redirect_to = "/" }
        end
    end

end)


accounts_app:get("register", "/register", function(self)
    return { render = "register" }
end)

accounts_app:post("register", "/register", function(self)
    local user = users_table:create({
        username = self.params.username,
        password = bcrypt.digest(self.params.password, 10),
        user_email = self.params.email,
        display_name = self.params.username
    })
    if user then
        return { redirect_to = "/login" }
    else
        return "<center><p>Something went wrong</p></center>"
    end
end)
return accounts_app
