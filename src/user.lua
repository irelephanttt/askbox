local lapis = require("lapis")
local user_app = lapis.Application()
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
local follows_table = Model:extend("follows", {
    primary_key = "follow_id"
})


user_app:get("profile-page", "/users/:name", function(self)
    local user = users_table:find({
        username = self.params.name
    })

    local user_posts = db.query([[
    SELECT
        posts.post_id AS post_id,
        posts.post_content AS post_content,
        posts.post_timestamp AS post_timestamp,
        asks.ask_id AS ask_id,
        asks.ask_content AS ask_content,
        asks.sender_id AS ask_sender_id,
        ask_user.username AS ask_sender_username
    FROM posts
    JOIN asks ON posts.answering_ask = asks.ask_id
    JOIN users AS ask_user ON asks.sender_id = ask_user.user_id
    WHERE posts.post_created_by = ?
        AND posts.post_in_reply_to IS NULL
    ]], user.user_id)

    

    
    self.user = {
        username = user.display_name,
        handle = user.username,
        bio = user.user_bio,
        id = user.user_id,
        posts = {}
    }

    if self.params.ask_sent == "true" then
        self.ask_message = "Ask sucessfully sent."
    elseif self.params.ask_sent == "fail" then
        self.ask_message = "Sending ask failed."
    end


    local is_following = follows_table:find({
        following_id = user.user_id,
        follower_id = self.session.current_user_id
    })

    
    
    if is_following then
        self.user.is_following = true
    else
        self.user.is_following = false
    end

    for i, post in ipairs(user_posts) do
        table.insert(self.user.posts, {
            ask = {
                author = post.ask_sender_username,
                content = post.ask_content
            },
            content = post.post_content,
            link = "/post/" .. user.username .. "/" .. post.post_id
        })
    end
    
    return { render = "user" }
    
end)



user_app:post("follow-user", "/follow", function(self)
    local is_following = follows_table:find({
        following_id = self.params.following_id,
        follower_id = self.session.current_user_id
    })

    if not is_following then
        local follow = follows_table:create({
            follower_id = self.session.current_user_id,
            following_id = self.params.following_id
        })
        if follow then
            return { redirect_to = self.req.headers.referer }
        else
            return { "<p>Something went wrong.</p>", status = 500 }
        end
    end
    
    return { "<p>Something went wrong. You may already be following this user.</p>", status = 409 }
end)


return user_app
