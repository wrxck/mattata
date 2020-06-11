local redis = dofile('libs/redis.lua')
local disabled_plugin_keys = redis:keys('chat:*:disabled_plugins')
if next(disabled_plugin_keys) then
    for _, v in pairs(disabled_plugin_keys) do
        local plugins = redis:hgetall(v)
        if #plugins > 2 then
            for plugin, value in pairs(plugins) do
                if plugin then
                    if tostring(value) == 'true' then
                        local chat_id = v:match(':(%-?%d+):')
                        redis:sadd('disabled_plugins:' .. chat_id, plugin:lower())
                        print('Migrated disabled plugin "' .. plugin.lower() .. '" for ' .. chat_id)
                    end
                end
            end
            redis:del(v)
        end
    end
end
return 'Migration complete!'