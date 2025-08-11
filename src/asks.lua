local lapis = require("lapis")
local asks_app = lapis.Application()
local db = require("lapis.db")
local Model = require("lapis.db.model").Model

local users_table = Model:extend("users", {
    primary_key = "user_id"
})
local posts_table = Model:extend("posts", {
    primary_key = "post_id"
})
local asks_table = Model:extend("asks", {
    primary_key = "ask_id"
})

asks_app:post("ask-post", "/ask/:name", function(self)
    local recipient = users_table:find({
        username = self.params.name
    })
    local ask = {}
    if self.is_logged_in then
        ask = asks_table:create({
            sender_id = self.session.current_user_id,
            recipient_id = recipient.user_id,
            ask_content = self.params.askcontent
        })
    else
        return "<p>You are not logged in.</p>"
    end

    if ask.ask_id then
        return { redirect_to = self.req.headers.referer .. "?ask_sent=true" }
    end

    return "<p>Something went wrong.</p>"
end)

asks_app:get("answer", "/answer/:id", function(self)
    local ask = asks_table:select("JOIN users ON asks.sender_id = users.user_id WHERE ask_id = ? LIMIT 1",
        self.params.id)

    self.ask = {
        author = ask[1].username,
        content = ask[1].ask_content,
        answered = ask[1].answered,
        id = ask[1].ask_id
    }

    return {
        render = "answer"
    }
    -- return json.encode(ask)
end)

asks_app:post("answer", "/answer/:id", function(self)
    local ask = asks_table:find(self.params.id)

    if ask then
        local post = posts_table:create({
            answering_ask = self.params.id,
            post_content = self.params.askanswer,
            post_created_by = self.session.current_user_id,
            post_in_reply_to = db.NULL,
            post_reply_parent = db.NULL
        })
    else
        return { "<p>Something went wrong. That ask may not exist.</p>", status = 404 }
    end 

    ask:update({
        answered = true
    })
    
    return { redirect_to = "/" } -- replace with the posts uri
end)

return asks_app
