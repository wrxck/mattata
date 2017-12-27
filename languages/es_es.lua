-- This is a language file for BarrePolice
-- Language: es-es
-- Author: Diego Barreiro (@barreeeiroo)

-- DO NOT CHANGE ANYTHING THAT BEGINS OR ENDS WITH A %
-- THESE ARE PLACEHOLDERS!

-- DO NOT CHANGE ANY MARKDOWN/HTML FORMATTING!
-- IF YOU ARE UNSURE, ASK ON TELEGRAM (t.me/BarrePolice)

return {
    ['errors'] = {
        ['connection'] = 'Error de conexión.',
        ['results'] = 'No he podido encontrar resultados.',
        ['supergroup'] = 'Este comando solo funciona en supergrupos.',
        ['admin'] = 'Necesitas ser un administrador o moderador para usar este comando.',
        ['unknown'] = 'No reconozco a ese usuario. Si quieres que lo detecte, reenvia un mensaje suyo a cualquier chat donde esté.',
        ['generic'] = 'Ha ocurrido un error!',
        ['use'] = 'No estás autorizado para usar esto!'
    },
    ['afk'] = {
        ['1'] = 'Ooops, esta función solo está disponible para usuarios con un @username público!',
        ['2'] = '%s ha vuelto tras estar AFK durante %s!',
        ['3'] = 'Nota',
        ['4'] = '%s está AFK.%s'
    },
    ['antispam'] = {
        ['1'] = 'Desactivar',
        ['2'] = 'Actiar',
        ['3'] = 'Desactivar límite',
        ['4'] = 'Activar límites en %s',
        ['5'] = 'Todos los ajustes de administración',
        ['6'] = '%s [%s] ha expulsado a %s [%s] de %s [%s] por alcanzar el límite anti-spam de [%s] multimedia.',
        ['7'] = 'Expulsado %s por alcanzar el límite antispam de [%s] mensajes.',
        ['8'] = 'El máximo límite es 100.',
        ['9'] = 'El mínimo límite es 1.',
        ['10'] = 'Edita la configuración antispam de %s aquí:'
    },
    ['appstore'] = {
        ['1'] = 'Ver en iTunes'
    },
    ['avatar'] = {
        ['1'] = 'No he podido coger el avatar de ese usuario, comprueba que has escrito correctamente el alias o ID.',
        ['2'] = 'Este usuario no tiene fotos de perfil.',
        ['3'] = 'Ese usuario no tiene tantas fotos!',
        ['4'] = 'Ese usuario ha desactivado la opción de recogida de datos, por eso no puedo acceder a ninguna de sus fotos.'
    },
    ['ban'] = {
        ['1'] = 'Que usuario quieres que banee? Especifica un alias o ID.',
        ['2'] = 'No puedo banear a este usuario porque es administrador o moderador.',
        ['3'] = 'No puedo banear a este usuario porque ya ha abandonado el chat.',
        ['4'] = 'No puedo banear a este usuario porque ya está baneado.',
        ['5'] = 'Necesito ser administrador del grupo para banear al usuario. Por favor, otórgame permisos y prueba otra vez.'
    },
    ['bash'] = {
        ['1'] = 'Por favor, especifica un comando a ejecutar!',
        ['2'] = 'Éxito!'
    },
    ['blacklist'] = {
        ['1'] = 'Que usuario quieres que ponga en la lista negra? Especifica un alias o ID.',
        ['2'] = 'No puedo poner a este usuario en la lista negra porque es es administrador o moderador.',
        ['3'] = 'No puedo poner a este usuario en la lista negra porque ha abandonado el chat.',
        ['4'] = 'No puedo poner a este usuario en la lista negra porque ya está en la lista negra.'
    },
    ['blacklistchat'] = {
        ['1'] = '%s ha sido puesto en la lista negra. Me saldré en cuanto me metan en ese chat!',
        ['2'] = '%s es un usuario, este comando solo funciona con grupos o canales!',
        ['3'] = '%s no parece ser un chat válido!'
    },
    ['bugreport'] = {
        ['1'] = 'Listo! Tu reporte se ha enviad. El ID de tu reporte es #%s.',
        ['2'] = 'Ha habido un error enviando el bug! Vaya, que ironía!'
    },
    ['calc'] = {
        ['1'] = 'Clica para enviar el resultado.'
    },
    ['captionbotai'] = {
        ['1'] = 'No puedo describir esta imagen!'
    },
    ['cats'] = {
        ['1'] = 'Miau!'
    },
    ['channel'] = {
        ['1'] = 'No estás autorizado para usar esto!',
        ['2'] = 'No parece que seas administrador en ese chat!',
        ['3'] = 'No he podido enviar el mensaje. Estás seguro de que soy administrador en él?',
        ['4'] = 'Tu mensaje se ha enviado!',
        ['5'] = 'No me ha sido posible obtener la lista de administradores de ese chat!',
        ['6'] = 'No parece que seas administrador en ese chat!',
        ['7'] = 'Especifica el mensaje a enviar, con /channel <canal> <mensaje>.',
        ['8'] = 'Estás seguro de enviar este mensaje? Así es como quedará:',
        ['9'] = 'Si, estoy seguro!',
        ['10'] = 'Ese mensaje contiene markdown inválido! Corrige la sintaxis y prueba de nuevo.'
    },
    ['commandstats'] = {
        ['1'] = 'No se han enviado comandos en ese chat!',
        ['2'] = '<b>Estadísticas de comandos para:</b> %s\n\n%s\n<b>Total de comandos enviados:</b> %s',
        ['3'] = 'Las estadísticas de comandos para este chat se han reseteado!',
        ['4'] = 'No he podido resetear las estadísticas de comando para este chat. Puede que ya se hayan reseteado?'
    },
    ['control'] = {
        ['1'] = 'Psst, ya quisieras!',
        ['2'] = '%s se está reiniciando...'
    },
    ['copypasta'] = {
        ['1'] = 'El mensaje respondido no puede ser superior a %s carácteres!'
    },
    ['custom'] = {
        ['1'] = 'Listo! El mensaje será enviado cada vez que alguien use %s!',
        ['2'] = 'El comando "%s" no existe!',
        ['3'] = 'El comando "%s" se ha eliminado!',
        ['4'] = 'No has puesto ningún comando personalizado!',
        ['5'] = 'Comandos personalizados para %s:\n',
        ['6'] = 'Para crear un nuevo comando personalizado, usa la siguiente sintaxis:\n/custom new #comando <mensaje>. Para mostrar la lista de comandos personalizados, usa /custom list. Para eliminar un comando personalizado, usa /custom del #comando.'
    },
    ['delete'] = {
        ['1'] = 'No he podido eliminar ese mensaje. Puede que el mensaje sea demasiado viejo o inexistente?'
    },
    ['demote'] = {
        ['1'] = 'Que usuario quieres que degrade? Especifica un alias o ID.',
        ['2'] = 'No puedo degradar a este usuario porque no es administrador o moderador.',
        ['3'] = 'No puedo degradar a este usuario porque ha abandonado el chat.',
        ['4'] = 'No puedo degradar a este usuario porque ha sido expulsado.'
    },
    ['doge'] = {
        ['1'] = 'Introduce el texto a Doge-ficar. Cada frase debe ir separada en una línea nueva.'
    },
    ['exec'] = {
        ['1'] = 'Selecciona el idioma de programación del código a ejecutar:',
        ['2'] = 'Ha ocurrido un error! Tiempo de espera de conexión superior. Estás intentando volverme más lento?',
        ['3'] = 'Has seleccionado "%s" – Estás seguro?',
        ['4'] = 'Atrás',
        ['5'] = 'Si, estoy seguro',
        ['6'] = 'Introduce un fragmento del código a ejecutar. No tienes que especificar un lenguaje, lo haremos después!',
        ['7'] = 'Selecciona el lenguaje de programación del código a ejecutar:'
    },
    ['facebook'] = {
        ['1'] = 'Ha ocurrido un error!',
        ['2'] = 'Introduce el nombre de usuario de Facebook del que quieres obtener una foto.',
        ['3'] = 'Ver a @%s en Facebook'
    },
    ['fact'] = {
        ['1'] = 'Generar otro'
    },
    ['flickr'] = {
        ['1'] = 'Has buscado por:',
        ['2'] = 'Introduce tu búsqueda (esto es, que quieres que busque yo en Flickr, por ejemplo "Big Ben" dará una foto del Big Ben de Londres).',
        ['3'] = 'More Results'
    },
    ['game'] = {
        ['1'] = 'Victorias: %s\nDerrotas: %s\nBalance: %s BarreMonedas',
        ['2'] = 'Unirse al juego',
        ['3'] = 'Este juego ya ha acabado!',
        ['4'] = 'No es tu turno!',
        ['5'] = 'No eres parte de este juego!',
        ['6'] = 'No puedes ir aquí!',
        ['7'] = 'Ya eres parte del juego!',
        ['8'] = 'Este juego ya ha empezado!',
        ['9'] = '%s [%s] está jugando contra %s [%s]\nLe toca a %s!',
        ['10'] = '%s ganó contra %s!',
        ['11'] = '%s empató contra %s!',
        ['12'] = 'Esperando por oponente...',
        ['13'] = '3 en Raya',
        ['14'] = 'Clica para enviar el juego a algún chat!',
        ['15'] = 'Estadísticas para %s:\n',
        ['16'] = 'Jugar al 3 en Raya!'
    },
    ['gblacklist'] = {
        ['1'] = 'Responde al usuario que quieras poner en la lista negra global, o dime su alias o ID.',
        ['2'] = 'No he podido obtener la información de "%s", comprueba que es un alias o ID válido y prueba de nuevo.',
        ['3'] = 'Eso es un %s, no un usuario!'
    },
    ['gif'] = {
        ['1'] = 'Introduce un término de búsqueda (esto es, quieres que busque en GIPHY, por ejemplo "gato" dará un GIF de un gato).'
    },
    ['gwhitelist'] = {
        ['1'] = 'Responde al usuario que quieras quitar de la lista negra global, o dime su alias o ID.',
        ['2'] = 'No he podido obtener la información de "%s", comprueba que es un alias o ID válido y prueba de nuevo.',
        ['3'] = 'Eso es un %s, no un usuario!'
    },
    ['hackernews'] = {
        ['1'] = 'Últimas historias de Hacker News:'
    },
    ['help'] = {
        ['1'] = 'No se han encontrado resultados!',
        ['2'] = 'No hay funciones que coincidan con "%s", intenta ser más específico!',
        ['3'] = '\n\nArgumentos: <requerido> [opcional]\n\nBusca una función o recibe ayuda con un comando con mi funcionalidad inline - solo mencióname en cualquier chat con @%s <búsqueda>.',
        ['4'] = 'Anterior',
        ['5'] = 'Siguiente',
        ['6'] = 'Atrás',
        ['7'] = 'Buscar',
        ['8'] = 'Página %s de %s!',
        ['9'] = [[
Puedo realizar funciones de administración en grupos, simplemente añádeme a uno con todos los poderes administrativos y envía /administration para ajustar las configuraciones del grupo.
Algunos comandos administrativos con una pequeña descripción:

• /pin <texto> - Envía un mensaje con formateo markdown que puede ser editado con el mismo comando, que puede ser guardado, editado y anclado en cualquier momento (esto no ocurre se puede hacer si el mensaje es más viejo que 48 horas, pero con el bot si)

• /ban - Banea a un usuario respondiendo a un mensaje, o poniendo su alias o ID

• /kick - Expulsa (baneo y luego desbaneo) a un usuario respondiendo a un mensaje, o poniendo su alias o ID

• /unban - Desbanea a un usuario respondiendo a un mensaje, o poniendo su alias o ID

• /setrules <texto> - Pone las reglas con formateo markdown, que serán enviadas con el comando /rules

• /trust - Confía en un usuario. Sólo administradores y usuarios pueden usarlo, y ellos pueden darle permisos para saltarse filtros.
        ]],
        ['10'] = [[
• /setwelcome - Pone el texto recibido con formateo markdown como mensaje de bienvenida, que será enviado cada vez que alguien se una al grupo (este mensaje se puede desactivar desde la configuración del grupo, con el comando /administration). Puedes usar campos predefinidos para poner un mensaje personalizado. Usa $user\_id para insertar el ID númerico del usuario, $chat\_id para el ID númerico de chat, $name para insertar el nombre del usuario, $title para insertar el título de chat y $username para insertar el alias del usuario (si el usuario no tiene un alias como @username, se mostrará su nombre, así que es mejor usar $name en vez de este)

• /warn - Avisa a un usuario, y lo banea cuando se alcanza el número máximo de avisos

• /mod - Asciende al usuario al que se responde, dándole acceso a comandos como /ban, /kick, /warn etc. (esto es útil si quieres que un administrador no tenga permiso para eliminar mensajes)

• /demod - Desciende al usuario al que se responde, retirándole sus privilegios de moderación y evitar que use comandos de administración

• /staff - Mira al creador, administradores y moderadores en una bonita lista
        ]],
        ['11'] = [[
• /report - Reenvia el mensaje al que se responde a los administradores y les avisa de la situación

• /setlink <URL> - Fija el link del grupo a una URL fija, que será enviada con el comando /link

• /links <texto> - Ignora los enlaces de Telegram encontrados en ese texto (incluyendo enlaces de alias como @username)
        ]],
        ['12'] = 'Algunos links que pueden ser útiles:',
        ['13'] = 'Desarrollo',
        ['14'] = 'Canal',
        ['15'] = 'Soporte',
        ['16'] = 'FAQ',
        ['17'] = 'Código Fuente',
        ['18'] = 'Donar',
        ['19'] = 'Evaluar',
        ['20'] = 'Registro de Administraciones',
        ['21'] = 'Ajustes de Administración',
        ['22'] = 'Plugins',
        ['23'] = [[
<b>Hola %s! Mi nombre es %s, es un placer conocerte</b> %s

Entiendo muchos comandos, de los cuales puedes aprender más pulsando el botón "Commands" usando el teclado de abajo.

%s <b>Truco:</b> Usa el botón "Settings" Para cambiar como funciono%s!

%s <b>Me encuentras útil, o me quieres ayudar?</b> Las donaciones son muy apreciadas, usa /donate para más información!
        ]],
        ['24'] = 'en'
    },
    ['id'] = {
        ['1'] = 'Ooops, no reconozco a ese usuario. Para enseñarme quien es, reenvíame un mensaje o dile que me hable.',
        ['2'] = 'Chat solicitado:',
        ['3'] = 'Este chat:',
        ['4'] = 'Clica para enviar el resultado!'
    },
    ['imdb'] = {
        ['1'] = 'Anterior',
        ['2'] = 'Siguiente',
        ['3'] = 'Página %s de %s!'
    },
    ['import'] = {
        ['1'] = 'No reconozco ese chat!',
        ['2'] = 'No es un supergrupo, por eso no puedo importar la configuración!',
        ['3'] = 'Importadas las configuraciones administrativas y de plugins de %s a %s!'
    },
    ['info'] = {
        ['1'] = [[
```
Redis:
%s Archivo de configuración: %s
%s Modo: %s
%s Puerto TCP: %s
%s Versión: %s
%s Tiempo encendido: %s days
%s ID de proceso: %s
%s Claves expiradas: %s

%s Número de usuarios: %s
%s Número de grupos: %s
%s Mensajes recibidos: %s
%s Mensajes enviados: %s
%s Peticiones Callback recibidas: %s
%s Peticiones Inline recibidas: %s

Sistema:
%s SO: %s
```
        ]]
    },
    ['instagram'] = {
        ['1'] = '@%s en Instagram'
    },
    ['ipsw'] = {
        ['1'] = '<b>%s</b> iOS %s\n\n<code>Firma MD5: %s\nFirma SHA1: %s\nTamaño del archivo: %s GB</code>\n\n<i>%s %s</i>',
        ['2'] = 'Este firmware ya no está firmado!',
        ['3'] = 'Este firmware aún se firma!',
        ['4'] = 'Selecciona tu modelo:',
        ['5'] = 'Selecciona la versión del firmware:',
        ['6'] = 'Selecciona el tipo de dispositivo:',
        ['7'] = 'iPod Touch',
        ['8'] = 'iPhone',
        ['9'] = 'iPad',
        ['10'] = 'Apple TV'
    },
    ['ispwned'] = {
        ['1'] = 'Esa cuenta se ha encontrado en las siguientes bases de datos:'
    },
    ['itunes'] = {
        ['1'] = 'Nombre:',
        ['2'] = 'Artista:',
        ['3'] = 'Álbum:',
        ['4'] = 'Pista:',
        ['5'] = 'Disco:',
        ['6'] = 'La búsqueda original no pudo ser encontrada, posiblemente se haya borrado el mensaje.',
        ['7'] = 'El resultado se puede encontrar aquí:',
        ['8'] = 'Introduce tu término de bísqueda (esto es, si quieres que busque en iTunes, por ejemplo "Green Day American Idiot" devolverá el primer resultado de American Idiot by Green Day).',
        ['9'] = 'Obtener resultados del trabajo'
    },
    ['kick'] = {
        ['1'] = 'Que usuario quieres que expulse? Especifica un alias o ID.',
        ['2'] = 'No puedo expulsar a este usuario porque es administrador o moderador.',
        ['3'] = 'No puedo expulsar a este usuario porque ya ha abandonado el chat.',
        ['4'] = 'No puedo expulsar a este usuario porque ya está expulsado.',
        ['5'] = 'Necesito ser administrador del grupo para expulsar al usuario. Por favor, otórgame permisos y prueba otra vez.'
    },
    ['lastfm'] = {
        ['1'] = 'El usuario de last.fm de %s se ha guardado a "%s".',
        ['2'] = 'He borrado tu usuario de last.fm!',
        ['3'] = 'No tienes guardad un usuario de last.fm!',
        ['4'] = 'Especifica tu usuario de last.fm o ponlo con /fmset.',
        ['5'] = 'No se ha encontrado historial para ese usuario.',
        ['6'] = '%s ahora mismo está escuchando a:\n',
        ['7'] = '%s por última vez ha escuchado:\n',
        ['8'] = 'Desconocido',
        ['9'] = 'Clica para enviar el resultado.'
    },
    ['location'] = {
        ['1'] = 'No tienes ninguna ubicación puesta. Que ubicación quieres usar?'
    },
    ['logchat'] = {
        ['1'] = 'Introduce el alias o ID del chat al que quieres reenviar el registro de todas las acciones administrativas.',
        ['2'] = 'Comprobando si es un chat válido...',
        ['3'] = 'Ooops, parece que me has dado un chat inválido, o me has especificado un chat al que no he sido añadido. Corrígelo y prueba de nuevo.',
        ['4'] = 'No puedes poner un usuario como chat de registro!',
        ['5'] = 'No parece que seas administrador en el chat!',
        ['6'] = 'Parece que ya estoy usando ese chat como registro de acciones! Usa /logchat para especificar uno distinto.',
        ['7'] = 'Ese chat es válido, voy a intentar enviar un mensaje de prueba, para comprobar que tengo permiso para enviar mensajes!',
        ['8'] = 'Hola Mundo! - este es un mensaje de prueba para comprobar si tengo permiso para enviar mensajes - si estás leyendo esto es porque todo está OK!',
        ['9'] = 'Todo correcto! Desde ahora, todas las acciones serán registradas a %s - para cambiar a donde envío el registro, solo envía /logchat.'
    },
    ['lua'] = {
        ['1'] = 'Introduce la línea de Lua a ejecutar!'
    },
    ['lyrics'] = {
        ['1'] = 'Spotify',
        ['2'] = 'Mostrar letra',
        ['3'] = 'Introduce un término de búsqueda (esto es, de que canción quieres que muestre la letra, por ejemplo "Despacito" dará la letra de la canción Despacito de Luis Fonsi).'
    },
    ['minecraft'] = {
        ['1'] = '<b>%s ha cambiado su nombre de usuario %s vez</b>',
        ['2'] = '<b>%s ha cambiado su nombre de usuario %s veces</b>',
        ['3'] = 'Anterior',
        ['4'] = 'Siguiente',
        ['5'] = 'Atrás',
        ['6'] = 'UUID',
        ['7'] = 'Avatar',
        ['8'] = 'Historial de Nombre de Usuario',
        ['9'] = 'Selecciona una opción:',
        ['10'] = 'Introduce el nombre de usuario del jugador de Minecraft del que quieras sacar la información (por ejemplo, enviando "Notch" dará la información del jugar Notch).',
        ['11'] = 'Los nombres de usuario de Minecraft son de 3 a 16 carácteres de largo.'
    },
    ['msglink'] = {
        ['1'] = 'Solo puedes usar este comando en supergrupos y canales.',
        ['2'] = 'Este %s tiene que ser público, con un alias como @username.',
        ['3'] = 'Reponde al mensaje del que quieras sacar el enlace.'
    },
    ['mute'] = {
        ['1'] = 'Que usuario quieres que silencie? Especifica un alias o ID.',
        ['2'] = 'No puedo silenciar a este usuario porque ya está silenciado.',
        ['3'] = 'No puedo silenciar a este usuario porque es administrador o moderador.',
        ['4'] = 'No puedo silenciar a este usuario porque ha sido expulsado o ha abandonado el chat.',
        ['5'] = 'Necesito ser administrador del grupo para silenciar al usuario. Por favor, otórgame permisos y prueba otra vez.'
    },
    ['myspotify'] = {
        ['1'] = 'Perfil',
        ['2'] = 'Siguiendo',
        ['3'] = 'Escuchado recientemente',
        ['4'] = 'Escuchando ahora mismo',
        ['5'] = 'Mejores pistas',
        ['6'] = 'Mejores artistas',
        ['7'] = 'No parece que estés siguiendo a ningún artista!',
        ['8'] = 'Tus mejores artistas',
        ['9'] = 'No parece que tengas ninguna pista en tu música!',
        ['10'] = 'Tus mejores pistas',
        ['11'] = 'No parece que estés siguiendo a ningún artista!',
        ['12'] = 'Artistas que sigues',
        ['13'] = 'No parece que hayas reproducido ninguna pista recientemente!',
        ['14'] = '<b>Escuchado recientemente</b>\n%s %s\n%s %s\n%s Escuchado a las %s:%s el %s/%s/%s.',
        ['15'] = 'La solicitud se ha recibido para procesarla, pero aún no se ha completado.',
        ['16'] = 'No parece que estés escuchando nada ahora mismo!',
        ['17'] = 'Escuchando ahora mismo',
        ['18'] = 'Ha ocurrido un error a la hora de reautorizar tu cuenta de Spotify!',
        ['19'] = 'Cuenta de Spotify reautorizada! Procesando solicitud original...',
        ['20'] = 'Reautorizando tu cuenta de Spotify, por favor espera...',
        ['21'] = 'Tienes que autorizar a BarrePolice para que acceda a tu cuenta de Spotify. Clica [aquí](https://accounts.spotify.com/en/authorize?client_id=%s&response_type=code&redirect_uri=%s&scope=user-library-read%%20playlist-read-private%%20playlist-read-collaborative%%20user-read-private%%20user-read-birthdate%%20user-read-email%%20user-follow-read%%20user-top-read%%20user-read-playback-state%%20user-read-recently-played%%20user-read-currently-playing%%20user-modify-playback-state) y pulsa el botón "VALE" verde para enlazar a BarrePolice con tu cuenta de Spotify. Una vez que hayas hecho eso, envíame el enlace al que te redirigió (debería comenzar con "%s", seguido de un código) en respuesta a este mensaje.',
        ['22'] = 'Listas de reproducción',
        ['23'] = 'Usar modo Inline',
        ['24'] = 'Letra',
        ['25'] = 'No se encontraron dispositivos.',
        ['26'] = 'No parece que tengas ninguna lista de reproducción.',
        ['27'] = 'Tus listas de reproducción',
        ['28'] = '%s %s [%s pistas]',
        ['29'] = '%s %s [%s]\nUsuario %s de Spotify\n\n<b>Dispoitivos:</b>\n%s',
        ['30'] = 'Reproduciendo pista anterior...',
        ['31'] = 'No eres un usuario premium!',
        ['32'] = 'No he podido encontrar ningún dispositivo.',
        ['33'] = 'Reproduciendo pista siguiente...',
        ['34'] = 'Reproduciendo pista...',
        ['35'] = 'Tu dispositivo no está disponible temporalmente...',
        ['36'] = 'No se encontraron dispositivos!',
        ['37'] = 'Pausando pista...',
        ['38'] = 'Ahora escuchando',
        ['39'] = 'Mezclando música...',
        ['40'] = 'Ese no es un volumen válido. Especifica un valor entre 0 y 100.',
        ['41'] = 'El volumen se ha puesto en %s%%!',
        ['42'] = 'Este mensaje es demasiado viejo, solicita uno nuevo con /myspotify!'
    },
    ['name'] = {
        ['1'] = 'El nombre al que respondo actualmente es "%s" - para cambiar esto, usa /name <texto> (donde <texto> es el nombre al que quieres que responda).',
        ['2'] = 'Mi nombre tiene que tener entre 2 y 32 carácteres!',
        ['3'] = 'Mi nombre solo puede tener carácteres alfanuméricos!',
        ['4'] = 'Ahora responderé a "%s", en vez de a "%s" - para cambiar esto, usa /name <texto> (donde <texto> es el nombre al que quieres que responda).'
    },
    ['netflix'] = {
        ['1'] = 'Leer más.'
    },
    ['news'] = {
        ['1'] = '"<code>%s</code>" no es un patrón válido en Lua.',
        ['2'] = 'No he podido recoger ninguna lista de fuente de noticias.',
        ['3'] = '<b>Fuentes de noticias que coinciden con</b> "<code>%s</code>":\n\n%s',
        ['4'] = '<b>Aquí están todas las fuentes de noticias disponibles con</b> /news<b>. Usa</b> /nsources &lt;query&gt; <b>para buscar entre la lista de fuentes. Las búsquedas se realizan con patrones de Lua</b>\n\n%s',
        ['5'] = 'No tienes ninguna fuente de noticias guardada. Usa /setnews <fuente> para poner una. Mira todas las fuentes disponibles con /nsources, o filtra los resultados con /nsources <filtro>.',
        ['6'] = 'Tu fuente de noticias preferida es %s. Usa /setnews <fuente> para cambiarlo. Mira todas las fuentes disponibles con /nsources, o filtra los resultados con /nsources <filtro>.',
        ['7'] = 'Tu fuente de noticias preferida ya está puesta a %s! Usa /news para ver las últimas noticias.',
        ['8'] = 'Eso no es una fuente de noticias válida. Mira todas las fuentes disponibles con /nsources, o filtra los resultados con /nsources <filtro>.',
        ['9'] = 'Tu fuente de noticias preferida se ha guardado a %s! Usa /news para ver las últimas noticias.',
        ['10'] = 'Eso no es una fuente de noticias válida, usa /nsources para ver una lista de fuentes de noticias. Si te gusta una en concreto, usa /setnews <fuente> para ver siempre noticias de esa fuente con /news, sin tener que especificar nada.',
        ['11'] = 'Leer más.'
    },
    ['nick'] = {
        ['1'] = 'He olvidado tu alias!',
        ['2'] = 'Tu alias se ha puesto como "%s"!'
    },
    ['optout'] = {
        ['1'] = 'Has vuelto a entrar en el sistema de recogida de datos! Usa /optout para salir.',
        ['2'] = 'Te has salido del sistema de recogida de datos! Usa /optin para entrar.'
    },
    ['paste'] = {
        ['1'] = 'Selecciona un servicio al que quieres subir la nota:'
    },
    ['pin'] = {
        ['1'] = 'No has anclado ningún mensaje. Usa /pin <texto> para poner uno. Formateado markdown está permitido.',
        ['2'] = 'Aquí está el último mensaje generado con /pin.',
        ['3'] = 'He encontrado un mensaje con /pin en la base de datos, pero parece que se ha eliminado y no lo puedo encontrar. Puedes poner uno nuevo con /pin <texto>. Formateado markdown está permitido.',
        ['4'] = 'Hubo un error poniendo el nuevo mensaje anclado. Puede que tuviese Markdown inválido, o el mensaje anclado se haya eliminado. Voy a intentar anclar un nuevo mensaje - si necesitas editarlo, después de comprobar que exista, usa /pin <texto>.',
        ['5'] = 'No pude anclar ese mensaje porque contiene Markdown inválido.',
        ['6'] = 'Clica aquí para ver el nuevo mensaje anclado.'
    },
    ['pokedex'] = {
        ['1'] = 'Nombre: %s\nID: %s\nTipo: %s\nDescripción: %s'
    },
    ['promote'] = {
        ['1'] = 'I cannot promote this user because they are a moderator or an administrator of this chat.',
        ['2'] = 'I cannot promote this user because they have already left this chat.',
        ['3'] = 'I cannot promote this user because they have already been kicked from this chat.'
    },
    ['quote'] = {
        ['1'] = 'This user has opted out of data-storing functionality.',
        ['2'] = 'There are no saved quotes for %s%s! You can save one by using /save in reply to a message they send.'
    },
    ['report'] = {
        ['1'] = 'Please reply to the message you would like to report to the group\'s administrators.',
        ['2'] = 'You can\'t report your own messages, are you just trying to be funny?',
        ['3'] = '<b>%s needs help in %s!</b>',
        ['4'] = 'Click here to view the reported message.',
        ['5'] = 'I\'ve successfully reported that message to %s admin(s)!'
    },
    ['save'] = {
        ['1'] = 'This user has opted out of data-storing functionality.',
        ['2'] = 'That message has been saved in my database, and added to the list of possible responses for when /quote is used in reply to %s%s!'
    },
    ['sed'] = {
        ['1'] = '%s\n\n<i>%s didn\'t mean to say this!</i>',
        ['2'] = '%s\n\n<i>%s has admitted defeat.</i>',
        ['3'] = '%s\n\n<i>%s isn\'t sure if they were mistaken...</i>',
        ['4'] = 'Screw you, <i>when am I ever wrong?</i>',
        ['5'] = '"<code>%s</code>" isn\'t a valid Lua pattern.',
        ['6'] = '<b>Hi, %s, did you mean:</b>\n<i>%s</i>',
        ['7'] = 'Yes',
        ['8'] = 'No',
        ['9'] = 'Not sure'
    },
    ['setgrouplang'] = {
        ['1'] = 'This group\'s language has been set to %s!',
        ['2'] = 'This group\'s language is currently %s.\nPlease note that some strings may not be translated as of yet. If you\'d like to change your language, select one using the keyboard below:',
        ['3'] = 'The option to force users to use the same language in this group is currently disabled. This setting should be toggled from /administration but, to make things easier for you, I\'ve included a button below.',
        ['4'] = 'Enable',
        ['5'] = 'Disable'
    },
    ['setlang'] = {
        ['1'] = 'Your language has been set to %s!',
        ['2'] = 'Your language is currently %s.\nPlease note that some strings may not be translated as of yet. If you\'d like to change your language, select one using the keyboard below:'
    },
    ['setlink'] = {
        ['1'] = 'That\'s not a valid URL.',
        ['2'] = 'Link set successfully!'
    },
    ['setrules'] = {
        ['1'] = 'Invalid Markdown formatting.',
        ['2'] = 'Successfully set the new rules!'
    },
    ['setwelcome'] = {
        ['1'] = 'What would you like the welcome message to be? The text you specify will be Markdown-formatted and sent every time a user joins the chat (the welcome message can be disabled in the administration menu, accessible via /administration). You can use placeholders to automatically customise the welcome message for each user. Use $user_id to insert the user\'s numerical ID, $chat_id to insert the chat\'s numerical ID, $name to insert the user\'s name, $title to insert the chat\'s title and $username to insert the user\'s username (if the user doesn\'t have an @username, their name will be used instead, so it is best to avoid using this in conjunction with $name).',
        ['2'] = 'There was an error formatting your message, please check your Markdown syntax and try again.',
        ['3'] = 'The welcome message for %s has successfully been updated!'
    },
    ['share'] = {
        ['1'] = 'Share'
    },
    ['shorten'] = {
        ['1'] = 'Please select a URL shortener using the buttons below:'
    },
    ['shsh'] = {
        ['1'] = 'I couldn\'t fetch any SHSH blobs for that ECID, please ensure it\'s valid and you have saved them using https://tsssaver.1conan.com.',
        ['2'] = 'SHSH blobs for that device are available for the following versions of iOS:\n',
        ['3'] = 'Download .zip'
    },
    ['statistics'] = {
        ['1'] = 'No se han enviado mensajes en este chat!',
        ['2'] = '<b>Estadísticas para:</b> %s\n\n%s\n<b>Número total de mensajes:</b> %s',
        ['3'] = 'Las estadísticas para este chat se han reseteado!',
        ['4'] = 'No he podido resetear las estadísticas para este chat. Puede que ya se hayan reseteado'
    },
    ['steam'] = {
        ['1'] = 'Your Steam username has been set to "%s".',
        ['2'] = '"%s" isn\'t a valid Steam username.',
        ['3'] = '%s has been a user on Steam since %s, on %s. They last logged off at %s, on %s. Click <a href="%s">here</a> to view their Steam profile.',
        ['4'] = '%s, AKA "%s",'
    },
    ['trust'] = {
        ['1'] = 'I cannot trust this user because they are a moderator or an administrator of this chat.',
        ['2'] = 'I cannot trust this user because they have already left this chat.',
        ['3'] = 'I cannot trust this user because they have already been kicked from this chat.'
    },
    ['unmute'] = {
        ['1'] = 'Which user would you like me to unmute? You can specify this user by their @username or numerical ID.',
        ['2'] = 'I cannot unmute this user because they are not currently muted in this chat.',
        ['3'] = 'I cannot unmute this user because they are a moderator or an administrator in this chat.',
        ['4'] = 'I cannot unmute this user because they have already left (or been kicked from) this chat.'
    },
    ['untrust'] = {
        ['1'] = 'Which user would you like me to untrust? You can specify this user by their @username or numerical ID.',
        ['2'] = 'I cannot untrust this user because they are a moderator or an administrator in this chat.',
        ['3'] = 'I cannot untrust this user because they have already left this chat.',
        ['4'] = 'I cannot untrust this user because they have already been kicked from this chat.'
    },
    ['upload'] = {
        ['1'] = 'Please reply to the file you\'d like to download to the server. It must be <= 20 MB.',
        ['2'] = 'That file is too large. It must be <= 20 MB.',
        ['3'] = 'I couldn\'t get this file, it\'s probably too old.',
        ['4'] = 'There was an error whilst retrieving this file.',
        ['5'] = 'Successfully downloaded the file to the server - it can be found at <code>%s</code>!'
    },
    ['version'] = {
        ['1'] = '@%s AKA %s `[%s]` is running BarrePolice %s, created by [Duegi Barreiro](https://t.me/barreeeiroo). The source code is available on [GitHub](https://github.com/barreeeiroo/BarrePolice).'
    },
    ['voteban'] = {
        ['1'] = 'Which user would you like to open up a vote-ban for? You can specify this user by their @username or numerical ID.',
        ['2'] = 'I cannot setup a vote-ban for this user because they are a moderator or an administrator in this chat.',
        ['3'] = 'I cannot setup a vote-ban for this user because they have already left (or been kicked from) this chat.',
        ['4'] = 'Should %s [%s] be banned from %s? %s upvotes are required for an immediate ban, and %s downvotes are required for this vote to be closed.',
        ['5'] = 'Yes [%s]',
        ['6'] = 'No [%s]',
        ['7'] = 'The people have spoken. I have banned %s [%s] from %s because %s people voted for me to do so.',
        ['8'] = 'The required upvote amount was reached, however, I was unable to ban %s - perhaps they\'ve left the group or been promoted since we opened the vote to ban them? It\'s either that, or I no longer have the administrative privileges required in order to perform this action!',
        ['9'] = 'The people have spoken. I haven\'t banned %s [%s] from %s because the required %s people downvoted the decision to ban them.',
        ['10'] = 'You upvoted the decision to ban %s [%s]!',
        ['11'] = 'Your current vote has been retracted, use the buttons again to re-submit your vote.',
        ['12'] = 'You downvoted the decision to ban %s [%s]!',
        ['13'] = 'A vote-ban has already been opened for this user!'
    },
    ['weather'] = {
        ['1'] = 'You don\'t have a location set. Use /setloc <location> to set one.',
        ['2'] = 'It\'s currently %s (feels like %s) in %s. %s'
    },
    ['welcome'] = {
        ['1'] = 'Group Rules'
    },
    ['whitelist'] = {
        ['1'] = 'Which user would you like me to whitelist? You can specify this user by their @username or numerical ID.',
        ['2'] = 'I cannot whitelist this user because they are a moderator or an administrator in this chat.',
        ['3'] = 'I cannot whitelist this user because they have already left this chat.',
        ['4'] = 'I cannot whitelist this user because they have already been banned from this chat.'
    },
    ['wikipedia'] = {
        ['1'] = 'Read more.'
    },
    ['youtube'] = {
        ['1'] = 'Previous',
        ['2'] = 'Next',
        ['3'] = 'You are on page %s of %s!'
    }
}
