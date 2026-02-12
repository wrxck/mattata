-- mattata v2.0 - English (US)
-- Inherits from en_gb with US-specific overrides
local lang = require('src.languages.en_gb')

-- Override any US-specific strings here
lang.errors.unknown = 'I don\'t recognize that user. Forward a message from them to any chat I\'m in.'

return lang
