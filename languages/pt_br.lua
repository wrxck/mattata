-- This is a language file for mattata
-- Language: pt-br
-- Author: American_Jesus

-- DO NOT CHANGE ANYTHING THAT BEGINS OR ENDS WITH A %
-- THESE ARE PLACEHOLDERS!

-- DO NOT CHANGE ANY MARKDOWN/HTML FORMATTING!
-- IF YOU ARE UNSURE, ASK ON TELEGRAM (t.me/mattataDev)

return {
    ['errors'] = {
        ['connection'] = 'Erro de conexão.',
        ['results'] = 'Eu não consegui encontrar nenhum resultado para isso.',
        ['supergroup'] = 'Este comando só pode ser usado em super grupos.',
        ['admin'] = 'Precisa ser moderador ou administrador neste grupo para usar este comando.',
        ['unknown'] = 'Eu não reconheço esse(s) utilizador(es). Se gostaria de me ensinar quem ele(s) são, encaminhe-me uma mensagem dele(s) para qualquer conversa que eu estou.',
        ['generic'] = 'Ocorreu um erro!',
        ['use'] = 'Você não tem permissão para usar isso!',
        ['private'] = 'You can only use this command in private chat!'
    },
    ['addcommand'] = {
        ['1'] = 'Please specify the command in the format <code>/command - description</code>',
        ['2'] = 'I couldn\'t retrieve my commands!',
        ['3'] = 'The command description can\'t be longer than 256 characters!',
        ['4'] = 'An unknown error occurred! I couldn\'t add your command!',
        ['5'] = 'Success! Command added.'
    },
    ['addrule'] = {
        ['1'] = 'Please specify the rule you would like to add!',
        ['2'] = 'You don\'t have any rules to add to! Please set group rules using /setrules!',
        ['3'] = 'I couldn\'t add that rule, as it would make the length of the rules longer than Telegram\'s 4096 character limit!',
        ['4'] = 'I couldn\'t add that rule, it appears it contains invalid Markdown formatting!',
        ['5'] = 'Successfully updated the rules!'
    },
    ['addslap'] = {
        ['1'] = 'You can only use this command in groups!',
        ['2'] = 'The slap cannot contain curly braces apart from placeholders!',
        ['3'] = 'The slap cannot be any longer than 256 characters in length!',
        ['4'] = 'I\'ve successfully added that slap as a possibility for /slap in this group!',
        ['5'] = 'You must include placeholders in your slap. Use {ME} for the person executing and {THEM} for the victim.'
    },
    ['administration'] = {
        ['1'] = 'Enable Administration',
        ['2'] = 'Disable Administration',
        ['3'] = 'Anti-Spam Settings',
        ['4'] = 'Warning Settings',
        ['5'] = 'Vote-Ban Settings',
        ['6'] = 'Welcome New Users?',
        ['7'] = 'Send Rules On Join?',
        ['8'] = 'Send Rules In Group?',
        ['9'] = 'Back',
        ['10'] = 'Next',
        ['11'] = 'Word Filter',
        ['12'] = 'Anti-Bot',
        ['13'] = 'Anti-Link',
        ['14'] = 'Log Actions?',
        ['15'] = 'Anti-RTL',
        ['16'] = 'Anti-Spam Action',
        ['17'] = 'Ban',
        ['18'] = 'Kick',
        ['19'] = 'Delete Commands?',
        ['20'] = 'Force Group Language?',
        ['21'] = 'Send Settings In Group?',
        ['22'] = 'Delete Reply On Action?',
        ['23'] = 'Require Captcha?',
        ['24'] = 'Use Inline Captcha?',
        ['25'] = 'Ban SpamWatch-flagged users?',
        ['26'] = 'Number of warnings until %s:',
        ['27'] = 'Upvotes needed to ban:',
        ['28'] = 'Downvotes needed to dismiss:',
        ['29'] = 'Deleted %s, and its matching link from the database!',
        ['30'] = 'There were no entries found in the database matching "%s"!',
        ['31'] = 'You\'re not an administrator in that chat!',
        ['32'] = 'The minimum number of upvotes required for a vote-ban is %s.',
        ['33'] = 'The maximum number of upvotes required for a vote-ban is %s.',
        ['34'] = 'The minimum number of downvotes required for a vote-ban is %s.',
        ['35'] = 'The maximum number of downvotes required for a vote-ban is %s.',
        ['36'] = 'The maximum number of warnings is %s.',
        ['37'] = 'The minimum number of warnings is %s.',
        ['38'] = 'You can add one or more words to the word filter by using /filter <word(s)>',
        ['39'] = 'You will no longer be reminded that the administration plugin is disabled. To enable it, use /administration.',
        ['40'] = 'That\'s not a valid chat!',
        ['41'] = 'You don\'t appear to be an administrator in that chat!',
        ['42'] = 'My administrative functionality can only be used in groups/channels! If you\'re looking for help with using my administrative functionality, check out the "Administration" section of /help! Alternatively, if you wish to manage the settings for a group you administrate, you can do so here by using the syntax /administration <chat>.',
        ['43'] = 'Use the keyboard below to adjust the administration settings for <b>%s</b>:',
        ['44'] = 'Please send me a [private message](https://t.me/%s), so that I can send you this information.',
        ['45'] = 'I have sent you the information you requested via private chat.',
        ['46'] = 'Remove Channel Pins?',
        ['47'] = 'Remove Other Pins?',
        ['48'] = 'Remove Pasted Code?',
        ['49'] = 'Prevent Inline Bots?',
        ['50'] = 'Kick Media On Join?',
        ['51'] = 'Enable Plugins For Admins?',
        ['52'] = 'Kick URLs On Join?'
    },
    ['afk'] = {
        ['1'] = 'Desculpe, receio que este elemento esteja disponível somente para utilizadores com um @utilizador público!',
        ['2'] = '%s voltou depois de estar AFK por %s!',
        ['3'] = 'Nota',
        ['4'] = '%s está agora AFK.%s'
    },
    ['antispam'] = {
        ['1'] = 'Desabilitar',
        ['2'] = 'Habilitar',
        ['3'] = 'Desabilitar limite',
        ['4'] = 'Habilitar limite para %s',
        ['5'] = 'Todas as Configurações de Administração',
        ['6'] = '%s [%s] has kicked %s [%s] from %s [%s] for hitting the configured anti-spam limit for [%s] media.',
        ['7'] = 'Kicked %s for hitting the configured antispam limit for [%s] media.',
        ['8'] = 'The maximum limit is 100.',
        ['9'] = 'The minimum limit is 1.',
        ['10'] = 'Modificar as configurações de anti-spam para %s abaixo:',
        ['11'] = 'Hey %s, if you\'re going to send code that is longer than %s characters in length, please do so using /paste in <a href="https://t.me/%s">private chat with me</a>!',
        ['12'] = '%s <code>[%s]</code> has %s %s <code>[%s]</code> from %s <code>[%s]</code> for sending Telegram invite link(s).\n#chat%s #user%s',
        ['13'] = '%s %s for sending Telegram invite link(s).',
        ['14'] = 'Hey, I noticed you\'ve got anti-link enabled and you\'re currently not allowing your users to mention a chat you\'ve just mentioned, if you\'d like to whitelist it, use /whitelistlink <links>.',
        ['15'] = 'Kicked %s <code>[%s]</code> from %s <code>[%s]</code> for sending media within their first few messages.\n#chat%s #user%s',
        ['16'] = 'Kicked %s <code>[%s]</code> from %s <code>[%s]</code> for sending a URL within their first few messages.\n#chat%s #user%s'
    },
    ['appstore'] = {
        ['1'] = 'Ver no iTunes',
        ['2'] = 'rating',
        ['3'] = 'ratings'
    },
    ['authspotify'] = {
        ['1'] = 'You are already authorised using that account.',
        ['2'] = 'Authorising, please wait...',
        ['3'] = 'A connection error occured. Are you sure you replied with the correct link? It should look like',
        ['4'] = 'Successfully authorised your Spotify account!'
    },
    ['avatar'] = {
        ['1'] = 'Não consegui obter fotos de perfil para esse utilizador, verifique se especificou um nome de utilizador ou ID numérico válido.',
        ['2'] = 'Esse utilizador não tem fotos de perfil.',
        ['3'] = 'Esse utilizador não tem assim tantas de perfil!',
        ['4'] = 'That user has opted-out of data-collecting functionality, therefore I am not able to show you any of their profile photos.',
        ['5'] = 'User: %s\nPhoto: %s/%s\nSend /avatar %s [offset] to @%s to view a specific photo of this user',
        ['6'] = 'User: %s\nPhoto: %s/%s\nUse /avatar %s [offset] to view a specific photo of this user'
    },
    ['ban'] = {
        ['1'] = 'Qual utilizador gostaria que eu bane? Pode especificar esse utilizador pelo seu @username ou ID numérico.',
        ['2'] = 'Não consigo banir esse utilizador porque ele é um moderador ou um administrador neste grupo.',
        ['3'] = 'Não consigo banir este utilizador porque ele saiu deste grupo.',
        ['4'] = 'Não consigo banir este utilizador porque ele já foi banido deste grupo.',
        ['5'] = 'Eu preciso ter permissões administrativas para banir esse utilizador. Corrija este problema e tente novamente.',
        ['6'] = '%s <code>[%s]</code> has banned %s <code>[%s]</code> from %s <code>[%s]</code>%s.\n%s %s',
        ['7'] = '%s has banned %s%s.'
    },
    ['bash'] = {
        ['1'] = 'Especifique um comando para executar!',
        ['2'] = 'Sucesso!'
    },
    ['blacklist'] = {
        ['1'] = 'Qual utilizador gostaria de adicionar a lista negra? Pode especificar este utilizador pelo seu @username ou ID numérico.',
        ['2'] = 'Não consigo adicionar a lista negra esse utilizador porque ele é um moderador ou um administrador neste grupo.',
        ['3'] = 'Não consigo adicionar a lista negra esse utilizador porque ele já deixou este grupo.',
        ['4'] = 'Não consigo adicionar a lista negra esse utilizador porque ele já foi banido neste grupo.',
        ['5'] = '%s <code>[%s]</code> has blacklisted %s <code>[%s]</code> from using %s <code>[%s]</code> in %s <code>[%s]</code>%s.\n%s %s',
        ['6'] = '%s has blacklisted %s from using %s%s.'
    },
    ['blacklistchat'] = {
        ['1'] = '%s foi adicionado a lista negra, e vou deixar lá quem eu adicionar!',
        ['2'] = '%s é um utilizador, este comando é apenas para lista negras em conversas como grupos e canais!',
        ['3'] = '%s não parece ser uma conversa valida!'
    },
    ['bugreport'] = {
        ['1'] = 'Sucesso! Seu relatório de bug foi enviado. O ID deste relatório é #%s.',
        ['2'] = 'Ocorreu um problema enquanto relatava esse bug! Ah, a ironia!'
    },
    ['calc'] = {
        ['1'] = 'Clique para enviar o resultado.',
        ['2'] = '"%s" was an unexpected word!',
        ['3'] = 'You cannot have a unit before a number!'
    },
    ['captionbotai'] = {
        ['1'] = 'Eu realmente não posso descrever essa imagem!'
    },
    ['cats'] = {
        ['1'] = 'Meow!'
    },
    ['channel'] = {
        ['1'] = 'Não tem permissão para usar isso!',
        ['2'] = 'Parece já não ser um administrador nesse grupo!',
        ['3'] = 'Não consegui enviar a sua mensagem, tem certeza de que ainda tenho permissão para enviar mensagens nesse grupo?',
        ['4'] = 'A sua mensagem foi enviada!',
        ['5'] = 'Não consegui recuperar uma lista de administradores para desse grupo!',
        ['6'] = 'Não parece ser um administrador desse grupo!',
        ['7'] = 'Especifique a mensagem a enviar, utilizando a sintaxe /channel <canal> <mensagem>.',
        ['8'] = 'Tem certeza de que deseja enviar esta mensagem? É assim que vai aparecer:',
        ['9'] = 'Sim, tenho a certeza!',
        ['10'] = 'Essa mensagem contém formatação Markdown inválida! Corrija a sintaxe e tente novamente.'
    },
    ['chatroulette'] = {
        ['1'] = 'Hey! Please don\'t send messages longer than %s characters. We don\'t want to annoy the other user!',
        ['2'] = '*Anonymous said:*\n```\n%s\n```\nTo end your session, send /endchat.',
        ['3'] = 'I\'m afraid I lost connection from the other user! To begin a new chat, please send /chatroulette!',
        ['4'] = 'The other person you were chatting with has ended the session. To start a new one, send /chatroulette.',
        ['5'] = 'Successfully ended your session. To start a new one, send /chatroulette.',
        ['6'] = 'I have successfully removed you from the list of available users.',
        ['7'] = 'You don\'t have a session set up at the moment. To start one, send /chatroulette.',
        ['8'] = 'Finding you a session, please wait...',
        ['9'] = 'I\'m afraid there aren\'t any available users right now, but I have added you to the list of available users! To stop this completely, please send /endchat.',
        ['10'] = 'I have successfully paired you with another user to chat to! Please remember to be kind to them! To end the chat, send /endchat.',
        ['11'] = 'I\'m afraid the user who I tried to pair you with has since blocked me. Please try and send /chatroulette again to try and connect to me!',
        ['12'] = 'I have successfully paired you with another user to chat to! Please remember to be kind to them! To end the chat, send /endchat.'
    },
    ['commandstats'] = {
        ['1'] = 'Nenhum comando foi enviado neste chat!',
        ['2'] = '<b>Estatísticas de comandos para:</b> %s\n\n%s\n<b>Total de comandos enviados:</b> %s',
        ['3'] = 'As estatísticas de comandos para este chat foram resetadas!',
        ['4'] = 'Não consegui resetar as estatísticas de comandos para este chat. Talvez eu já as tenha resetado?'
    },
    ['control'] = {
        ['1'] = 'Pfft, querias!',
        ['2'] = '%s está recarregando...'
    },
    ['copypasta'] = {
        ['1'] = 'O texto respondido não deverá exceder %s caracteres!'
    },
    ['coronavirus'] = {
        ['1'] = [[*COVID-19 Statistics for:* %s

*New confirmed cases:* %s
*Total confirmed cases:* %s
*New deaths:* %s
*Total deaths:* %s
*New recovered cases:* %s
*Total recovered cases:* %s]]
    },
    ['counter'] = {
        ['1'] = 'Eu não pude adicionar um contador a essa mensagem!'
    },
    ['custom'] = {
        ['1'] = 'Sucesso! Essa mensagem será enviada toda vez que alguém usar %s!',
        ['2'] = 'O trigger "%s" não existe!',
        ['3'] = 'O trigger "%s" foi apagado!',
        ['4'] = 'Ainda não tem triggers personalizado definidos!',
        ['5'] = 'Comandos personalizados para %s:\n',
        ['6'] = 'Para criar um novo comando personalizado, use a seguinte sintaxe:\n/custom new #trigger <valor>. Para listar todos os triggers atuais, use /custom list. Para apagar um trigger, use /custom del #trigger.'
    },
    ['delete'] = {
        ['1'] = 'Não consegui apagar essa mensagem. Talvez a mensagem seja muito antiga ou inexistente?'
    },
    ['demote'] = {
        ['1'] = 'Qual utilizador gostaria que eu despromovesse? Pode especificar este utilizador pelo seu @username ou ID numérico.',
        ['2'] = 'Eu não posso despromover esse utilizador porque ele não é um moderador ou um administrador neste grupo.',
        ['3'] = 'Eu não posso despromover esse utilizador porque ele já deixou este grupo.',
        ['4'] = 'Não consigo despromover esse utilizador porque ele já foi expulso deste grupo.'
    },
    ['doge'] = {
        ['1'] = 'Por favor, escreva o texto que deseja para Doge-ify. Cada sentença deve ser separada usando barras (/) ou novas linhas.'
    },
    ['donate'] = {
        ['1'] = '<b>Hello, %s!</b>\n\nIf you\'re feeling generous, you can contribute to the mattata project by making a monetary donation of any amount. This will go towards server costs and any time and resources used to develop mattata. This is an optional act, however it is greatly appreciated and your name will also be listed publically on mattata\'s GitHub page.\n\nIf you\'re still interested, you can donate <a href="https://paypal.me/wrxck">here</a>. Thank you for your continued support!'
    },
    ['exec'] = {
        ['1'] = 'Selecione a linguagem em que gostaria de executar o seu código:',
        ['2'] = 'Ocorreu um erro! Tempo de ligação expirou. Está tentando me engasgar?',
        ['3'] = 'Selecionou "%s" – tem a certeza?',
        ['4'] = 'Voltar',
        ['5'] = 'Tenho certeza',
        ['6'] = 'Introduza um fragmento de código que pretende executar. Não precisa especificar a linguagem, faremos isso depois!',
        ['7'] = 'Selecione a linguagem em que gostaria de executar o seu código:'
    },
    ['facebook'] = {
        ['1'] = 'Ocorreu um erro!',
        ['2'] = 'Escreva o nome de utilizador do Facebook do qual gostaria de obter a foto do perfil.',
        ['3'] = 'Visitas @%s no Facebook'
    },
    ['fact'] = {
        ['1'] = 'Gerar Outro'
    },
    ['fban'] = {
        ['1'] = 'Which user would you like me to Fed-ban? You can specify this user by their @username or numerical ID.',
        ['2'] = 'I cannot Fed-ban this user because they are a moderator or an administrator in this chat.'
    },
    ['flickr'] = {
        ['1'] = 'Pesquisou por:',
        ['2'] = 'Introduza uma consulta de pesquisa (Ou seja, o que quer que eu procure no Flickr, i.e. "Big Ben" mostrara uma fotografia do Big Ben em Londres).',
        ['3'] = 'Mais Resultados'
    },
    ['game'] = {
        ['1'] = 'Total de vitórias: %s\nTotal de derrotas: %s\nBalanço: %s mattacoins',
        ['2'] = 'Entrar no Jogo',
        ['3'] = 'Este jogo já acabou!',
        ['4'] = 'Não é a sua vez!',
        ['5'] = 'Não faz parte deste jogo!',
        ['6'] = 'Não pode ser ai!',
        ['7'] = 'Já faz parte deste jogo!',
        ['8'] = 'Este jogo já começou!',
        ['9'] = '%s [%s] está a jogar contra %s [%s]\nE é a vez de %s\'s a jogar!',
        ['10'] = '%s ganhou o jogo contra %s!',
        ['11'] = '%s criou um jogo contra %s!',
        ['12'] = 'A espera pelo oponente...',
        ['13'] = 'Jogo do Galo',
        ['14'] = 'Clique para enviar o jogo para o seu grupo!',
        ['15'] = 'Estatísticas %s:\n',
        ['16'] = 'Jogar ao Jogo do Galo!'
    },
    ['gblacklist'] = {
        ['1'] = 'Responda ao utilizador que deseja incluir na lista negra global ou especifique-o por nome de utilizador/ID.',
        ['2'] = 'Não conseguir obter informações sobre "%s", verifique se é um nome de utilizador/ID válido e tente novamente.',
        ['3'] = 'Isso é um %s, não um utilizador!'
    },
    ['gif'] = {
        ['1'] = 'Introduza uma consulta de pesquisa (Que é, o que quer que eu procure no GIPHY, ex: "cat" irá mostrar um GIF de um gato).'
    },
    ['gwhitelist'] = {
        ['1'] = 'Responda ao utilizador que deseja incluir na lista branca global ou especifique-o por nome de utilizador/ID.',
        ['2'] = 'Não conseguir obter informações sobre "%s", verifique se é um nome de utilizador/ID válido e tente novamente.',
        ['3'] = 'Isso é um %s, não um utilizador!'
    },
    ['hackernews'] = {
        ['1'] = 'Histórias principais de Hacker News:'
    },
    ['help'] = {
        ['1'] = 'Nenhum resultado encontrado!',
        ['2'] = 'Não foram encontrados elementos que correspondam a "%s", Por favor, tente ser mais específico!',
        ['3'] = '\n\nArgumentos: <requer> [opcional]\n\nProcurar um elemento ou obter ajuda com um comando usando minha funcionalidade de pesquisa inline - apenas me mencione em qualquer grupo usando a sintaxe @%s <texto de procura>.',
        ['4'] = 'Anterior',
        ['5'] = 'Seguinte',
        ['6'] = 'Voltar',
        ['7'] = 'Procurar',
        ['8'] = 'Está na pagina %s de %s!',
        ['9'] = [[
Posso executar muitas ações administrativas nos seus grupos, basta adicionar-me como administrador e envie /administration para ajustar as configurações do seu grupo.
Aqui estão alguns comandos administrativos e um breve comentário sobre o que eles fazem:

• /pin <texto> - Envie uma mensagem formatada em Markdown que pode ser editada usando o mesmo comando com texto diferente, para evitar de ter que afixar novamente uma mensagem se não poder edita-la (o que acontece se a mensagem tiver mais de 48 horas)

• /ban - Banir um utilizador respondendo a uma de suas mensagens ou especificando com o nome de utilizador/ID

• /kick - Expulsar (banir e depois remover ban) um utilizador respondendo a uma de suas mensagens ou especificando com o nome de utilizador/ID

• /unban - Remover ban a um utilizador respondendo a uma de suas mensagens ou especificando com o nome de utilizador/ID

• /setrules <texto> - Defina o texto formatado como Markdown como as regras de grupo, que serão enviadas sempre que alguém usar /rules
        ]],
        ['10'] = [[
• /setwelcome - Defina o texto formatado como Markdown como uma mensagem de boas-vindas que será enviada sempre que um utilizador se juntar ao seu grupo (A mensagem de boas-vindas pode ser desativada no menu de administração, acessível via /administration). Pode usar espaços reservados para personalizar automaticamente a mensagem de boas-vindas para cada utilizador. Use $user_id para inserir o ID numérico do utilizador, $chat_id para inserir o ID numérico do grupo, $name para inserir o nome do utilizador, $title para inserir o título do grupo e $username para inserir o nome de utilizador do utilizador (Se o utilizador não tiver um @utilizador, o seu nome será usado em vez disso, para evitar é melhor usar isso com $name)

• /warn - Avisa um utilizador, e bane-o quando atingirem o número máximo de avisos

• /mod - Promove um utilizador respondendo a, dando acesso a comandos administrativos como /ban, /kick, /warn etc. (isto é útil quando não quer que alguém tenha a capacidade de apagar mensagens!)

• /demod - Despromove um utilizador respondendo a, removendo do seu estatuto de moderação e revogando sua capacidade de usar comandos administrativos

• /staff - Mostrar o criador, administradores e moderadores do grupo numa lista bem formatada
        ]],
        ['11'] = [[
• /report - Encaminha a mensagem de resposta para todos os administradores e os alerta da situação atual

• /setlink <URL> - Define o endereço do grupo para o URL fornecido, que será enviado sempre que alguém usar /link

• /links <texto> - Listas brancas todos os endereços Telegram encontrados no texto fornecido (inclui endereços de @utilizador)
        ]],
        ['12'] = 'Abaixo estão alguns links que pode achar úteis:',
        ['13'] = 'Desenvolvimento',
        ['14'] = 'Canal',
        ['15'] = 'Suporte',
        ['16'] = 'FAQ',
        ['17'] = 'Código Fonte',
        ['18'] = 'Doar',
        ['19'] = 'Rate',
        ['20'] = 'Registo de Administração',
        ['21'] = 'Definições de administrador',
        ['22'] = 'Plugins',
        ['23'] = [[
<b>Olá %s! O meu nome é %s, é um prazer conhece-lo</b> %s

Eu entendo muitos comandos, que você pode aprender mais sobre pressionando o botão "Comandos" usando o teclado acoplado.

%s <b>Dica:</b> Use o botão "Definições" para alterar o modo como eu trabalho%s!

%s <b>Find me useful, or just want to help?</b> Donations are very much appreciated, use /donate for more information!
        ]],
        ['24'] = 'em'
    },
    ['id'] = {
        ['1'] = 'Desculpe, mas eu não reconheço esse utilizador. Ensine-me quem ele é, encaminhando uma mensagem dele a mim ou faça com que ele me enviem uma mensagem.',
        ['2'] = 'Grupo consultado:',
        ['3'] = 'Este grupo:',
        ['4'] = 'Clique para enviar o resultado!'
    },
    ['imdb'] = {
        ['1'] = 'Anterior',
        ['2'] = 'Seguinte',
        ['3'] = 'Está na pagina %s de %s!'
    },
    ['import'] = {
        ['1'] = 'Eu não reconheço esse grupo!',
        ['2'] = 'Isso não é um super grupo, portanto não consigo importar nenhuma configuração dele!',
        ['3'] = 'Configurações administrativas importadas e plugins alternados com sucesso de %s para %s!'
    },
    ['info'] = {
        ['1'] = [[
```
Redis:
%s Ficheiro de Configuração: %s
%s Modo: %s
%s Porta TCP: %s
%s Versão: %s
%s Tempo de atividade: %s days
%s ID do Processo: %s
%s Keys Expiradas: %s

%s Contagem de Utilizadores: %s
%s Contagem de Grupos: %s

Sistema:
%s OS: %s
```
        ]]
    },
    ['instagram'] = {
        ['1'] = '@%s no Instagram'
    },
    ['ipsw'] = {
        ['1'] = '<b>%s</b> iOS %s\n\n<code>MD5 sum: %s\nSHA1 sum: %s\nTamanho do ficheiro: %s GB</code>\n\n<i>%s %s</i>',
        ['2'] = 'Este firmware não está mais sendo assinado!',
        ['3'] = 'Este firmware ainda está sendo assinado!',
        ['4'] = 'Selecione o seu modelo:',
        ['5'] = 'Selecione a versão do firmware:',
        ['6'] = 'Selecione seu tipo de dispositivo:',
        ['7'] = 'iPod Touch',
        ['8'] = 'iPhone',
        ['9'] = 'iPad',
        ['10'] = 'Apple TV'
    },
    ['ispwned'] = {
        ['1'] = 'Essa conta foi encontrada nos seguintes fugas de informação:'
    },
    ['itunes'] = {
        ['1'] = 'Nome:',
        ['2'] = 'Artista:',
        ['3'] = 'Álbum:',
        ['4'] = 'Faixa:',
        ['5'] = 'Disco:',
        ['6'] = 'A consulta original não pôde ser encontrada, provavelmente apagou a mensagem original.',
        ['7'] = 'A capa pode ser encontrada abaixo:',
        ['8'] = 'Introduza uma consulta de pesquisa (Ou seja, o que quer que eu procure no iTunes, Ex: "Green Day American Idiot" ira mostrar informações sobre o primeiro resultado para American Idiot dos Green Day).',
        ['9'] = 'Obter Capa do Álbum'
    },
    ['kick'] = {
        ['1'] = 'Qual utilizador gostaria que eu expulsasse? Pode especificar este utilizador por seu @utilizador ou ID numérico.',
        ['2'] = 'Eu não consigo expulsar esse utilizador porque ele é um moderador ou administrador neste grupo.',
        ['3'] = 'Eu não consigo expulsar esse utilizador porque ele já deixou este grupo.',
        ['4'] = 'Não consigo expulsar esse utilizador porque ele já foi expulso deste grupo.',
        ['5'] = 'Eu preciso ter permissões administrativas para expulsar esse utilizador. Corrija este problema e tente novamente.'
    },
    ['lastfm'] = {
        ['1'] = '%s\'s utilizador de last.fm foi definido para "%s".',
        ['2'] = 'O seu utilizador last.fm foi esquecido!',
        ['3'] = 'Não tem atualmente um utilizado do last.fm definido!',
        ['4'] = 'Especifique o utilizador do last.fm ou defina com /fmset.',
        ['5'] = 'Nenhum histórico foi encontrado para este utilizador.',
        ['6'] = '%s está atualmente a ouvir:\n',
        ['7'] = '%s ouviu ultimamente:\n',
        ['8'] = 'Desconhecido',
        ['9'] = 'Clique para enviar o resultado.'
    },
    ['location'] = {
        ['1'] = 'Não tem uma localização definida. O que nova localização gostaria que fosse?'
    },
    ['logchat'] = {
        ['1'] = 'Escreva o nome de utilizador ou ID numérico do grupo no qual deseja registar todas as ações administrativas.',
        ['2'] = 'A verificar se o grupo é válido...',
        ['3'] = 'Desculpe, parece que especificou um grupo inválido, ou especificou um grupo que eu ainda não adicionado. Corrija e tente novamente.',
        ['4'] = 'Não pode definir um utilizador como o seu grupo de registo!',
        ['5'] = 'Não parece ser administrador nesse grupo!',
        ['6'] = 'Parece que eu já estou registar ações administrativas nesse grupo! Use /logchat para especificar um novo.',
        ['7'] = 'Esse grupo é válido, vou tentar e enviar uma mensagem de teste para ele, apenas para garantir que tenho permissão para falar!',
        ['8'] = 'Olá mundo - esta é uma mensagem de teste para verificar minhas permissões de escrita - se estiver a ler isto, então tudo correu bem!',
        ['9'] = 'Tudo feito! De agora em diante, Quaisquer ações administrativas neste grupo serão registadas em %s - para mudar o grupo que quer que eu registe ações administrativas, basta enviar /logchat.'
    },
    ['lua'] = {
        ['1'] = 'Digite uma string de Lua para executar!'
    },
    ['lyrics'] = {
        ['1'] = 'Spotify',
        ['2'] = 'Mostrar letra',
        ['3'] = 'Introduza uma consulta de pesquisa (isto é, que musica/artista/letra quer que eu obtenha letras, Ex: "Green Day Basket Case" irá mostrar a letra para Basket Case dos Green Day).'
    },
    ['minecraft'] = {
        ['1'] = '<b>%s mudou o seu utilizador %s vez</b>',
        ['2'] = '<b>%s mudou o seu utilizador %s vezes</b>',
        ['3'] = 'Anterior',
        ['4'] = 'Seguinte',
        ['5'] = 'Voltar',
        ['6'] = 'UUID',
        ['7'] = 'Avatar',
        ['8'] = 'Histórico de Utilizador',
        ['9'] = 'Selecione uma opção:',
        ['10'] = 'Escreva o nome de utilizador do jogador do Minecraft que gostaria de ver informações (Ex: enviando "Notch" irá ver as informações sobre o jogador Notch).',
        ['11'] = 'Os nomes de utilizadores do Minecraft têm entre 3 e 16 caracteres.'
    },
    ['mute'] = {
        ['1'] = 'Que utilizador gostaria que ficasse silenciar? Pode especificar este utilizador pelo seu @utilizador ou ID numérico.',
        ['2'] = 'Não consigo silenciar este utilizador porque já estão silenciados neste grupo.',
        ['3'] = 'Não consigo silenciar este utilizador porque ele é um moderador ou administrador neste grupo.',
        ['4'] = 'Não consigo silenciar este utilizador porque ele já deixou (ou foi expulso) deste grupo.',
        ['5'] = 'Eu preciso ter permissões administrativas para silenciar este utilizador. Corrija este problema e tente novamente.'
    },
    ['myspotify'] = {
        ['1'] = 'Perfil',
        ['2'] = 'Seguindo',
        ['3'] = 'Recently Played',
        ['4'] = 'Currently Playing',
        ['5'] = 'Top Tracks',
        ['6'] = 'Top Artistas',
        ['7'] = 'You don\'t appear to be following any artists!',
        ['8'] = 'Seus Top Artistas',
        ['9'] = 'You don\'t appear to have any tracks in your library!',
        ['10'] = 'Your Top Tracks',
        ['11'] = 'You don\'t appear to be following any artists!',
        ['12'] = 'Artists You Follow',
        ['13'] = 'You don\'t appear to have recently played any tracks!',
        ['14'] = '<b>Recently Played</b>\n%s %s\n%s %s\n%s Listened to at %s:%s on %s/%s/%s.',
        ['15'] = 'The request has been accepted for processing, but the processing has not been completed.',
        ['16'] = 'You don\'t appear to be listening to anything right now!',
        ['17'] = 'Currently Playing',
        ['18'] = 'An error occured whilst re-authorising your Spotify account!',
        ['19'] = 'Successfully re-authorised your Spotify account! Processing your original request...',
        ['20'] = 'Re-authorising your Spotify account, please wait...',
        ['21'] = 'You need to authorise mattata in order to connect your Spotify account. Click [here](https://accounts.spotify.com/en/authorize?client_id=%s&response_type=code&redirect_uri=%s&scope=user-library-read,playlist-read-private,playlist-read-collaborative,user-read-private,user-read-email,user-follow-read,user-top-read,user-read-playback-state,user-read-recently-played,user-read-currently-playing,user-modify-playback-state) and press the green "OKAY" button to link mattata to your Spotify account. After you\'ve done that, send the link you were redirected to (it should begin with "%s", followed by a unique code) in reply to this message.',
        ['22'] = 'Playlists',
        ['23'] = 'Use Inline Mode',
        ['24'] = 'Lyrics',
        ['25'] = 'No devices were found.',
        ['26'] = 'You don\'t appear to have any playlists.',
        ['27'] = 'Your Playlists',
        ['28'] = '%s %s [%s tracks]',
        ['29'] = '%s %s [%s]\nSpotify %s user\n\n<b>Devices:</b>\n%s',
        ['30'] = 'Playing previous track...',
        ['31'] = 'You are not a premium user!',
        ['32'] = 'I could not find any devices.',
        ['33'] = 'Playing next track...',
        ['34'] = 'Resuming track...',
        ['35'] = 'Your device is temporarily unavailable...',
        ['36'] = 'No devices were found!',
        ['37'] = 'Pausing track...',
        ['38'] = 'Now playing',
        ['39'] = 'Shuffling your music...',
        ['40'] = 'That\'s not a valid volume. Please specify a number between 0 and 100.',
        ['41'] = 'The volume has been set to %s%%!',
        ['42'] = 'This message is using an old version of this plugin, please request a new one by sending /myspotify!'
    },
    ['name'] = {
        ['1'] = 'O nome pelo qual respondo atualmente é "%s" - para alterar isso, use /name <texto> (onde <texto> é o nome pelo qual quer que eu responda).',
        ['2'] = 'Meu novo nome precisa ter entre 2 e 32 caracteres!',
        ['3'] = 'Meu nome só pode conter caracteres alfanuméricos!',
        ['4'] = 'Vou agora responder a "%s", em vez de "%s" - para alterar isso, use /name <texto> (onde <text> o nome a qual quer que eu responda).'
    },
    ['netflix'] = {
        ['1'] = 'Ver mais.'
    },
    ['news'] = {
        ['1'] = '"<code>%s</code>" não é um padrão Lua válido.',
        ['2'] = 'Eu não consegui obter uma lista de fontes.',
        ['3'] = '<b>Fontes de notícias encontradas correspondentes</b> "<code>%s</code>":\n\n%s',
        ['4'] = '<b>Aqui estão as fontes de notícias disponíveis que pode usar com</b> /news<b>. Use</b> /nsources &lt;pesquisa&gt; <b>para pesquisar a lista de fontes de notícias para um conjunto mais específico de resultados. As pesquisas são combinadas usando padrões Lua</b>\n\n%s',
        ['5'] = 'Não tem uma fonte de notícias preferida. Use /setnews <source> para definir uma. Veja a lista de fontes usando /nsources, ou restringir os resultados usando /nsources <pesquisa>.',
        ['6'] = 'A sua fonte de notícias preferida atual é %s. Use /setnews <source> para alterar isso. Veja a lista de fontes usando /nsources, ou restringir os resultados usando /nsources <pesquisa>.',
        ['7'] = 'A sua fonte preferida já está definida para %s! Use /news para ver a história principal atual.',
        ['8'] = 'Isso não é uma fonte de notícias válida. Exibir uma lista de fontes usando /nsources, ou restringir os resultados usando /nsources <pesquisa>.',
        ['9'] = 'A sua fonte de notícias preferida foi atualizada para %s! Use /news para ver a história principal atual.',
        ['10'] = 'Isso não é uma fonte válida, use /nsources para ver uma lista de fontes disponíveis. Se tem uma fonte preferida, use /setnews <fonte> Para receber automaticamente notícias daquela fonte enviada quando envie /news, sem quaisquer argumentos necessários.',
        ['11'] = 'Ver mais.'
    },
    ['nick'] = {
        ['1'] = 'O seu nick foi esquecido!',
        ['2'] = 'O seu nick foi definido como "%s"!'
    },
    ['optout'] = {
        ['1'] = 'Optou por enviar os seus dados! Use /optout para excluir.',
        ['2'] = 'Optou por não enviar os seus dados! Use /optin para enviar.'
    },
    ['paste'] = {
        ['1'] = 'Selecione um serviço para enviar copia:'
    },
    ['pin'] = {
        ['1'] = 'Não definiu ainda uma mensagem afixada. Use /pin <texto> para definir uma. A formatação Markdown é suportada.',
        ['2'] = 'Aqui está a última mensagem gerada usando /pin.',
        ['3'] = 'Eu encontrei uma mensagem afixada existente na base de dados, mas a mensagem que enviei parece ter sido apagada, e não consigo mais encontra-la. Pode definir uma nova usando /pin <texto>. A formatação Markdown é suportada.',
        ['4'] = 'Ocorreu um erro ao atualizar a mensagem afixada. Ou o texto inserido continha um sintaxe Markdown inválido, ou a mensagem afixada foi apagada. Eu estou agora tentar e enviar-lhe uma mensagem afixada nova, que será capaz de encontrar abaixo - se precisar modifica-lo, depois de garantir que a mensagem ainda existe, use /pin <texto>.',
        ['5'] = 'Eu não consegui enviar esse texto porque ele contém um sintaxe Markdown inválido.',
        ['6'] = 'Clique aqui para ver a mensagem afixada, atualizado para contendo o texto que me enviou.'
    },
    ['pokedex'] = {
        ['1'] = 'Nome: %s\nID: %s\nTipo: %s\nDescrição: %s'
    },
    ['promote'] = {
        ['1'] = 'Não consigo promover este utilizador porque é moderador ou administrador deste grupo.',
        ['2'] = 'Não consigo promover este utilizador porque já saiu deste grupo.',
        ['3'] = 'Não consigo promover esse utilizador porque ele já foi expulso deste grupo.'
    },
    ['quote'] = {
        ['1'] = 'Este utilizador desativou a funcionalidade de armazenamento de dados.',
        ['2'] = 'Não há citações guardadas para %s%s! Pode guardar um usando /save em resposta a uma mensagem que enviam.'
    },
    ['report'] = {
        ['1'] = 'Please reply to the message you would like to report to the group\'s administrators.',
        ['2'] = 'You can\'t report your own messages, are you just trying to be funny?',
        ['3'] = '<b>%s precisa de ajuda em %s!</b>',
        ['4'] = 'Click here to view the reported message.',
        ['5'] = 'I\'ve successfully reported that message to %s admin(s)!'
    },
    ['save'] = {
        ['1'] = 'Este utilizador desativou a funcionalidade de armazenamento de dados.',
        ['2'] = 'Esta mensagem foi gravada na minha base de dados, e adicionado à lista de possíveis respostas para quando /quote è usado em resposta a %s%s!'
    },
    ['sed'] = {
        ['1'] = '%s\n\n<i>%s não quis dizer isso!</i>',
        ['2'] = '%s\n\n<i>%s admitiu a sua derrota.</i>',
        ['3'] = '%s\n\n<i>%s não tem certeza se eles estavam errados...</i>',
        ['4'] = 'Vai-te lixar, <i>quando é que eu estou errado?</i>',
        ['5'] = '"<code>%s</code>" não é um modelo Lua válido.',
        ['6'] = '<b>%s quis dizer:</b>\n<i>%s</i>',
        ['7'] = 'Sim',
        ['8'] = 'Não',
        ['9'] = 'Não tenho certeza'
    },
    ['setgrouplang'] = {
        ['1'] = 'O idioma deste grupo foi alterado para %s!',
        ['2'] = 'This group\'s language is currently %s.\nPlease note that some strings may not be translated as of yet. If you\'d like to change your language, select one using the keyboard below:',
        ['3'] = 'The option to force users to use the same language in this group is currently disabled. This setting should be toggled from /administration but, to make things easier for you, I\'ve included a button below.',
        ['4'] = 'Habilitar',
        ['5'] = 'Desabilitar'
    },
    ['setlang'] = {
        ['1'] = 'O seu idioma foi definido para %s!',
        ['2'] = 'O seu idioma é atualmente %s.\nTome nota que algumas sequencias de caracteres podem não estar traduzidas. Se quiser alterar seu idioma, selecione um usando o teclado abaixo:'
    },
    ['setlink'] = {
        ['1'] = 'Não é um URL valido.',
        ['2'] = 'Endereço definido com sucesso!'
    },
    ['setrules'] = {
        ['1'] = 'Formato Markdown invalido.',
        ['2'] = 'Regras definidas com sucesso!'
    },
    ['setwelcome'] = {
        ['1'] = 'O que mensagem gostaria de boas-vindas que fosse? O texto que especificar será formato em Markdown e enviado toda vez que um utilizador se juntar ao grupo (A mensagem de boas-vindas pode ser desativada no menu de administração, acessível via /administration). Pode usar espaços reservados para personalizar automaticamente a mensagem de boas-vindas para cada utilizador. Use $user_id para inserir o ID numérico do utilizador, $chat_id para inserir o ID numérico do grupo, $name para inserir o nome do utilizador, $title para inserir o título do grupo e $username para inserir o nome de utilizador do utilizador (Se o utilizador não tiver um @utilizador, o seu nome será usado em vez disso, para evitar é melhor usar isso com $name).',
        ['2'] = 'Ocorreu um erro ao formatar a mensagem, verifique a sintaxe de Markdown e tente novamente.',
        ['3'] = 'A mensagem de boas-vindas para %s foi atualizada com sucesso!'
    },
    ['share'] = {
        ['1'] = 'Partilhar'
    },
    ['shorten'] = {
        ['1'] = 'Selecione um URL shortener usando os botões abaixo:'
    },
    ['shsh'] = {
        ['1'] = 'Eu não consegui obter qualquer blobs SHSH para esse ECID, assegure-se de que é válido e os guardou usando https://tsssaver.1conan.com.',
        ['2'] = 'Os blobs SHSH para esse dispositivo estão disponíveis para as seguintes versões do iOS:\n',
        ['3'] = 'Transferir .zip'
    },
    ['statistics'] = {
        ['1'] = 'No messages have been sent in this chat!',
        ['2'] = '<b>Statistics for:</b> %s\n\n%s\n<b>Total messages sent:</b> %s',
        ['3'] = 'The statistics for this chat have been reset!',
        ['4'] = 'I could not reset the statistics for this chat. Perhaps they have already been reset?'
    },
    ['steam'] = {
        ['1'] = 'O seu nome de utilizador do Steam foi definido para "%s".',
        ['2'] = '"%s" não é um nome de utilizador Steam valido.',
        ['3'] = '%s é utilizador do Steam desde %s, em %s. Desligou a ultima vez %s, em %s. Clique <a href="%s">aqui</a> para ver o perfil no Steam.',
        ['4'] = '%s, AKA "%s",'
    },
    ['trust'] = {
        ['1'] = 'I cannot trust this user because they are a moderator or an administrator of this chat.',
        ['2'] = 'I cannot trust this user because they have already left this chat.',
        ['3'] = 'I cannot trust this user because they have already been kicked from this chat.'
    },
    ['unmute'] = {
        ['1'] = 'Que utilizador gostaria que removesse silenciar? Pode especificar este utilizador pelo seu @utilizador ou ID numérico.',
        ['2'] = 'Não consigo remover silenciar a este utilizador porque não está atualmente silenciado neste grupo.',
        ['3'] = 'Não consigo remover silenciar a este utilizador porque ele é um moderador ou administrador neste grupo.',
        ['4'] = 'Não consigo remover silenciar a este utilizador porque ele já deixou (ou foi expulso) deste grupo.',
    },
    ['untrust'] = {
        ['1'] = 'Which user would you like me to untrust? You can specify this user by their @username or numerical ID.',
        ['2'] = 'I cannot untrust this user because they are a moderator or an administrator in this chat.',
        ['3'] = 'I cannot untrust this user because they have already left this chat.',
        ['4'] = 'I cannot untrust this user because they have already been kicked from this chat.'
    },
    ['upload'] = {
        ['1'] = 'Responda a mensagem do ficheiro que pretende transferir para o servidor. Deve ser <= 20 MB.',
        ['2'] = 'Ficheiro é demasiado grande. Deve ser <= 20 MB.',
        ['3'] = 'Não consegui obter esse ficheiro, é provavelmente muito antigo.',
        ['4'] = 'Ocorreu um erro ao recuperar esse ficheiro.',
        ['5'] = 'Ficheiro transferido para o servidor com sucesso - pode ser encontrado em <code>%s</code>!'
    },
    ['voteban'] = {
        ['1'] = 'Qual utilizador gostaria de abrir uma votação para banir? Pode especificar este utilizador pelo seu @utilizador ou ID numérico.',
        ['2'] = 'Não consigo criar uma votação para este utilizador porque ele é um moderador ou administrador neste grupo.',
        ['3'] = 'Não consigo criar uma votação para este utilizador porque ele já deixaram (ou foi expulso) deste grupo.',
        ['4'] = '%s [%s] deve ser banido por %s? %s voto a favor para banir imediatamente, e %s votos contra para fechar esta votação.',
        ['5'] = 'Sim [%s]',
        ['6'] = 'Não [%s]',
        ['7'] = 'O povo falou. E baniu %s [%s] por %s porque %s pessoas votaram a favor.',
        ['8'] = 'O montante de votos a favor necessários foi atingido, no entanto, não foi pode banir  %s - talvez deixou o grupo ou foi promovido desde que abrimos a votação para banir? É isso ou não tenho mais os privilégios administrativos necessários para executar esta ação!',
        ['9'] = 'O povo falou. E não foi banido %s [%s] por %s porque %s pessoa decidiram votar contra.',
        ['10'] = 'Votou a favor na decisão de banir %s [%s]!',
        ['11'] = 'O seu voto atual foi retirado, use os botões novamente para reenviar o seu voto.',
        ['12'] = 'Votou contra na decisão de banir %s [%s]!',
        ['13'] = 'A vote-ban has already been opened for this user!'
    },
    ['weather'] = {
        ['1'] = 'Ainda não tem uma localização definida. Use /setloc <localização> para definir uma.',
        ['2'] = 'Está atualmente %s (parece %s) em %s. %s'
    },
    ['welcome'] = {
        ['1'] = 'Regras do Grupo'
    },
    ['whitelist'] = {
        ['1'] = 'Qual utilizador gostaria de adicionar à white-list? Pode especificar este utilizador pelo seu @utilizador ou ID numérico.',
        ['2'] = 'Não consigo adicionar à white-list esse utilizador porque ele é um moderador ou administrador neste grupo.',
        ['3'] = 'Não consigo adicionar à white-list esse utilizador porque ele já deixou este grupo.',
        ['4'] = 'Não consigo adicionar à white-list esse utilizador porque ele já foi banido neste grupo.'
    },
    ['wikipedia'] = {
        ['1'] = 'Ver mais.'
    },
    ['youtube'] = {
        ['1'] = 'Anterior',
        ['2'] = 'Seguinte',
        ['3'] = 'Está na pagina %s de %s!'
    }
}