local lapis = require("lapis")
local feed_app = lapis.Application()
local Model = require("lapis.db.model").Model  

local posts_table = Model:extend("posts", {
    primary_key = "post_id"
})
local users_table = Model:extend("users", {
    primary_key = "user_id"
})

local asks_table = Model:extend("asks", {
    primary_key = "ask_id"
})

feed_app:get("feed", "/", function(self)
    if not self.is_logged_in then -- there's probably a better way to do this, will come back to this.
        return { redirect_to = "/login" }
    end

    
    local feed_posts = posts_table:select([[
        WHERE post_created_by IN (
            SELECT following_id
            FROM follows
            WHERE following_id = ?
        )
        ORDER BY post_timestamp DESC
    ]], self.session.current_user_id)
    
     
    users_table:include_in(feed_posts, "post_created_by", {
        as = "post_author"
    })
    asks_table:include_in(feed_posts, "answering_ask", {
        as = "ask"
    })
    for i, post in ipairs(feed_posts) do
        users_table:include_in({ post.ask }, "sender_id", {
            as = "sender"
        })
    end

    self.posts = {}

    for i, post in ipairs(feed_posts) do

        if post.ask then
            table.insert(self.posts, {
                user = {
                    username = post.post_author.display_name,
                    handle = post.post_author.username,
                    link = "/users/" .. post.post_author.username
                },
                ask = {
                    author = {
                        username = post.ask.sender.display_name,
                        handle = post.ask.sender.username,
                    },
                    content = post.ask.ask_content
                },
                type = "ask",
                content = post.post_content,
                link = "/post/" .. post.post_author.username .. "/" .. tostring(post.post_id)

            })
        elseif post.in_reply_to then
            print("TODO!")
        end 

    end
    --return { json = feed_posts }
    return { render = "feed" }

end)

return feed_app