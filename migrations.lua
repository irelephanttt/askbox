local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types  


return {
    [1] = function()
        schema.create_table("users", {
            { "user_id", types.serial },
            { "username", types.varchar({ unique = true }) },
            { "user_email", types.varchar },
            { "display_name", types.varchar },
            { "password", types.text }, 
            { "bio", types.text({ null = true }) },
            { "admin", types.boolean({ default = false }) },
            { "created_timestamp", types.time({ default = db.raw("current_timestamp") }) },
            "PRIMARY KEY (user_id)"
        })
        schema.create_table("asks", {
            { "ask_id", types.serial },
            { "sender_id", types.integer, references = "users(user_id)" },
            { "recipient_id", types.integer, references = "users(user_id)" },
            { "ask_content", types.text },
            { "answered", types.boolean({ default = false }) },
            { "sent_time", types.time({ default = db.raw("current_timestamp") }) },
            "PRIMARY KEY (ask_id)"
        })
        schema.create_table("posts", {
            { "post_id", types.serial },
            { "answering_ask", types.integer({ null = true }), references = "asks(ask_id)" },
            { "post_content", types.text },
            { "post_in_reply_to", types.integer({ null = true }), references = "posts(post_id)" },
            { "post_reply_parent", types.integer({ null = true }), references = "posts(post_id)"},
            { "post_created_by", types.integer, references = "users(user_id)" },
            { "post_timestamp", types.time({ default = db.raw("current_timestamp") }) },
            "PRIMARY KEY (post_id)"
        })
        schema.create_table("follows", {
            { "follow_id", types.serial },
            { "follower_id", types.integer, references = "users(user_id)" },
            { "following_id", types.integer, references = "users(user_id)" },
            { "followed_date", types.time({ default = db.raw("current_timestamp") }) },
            "PRIMARY KEY (follow_id)"
        })
        schema.create_table("likes", {
            { "like_id", types.serial },
            { "like_sent_by", types.integer, references = "users(user_id)" },
            { "like_recipient", types.integer, references = "users(user_id)" },
            { "liked_post", types.integer, references = "posts(posts_id)" }
        })
        schema.create_table("notifications", {
            { "notification_id", types.serial },
            { "notification_recipient", types.integer, references = "users(user_id)" },
            { "notification_sender", types.integer, references = "users(user_id)" },
            { "notification_type", types.varchar },
            { "notification_in_reply_to", types.integer, references = "posts(post_id)" },
            { "notification_like_id", types.integer, references = "likes(like_id)" },
            { "notification_reply_id", types.integer, references = "posts(post_id)" },
            "PRIMARY KEY (notification_id)"
        })
        
    end
}