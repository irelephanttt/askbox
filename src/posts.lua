local lapis = require("lapis")
local posts_app = lapis.Application()
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


posts_app:get("post", "/post/:username/:id", function(self)
    local post = posts_table:select("WHERE post_id = ? LIMIT 1", self.params.id)
    
    if post[1].post_created_by then
        users_table:include_in(post, "post_created_by", {
            as = "post_author"
        })
    else
        return { "not found.", status = 404 }
    end

    if post[1].answering_ask then
        asks_table:include_in(post, "answering_ask", {
            as = "post_ask"
        })
        users_table:include_in({ post[1].post_ask }, "recipient_id", {
            as = "recipient"
        })
    else 
        return { "something went wrong. ", status = 500 }
    end

    

    self.posts = {
        content = post[1].post_content,
        user = {
            handle = post[1].post_author.username,
            username = post[1].post_author.display_name,
            link = "/users/" .. post[1].post_author.username,
        },
        ask = {
            author = post[1].post_ask.recipient.username,
            content = post[1].post_ask.ask_content
        }
    }

    local post_replies = posts_table:select("WHERE post_reply_parent = ?", post[1].post_id)


    if #post_replies ~= 0 then
        self.posts.replies = {}

        users_table:include_in(post_replies, "post_created_by", {
            as = "post_author"
        })
        for _, reply in ipairs(post_replies) do
            table.insert(self.posts.replies, {
                user = {
                    link = "/users/" .. reply.post_author.username,
                    username = reply.post_author.display_name,
                    handle = reply.post_author.username
                },
                content = reply.post_content
            })
        end
    else
        self.posts.replies = false
    end
    
    return { render = "post" }
    --return { json = post }
end)

posts_app:post("reply", "/post", function(self)
    if self.params.in_reply_parent then
        posts_table:create({
            post_content = self.params.reply_content,
            post_created_by = self.session.current_user_id,
            post_reply_parent = self.params.in_reply_parent,
            post_in_reply_to = self.params.in_reply_parent, -- Change this after replies to replies are added.
        })
    
    else
        return { "not implemented", status = 501 }
    end
    return { redirect_to = self.req.headers["Referer"]  }
end)


posts_app:post("like", "/like", function(self)
    if self.params.post_id then
        local post = posts_table:find(self.params.post_id)
        local user = users_table:find(post.post_created_by)
        if post.post_id then
            local like = likes_table:create({
                liked_post = post.post_id,
                like_sent_by = self.session.current_user_id,
                like_recipient = user.user_id
            })

            if like then
                return { redirect_to = self.req.headers.referer .. "#" .. post.post_id }
            else 
                return { "Something went wrong.", status = 500 }
            end
        end
    end
end)


return posts_app

