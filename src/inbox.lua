local lapis = require("lapis")
local inbox_app = lapis.Application()
local db = require("lapis.db")


inbox_app:get("inbox", "/inbox", function(self)
    local ask_notifications = db.query([[SELECT
    asks.ask_id AS ask_id,
    asks.sender_id AS ask_sender_id,
    asks.recipient_id AS ask_recipient_id,
    asks.ask_content AS ask_content,
    asks.answered AS ask_answered,
    asks.sent_time AS ask_timestamp,
    users.user_id AS user_id,
    users.username AS user_username,
    users.display_name AS user_display_name
    FROM asks
    JOIN users ON asks.sender_id = users.user_id
    WHERE asks.recipient_id = ?
    AND asks.answered = FALSE
    ORDER BY ask_timestamp DESC
    ]], self.session.current_user_id)

    local inbox_items = {}
    for _, item in ipairs(ask_notifications) do
        table.insert(inbox_items, {
            ask = {
                author = item.user_username,
                content = item.ask_content,
                answered = item.ask_answered,
                id = item.ask_id
            },
            timestamp = item.ask_timestamp
        })
    end
    self.inbox_items = inbox_items

    return {
        render = "inbox"
    }
end)


return inbox_app