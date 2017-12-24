-- This is a language file for mattata
-- Language: tr-tr
-- Author: By_Azade

-- DO NOT CHANGE ANYTHING THAT BEGINS OR ENDS WITH A %
-- THESE ARE PLACEHOLDERS!

-- DO NOT CHANGE ANY MARKDOWN/HTML FORMATTING!
-- IF YOU ARE UNSURE, ASK ON TELEGRAM (t.me/mattataDev)

return {
    ['errors'] = {
        ['connection'] = 'Bağlantı Hatası',
        ['results'] = 'Bunun için herhangi bir sonuç bulamadım.',
        ['supergroup'] = 'Bu komut sadece grupta kullanılır.',
        ['admin'] = 'Bu komutu kullanabilmeniz için grupta admin veya moderatör olmalısınız.',
        ['unknown'] = 'Bu kullanıcıyı tanımıyorum. Eğer onu bana tanıtmak isterseniz, mesajını bana yönlendirin.',
        ['generic'] = 'Hata oluştu!',
        ['use'] = 'Bunu kullanmanıza izi yok!'
    },
    ['afk'] = {
        ['1'] = 'Üzgünüm, Bu özellik sadece aktif kullanıcılar için @kullanıcıadı şeklinde kullanılır!',
        ['2'] = '%s klavyeden uzaklaşarak tekrar geri döndü %s!',
        ['3'] = 'Not',
        ['4'] = '%s şuan klavyeden uzaklaştı.%s'
    },
    ['antispam'] = {
        ['1'] = 'Kapalı',
        ['2'] = 'Açık',
        ['3'] = 'Sınırı devre dışı bırak',
        ['4'] = 'Sınırları etkinleştir %s',
        ['5'] = 'Tüm Yönetim Ayarları',
        ['6'] = '%s [%s] Anti-spam medya limitine ulaşıldığı  %s [%s] için %s [%s] gruptan atıldı [%s] .',
        ['7'] = 'Atıldı %s anti-spam medya limitini aştığı için [%s] .',
        ['8'] = 'Maksimum sınır 100.',
        ['9'] = 'Minimum sınır is 1.',
        ['10'] = 'Aşağıdan %s anti-spam ayarlarını değiştirin:'
    },
    ['appstore'] = {
        ['1'] = 'iTunes de görüntüle'
    },
    ['avatar'] = {
        ['1'] = 'Bu kullanıcı için profil fotoğraflarını alamadım, lütfen geçerli bir kullanıcı adı veya sayısal kimlik belirttiğinizden emin olun.',
        ['2'] = 'Bu kullanıcının profil fotoğrafı yok..',
        ['3'] = 'Bu kullanıcının pek çok profil fotoğrafı yok!',
        ['4'] = 'Bu kullanıcı, veri toplama işlevini devre dışı bıraktı, bu nedenle profil fotoğraflarından hiçbirini size gösteremiyorum.'
    },
    ['ban'] = {
        ['1'] = 'Hangi kullanıcı banlamamı istersiniz? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Bu kullanıcıyı, bu sohbette bir moderatör veya yönetici oldukları için banlayamam.',
        ['3'] = 'Bu sohbetten ayrıldığı için bu kullanıcıyı banlayamam.',
        ['4'] = 'Bu sohbetten zaten banlandıkları için bu kullanıcıyı banlayamam.',
        ['5'] = 'Bu kullanıcıyı banlamam için admin izinlerine sahip olmam gerekiyor. Lütfen bu sorunu düzeltip tekrar deneyin.'
    },
    ['bash'] = {
        ['1'] = 'Lütfen çalıştırılacak bir komut belirtin!',
        ['2'] = 'Başarılı!'
    },
    ['blacklist'] = {
        ['1'] = 'Hangi kullanıcıyı kara listeye almamı istersiniz?? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Bu kullanıcıyı, bu sohbette bir moderatör veya yönetici oldukları için kara listeye alamam.',
        ['3'] = 'Bu sohbetten ayrıldığı için bu kullanıcıyı kara listeye alamam.',
        ['4'] = 'Bu sohbetten banlandığı için bu kullanıcıyı kara listeye alamam.'
    },
    ['blacklistchat'] = {
        ['1'] = '%s şimdi kara listeye alındı!',
        ['2'] = '%s bir kullanıcıysa, bu komut sadece gruplar ve kanallar gibi sohbetleri kara listeye almak için kullanılır!',
        ['3'] = '%s Geçerli bir sohbet gibi gözükmüyor!'
    },
    ['bugreport'] = {
        ['1'] = 'Başarılı! Hata raporunuz gönderilmiştir. Bu raporun kimliği #%s.',
        ['2'] = 'Bu hatayı bildirirken bir sorun oluştu! Ha, ironi!'
    },
    ['calc'] = {
        ['1'] = 'Sonuç göndermek için tıklayın.'
    },
    ['captionbotai'] = {
        ['1'] = 'Bu resmi gerçekten tarif edemiyorum!'
    },
    ['cats'] = {
        ['1'] = 'Miyavvv!'
    },
    ['channel'] = {
        ['1'] = 'Bunu kullanmanıza izin verilmiyor!',
        ['2'] = 'Bu sohbette artık yönetici gibi görünmüyorsunuz!',
        ['3'] = 'Mesajınızı gönderemedim, hala sohbet mesajı gönderme iznim var mı?',
        ['4'] = 'Mesajınız gönderildi!',
        ['5'] = 'Sohbet yöneticilerinin listesini alamadım!',
        ['6'] = 'Sohbette bir yönetici gibi görünmüyorsun!',
        ['7'] = 'Lütfen, gönderilecek mesajı /channel <kanal> <mesaj> sözdizimini kullanarak belirtin.',
        ['8'] = 'Bu mesajı göndermek istediğinizden emin misiniz? Nasıl görüneceği ise şöyledir:',
        ['9'] = 'Evet eminim!',
        ['10'] = 'Bu mesaj geçersiz Markdown biçimlendirme içeriyor! Lütfen sözdiziminizi düzeltin ve tekrar deneyin.'
    },
    ['commandstats'] = {
        ['1'] = 'Bu sohbette hiçbir komut gönderilmedi!',
        ['2'] = '<b>Komut için istatistikler:</b> %s\n\n%s\n<b>Toplam göderilen komutlar:</b> %s',
        ['3'] = 'Bu sohbetin komut istatistikleri sıfırlandı!',
        ['4'] = 'Bu sohbetin komut istatistiklerini sıfırlayamadım. Belki de daha önce sıfırlanmışlardır?'
    },
    ['control'] = {
        ['1'] = 'Pfft, dilersen!',
        ['2'] = '%s Yeniden yükleniyor...'
    },
    ['copypasta'] = {
        ['1'] = 'Yanıtlanan metin, %s karakterlerden uzun olmamalıdır.!'
    },
    ['counter'] = {
        ['1'] = 'Bu mesaja sayaç ekleyemedim!'
    },
    ['custom'] = {
        ['1'] = 'Başarılı! Bu mesaj şimdi birileri her kullandığı zaman gönderilecek %s!',
        ['2'] = 'Tetikleyici "%s" yok!',
        ['3'] = 'Tetikleyici  "%s" silindi!',
        ['4'] = 'Herhangi bir özel tetikleyici ayarlamadın!',
        ['5'] = 'Özel komutlar %s:\n',
        ['6'] = 'Yeni ve özel bir komut oluşturmak için şu sözdizimini kullanın:\n/custom new #tetikleyici <değer>.Tüm tetikleyiciler listesi için,  /custom list komutunu kullanın. Tetikleyiciyi silmek için ise, /custom del #trigger komutunu kullanın.'
    },
    ['delete'] = {
        ['1'] = 'Bu mesajı silemedim. Belki de mesaj çok eskidir veya mevcut değildir?'
    },
    ['demote'] = {
        ['1'] = 'Hangi kullanıcının yetkisini almamı istersin ? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Bu kullanıcıyı, bu sohbette bir moderatör veya yönetici olmadığı için yetkisini almam mümkün değil.',
        ['3'] = 'Bu sohbetten zaten ayrıldıı, bu kullanıcının yetkisini alamam.',
        ['4'] = 'Bu kullanıcı daha önce bu sohbetten atılmış ulduğu için yetkisini almam mümkün değil.'
    },
    ['doge'] = {
        ['1'] = 'Lütfen Dogeify istediğiniz metni girin. Her cümle eğik çizgi veya yeni satırlar kullanılarak ayrılmalıdır.'
    },
    ['exec'] = {
        ['1'] = 'Lütfen kodunuzu yürütmek istediğiniz dili seçin:',
        ['2'] = 'Bir hata oluştu! Bağlantı zaman aşımına uğradı. Beni geride bırakmaya mı çalışıyordun?',
        ['3'] = 'Seçtiniz "%s" – emin misin?',
        ['4'] = 'Geri',
        ['5'] = 'Eminim',
        ['6'] = 'Çalıştırmak istediğiniz kod parçacığını yazınız.Dili belirtmeniz gerekmiyor, bunu daha sonra yapacağız!',
        ['7'] = 'Lütfen kodunuzu yürütmek istediğiniz dili seçin:'
    },
    ['facebook'] = {
        ['1'] = 'Bir hata oluştu!',
        ['2'] = 'Lütfen profil resmini almak istediğiniz Facebook kullanıcısının adını girin.',
        ['3'] = 'Facebook da %s görüntüle'
    },
    ['fact'] = {
        ['1'] = 'Başka Bir Tane Oluştur'
    },
    ['flickr'] = {
        ['1'] = 'Aradığınız:',
        ['2'] = 'Lütfen bir arama sorgusu girin (Yani, Flickrı aramamı ne için istiyorsun, Örnek: "Kalem" kalem fotoğragları gösterilecek).',
        ['3'] = 'Daha fazla sonuç'
    },
    ['game'] = {
        ['1'] = 'Toplam kazanç: %s\nToplam kayıp: %s\nKalan: %s mattacoins',
        ['2'] = 'Oyuna Katıl',
        ['3'] = 'Bu oyun zaten bitti!',
        ['4'] = 'Senin sıran değil!',
        ['5'] = 'Bu oyunun bir parçası değilsin!',
        ['6'] = 'Bu oyuna giremezsiniz!',
        ['7'] = 'Zaten bu oyunun bir parçasısın!',
        ['8'] = 'Bu oyun zaten başladı!',
        ['9'] = '%s [%s] e karşı oynuyor %s [%s]\nŞuanda by %s\'s senin sıran!',
        ['10'] = '%s e karşı oyunu kazandı %s!',
        ['11'] = '%s e karşı oyundan çekildi %s!',
        ['12'] = 'Rakip bekleniyor...',
        ['13'] = 'Tic-Tac-Toe',
        ['14'] = 'Oyunu sohbete göndermek için tıklayın!',
        ['15'] = 'Oyun istatistiği %s:\n',
        ['16'] = 'Tic-Tac-Toe oyna!'
    },
    ['gblacklist'] = {
        ['1'] = 'Lütfen genel kara listeye eklemek istediğiniz kullanıcıyı yanıtlayın veya kullanıcı adı veya kimlik numarasına göre belirtin.',
        ['2'] = 'Hakkında bilgi alamadım "%s", lütfen geçerli bir kullanıcı adı veya kimliğini kontrol edin ve tekrar deneyin.',
        ['3'] = 'Bu bir %s kullanıcı değil'
    },
    ['gif'] = {
        ['1'] = 'Lütfen bir arama sorgusu girin (GIPHY de ne aramak istediğini belirt , örnek: "kedi" kedi ile ilgili olan GIF ler gösterilecek).'
    },
    ['gwhitelist'] = {
        ['1'] = 'Lütfen genel olarak beyaz listeye eklemek isteyen kullanıcıyı yanıtlayın, kullanıcı adı veya kimlik numarasına göre belirtin.',
        ['2'] = 'Hakkında bilgi alamadım "%s", lütfen geçerli bir kullanıcı adı veya kimliğini kontrol edin ve tekrar deneyin.',
        ['3'] = 'Bu bir %s kullanıcı değil'
    },
    ['hackernews'] = {
        ['1'] = 'Hacker Haberlerinden En Çok Okunan Hikayeler:'
    },
    ['help'] = {
        ['1'] = 'Sonuç bulunamadı!',
        ['2'] = '"%s" ile eşleşen hiçbir özellik bulunamadı, lütfen daha spesifik olmaya çalışın ve deneyin.!',
        ['3'] = '\n\nDeğişken: <required> [opsiyonel]\n\nSatır içi arama işlevselliğini kullanarak bir özellik arayın veya bir komutla yardım alın - @%s <arama sorgusu> sözdizimini kullanarak herhangi bir sohbetten bahsedin.',
        ['4'] = 'Önceki',
        ['5'] = 'Sonraki',
        ['6'] = 'Geri',
        ['7'] = 'Ara',
        ['8'] = '%s sayfanın %s sayfasındasın',
        ['9'] = [[
Gruplarınızda birçok idari işlem yapabilirim, Beni yönetici olarak eklemelisin ve grubunuzun ayarlarını yapmak için /administrator komutunu göndermelisin.
İşte bazı idari komutlar ve yaptıklarıyla ilgili kısa bir açıklama:

• /pin <yazı> - Aynı komutla farklı metni kullanarak düzenlenebilen Markdown formatlı bir mesaj gönderin, Bir mesajı düzenleyemiyorsanız bundan kurtulmak için yeniden sabitlemeniz gerekmez (Mesaj 48 saatten fazla sabit kalamaz)

• /ban - Bir kullanıcıyı, mesajlarından birine yanıt vererek veya kullanıcı adı / kimlik numarasıyla belirterek banla

• /kick - Bir kullanıcıyı mesajlarından birine yanıt vererek veya kullanıcı adı / kimlik numarasıyla belirterek bir kullanıcıyı banlayın (aynı şekilde unban komutu)

• /unban - Bir kullanıcıyı mesajlarından birine yanıt vererek veya kullanıcı adı / kimlik numarasıyla belirterek bir kullanıcının banını kaldırın

• /setrules <yazı> - Verilen Markdown formatlı metni, birisi kullandığı zaman gönderilecek olan grup kuralları olarak ayarlayın, /rules komutunu kullanarak
        ]],
        ['10'] = [[
• /setwelcome - Kullanıcının gruba katıldığı her zaman gösterilecek olan bir hoş geldin mesajı belirtin. (hoş geldin mesajı admin menüsünden kapalı olabilir, /administration komutu ile kontrol edin). Her kullanıcı için hoş geldiniz mesajını otomatik olarak özelleştirmek için yer tutucularını kullanabilirsiniz. Kullanıcının sayısal kimliğini eklemek için $user_id kullanın,sohbetin sayısal kimliğini eklemek için $chat_id, kullanıcının adını eklemek için $name, grubun ismini eklemek için $title ve kullanıcının kullanıcı adını eklemek için $username (eğer kullanıcının kullanıcı adı (@kullanıcıadı) yoksa, bunun yerine isimleri kullanılacak, bu yüzden $name ile birlikte kullanılmamalıdır.)

• /warn - Bir kullanıcıyı uyarmak ve maksimum uyarı sayısına ulaştığında onları banlamak için kullanılır

• /mod - Yanıtlanan kullanıcıya moderatör yetkisi verir, /ban, /kick, /warn vb  komutları kullanabilir.(Bu, birisinin mesajlarını silmeyi istemiyorsanız kullanışlıdır!)

• /demod - Yanıtlanan kullanıcınn moderatör yetkisini alır, moderatör komutlarını kullanamaz.

• /staff - Grubun kurucusunu, adminlerini, ve moderatörlerinin listesini gösterir.
        ]],
        ['11'] = [[
• /report - Yanıtlanan mesajı direk olarak admine rapor edip yönderir.

• /setlink <URL> - Grubun bağlantısını verilen URL'yi ayarlayın; /link bu komutu, biri kullanıldığında URL gönderilir.

• /links <yazı> - Verilen metinde bulunan tüm Telegram bağlantılarını beyaz listeye ekler ( @kullanıcıadı şeklinde olanları da)
        ]],
        ['12'] = 'Aşağıda yararlı bulabileceğiniz bazı bağlantılar verilmiştir.:',
        ['13'] = 'Geliştirme',
        ['14'] = 'Kanal',
        ['15'] = 'Destek',
        ['16'] = 'SSS',
        ['17'] = 'Kaynak',
        ['18'] = 'Bağışta bulunmak',
        ['19'] = 'Oylamak',
        ['20'] = 'Yönetim Günlüğü',
        ['21'] = 'Admin Ayarları',
        ['22'] = 'Eklentiler',
        ['23'] = [[
<b>Merhaba %s! Benim adım %s, sizinle tanışmak bir şeref idi</b> %s

Bir çok komutu anlıyorum, hangi komutu öğrenmek istiyorsan satır içinde "Komutlar" butonunu seçin.

%s <b>İpucu:</b> "Ayarlar" butonuna tıklayarak nasıl çalıştığımı öğrenin%s!

%s <b>Beni kullanışlı mı buldun, yoksa yardıma ihtiyaç mı var ?</b>Bağışlar çok takdir edilmektedir, /donate komutunu kullanarak daha fazla bilgi elde et!
        ]],
        ['24'] = 'içinde'
    },
    ['id'] = {
        ['1'] = 'Üzgünüm ama o kullanıcıyı tanımıyorum. Bana kim olduğunu öğretmek istersen, onun bir measjını bana ilet.',
        ['2'] = 'Sorgulanan Sohbet:',
        ['3'] = 'Bu sohbet:',
        ['4'] = 'Sonuç göndermek için tıklayın!'
    },
    ['imdb'] = {
        ['1'] = 'Önceki',
        ['2'] = 'Sonraki',
        ['3'] = '%s sayfanın %s sayfasındasın!'
    },
    ['import'] = {
        ['1'] = 'Bu sohbeti tanımıyorum!',
        ['2'] = 'Bu bir supergroup değil, bu nedenle herhangi bir ayarları aktaramıyorum!',
        ['3'] = '%s dan %s adresinden yönetim ayarlarını ve geçiş yapmış eklentileri başarıyla içe aktardı.!'
    },
    ['info'] = {
        ['1'] = [[
```
Dağıtım:
%s Yapılandırma Dosyası: %s
%s Mod: %s
%s TCP Port: %s
%s Versyon: %s
%s Çalışma süresi: %s days
%s Çalışma kimliği: %s
%s Süresi Dolmuş Anahtarlar: %s

%s Kullanıcı Sayısı: %s
%s Grup Sayısı: %s
%s Received Messages Count: %s
%s Sent Messages Count: %s
%s Received CallbackQueries Count: %s
%s Received InlineQueries Count: %s

Sistem:
%s İşletim sistemi: %s
```
        ]]
    },
    ['instagram'] = {
        ['1'] = '@%s İnstagram'
    },
    ['ipsw'] = {
        ['1'] = '<b>%s</b> iOS %s\n\n<code>MD5 toplamı: %s\nSHA1 toplamı: %s\nDosya boyutu: %s GB</code>\n\n<i>%s %s</i>',
        ['2'] = 'Bu yazılım artık imzalanmıyor!',
        ['3'] = 'Bu yazılım hala imzalanıyor!',
        ['4'] = 'Lütfen modelinizi seçin:',
        ['5'] = 'Lütfen bellenim sürümünüzü seçin:',
        ['6'] = 'Lütfen aygıt türünü seçin:',
        ['7'] = 'iPod Touch',
        ['8'] = 'iPhone',
        ['9'] = 'iPad',
        ['10'] = 'Apple TV'
    },
    ['ispwned'] = {
        ['1'] = 'Bu hesap aşağıdaki sızıntılarda bulundu:'
    },
    ['itunes'] = {
        ['1'] = 'İsim:',
        ['2'] = 'Sanatçı:',
        ['3'] = 'Albüm:',
        ['4'] = 'Parça:',
        ['5'] = 'Disk:',
        ['6'] = 'Orijinal sorgu bulunamadı, muhtemelen orijinal iletiyi silindiniz.',
        ['7'] = 'Sanat aşağıda bulunabilir:',
        ['8'] = 'Lütfen bir arama sorgusu girin (iTunes de aramak istediğin sorguyu gir, örnek: "Aykut Kuşkaya-Kaldırımlar" Aykut Kuşkaya - Kaldırımlar parçası aranacak.).',
        ['9'] = 'Albüm Kapağını Getir'
    },
    ['kick'] = {
        ['1'] = 'Hangi kullanıcıyı gruptan atmak istersiniz? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Bu kullanıcıyı, bu sohbette bir moderatör veya yönetici olduğu için gruptan atamam.',
        ['3'] = 'Bu kullanıcıyı, bu sohbeden ayrıldığı için gruptan atamam.',
        ['4'] = 'Bu kullanıcıyı, bu sohbetten çoktan atıldıkları için gruptan atamam.',
        ['5'] = 'Bu kullanıcıyı gruptan atmak için admin izinlerine sahip olmam gerekiyor. Lütfen bu sorunu düzeltip tekrar deneyin.'
    },
    ['lastfm'] = {
        ['1'] = '%s\'s last.fm kullanıcı adı ayarlandı "%s".',
        ['2'] = 'last.fm kullanıcı adın unutuldu!',
        ['3'] = 'Şu anda bir last.fm kullanıcı adınız yok!',
        ['4'] = 'Lütfen last.fm kullanıcı adınızı belirtin veya /fmset ile ayarlayın.',
        ['5'] = 'Bu kullanıcı için geçmiş bulunamadı.',
        ['6'] = '%s Şu anda bunu dinliyorsun:\n',
        ['7'] = '%s en son dinlenilen:\n',
        ['8'] = 'Bilinmeyen',
        ['9'] = 'Sonuç göndermek için tıklayın.'
    },
    ['location'] = {
        ['1'] = 'Ayarlanmış konumunuz yok. Yeni konum ayarlamak ister misiniz?'
    },
    ['logchat'] = {
        ['1'] = 'Lütfen tüm idari işlemleri kaydetmek istediğiniz sohbetin kullanıcı adını veya sayısal kimliğini girin.',
        ['2'] = 'Bu sohbetin geçerli olup olmadığını kontrol et...',
        ['3'] = 'Maalesef geçersiz bir sohbet belirttiniz veya henüz eklenmediğim bir sohbet belirttiniz. Lütfen bunu düzeltin ve tekrar deneyin.',
        ['4'] = 'Bir kullanıcıyı günlük sohbetiniz olarak ayarlayamazsınız!',
        ['5'] = 'Sohbette bir yönetici gibi görünmüyorsun!',
        ['6'] = 'Görünen o ki sohbetime zaten idari işlemler yapıyorum! /logchat komutunu kullanarak bir tane oluştur.',
        ['7'] = 'Bu sohbet geçerlidir, şimdi göndermeye izinim olduğundan emin olmak için ona bir test mesajı göndermeye çalışacağım!',
        ['8'] = 'Merhaba, Dünya - bu,mesaj gönderme izinlerini kontrol etmek için bir test mesajıdır - Eğer bunu okursanız, her şey yolundadır.',
        ['9'] = 'Hepsi tamam! Şu andan itibaren, bu sohbetteki herhangi bir idari işlemler giriş yapabilir %s - Benim için yönetimsel işlemleri kaydetmek istediğim sohbeti değiştirmek için, /logchat komutunu kullanın.'
    },
    ['lua'] = {
        ['1'] = 'Lütfen yürütülecek bir Lua dizgesi girin!'
    },
    ['lyrics'] = {
        ['1'] = 'Spotify',
        ['2'] = 'Şarkı sözlerini göster',
        ['3'] = 'Lütfen bir arama sorgusu girin (aramak istediğin şarkı sözlerini belirt, örnek: "Ankaranın Bağları" Ankaranın bağları şarkı sözlerini getirecek.).'
    },
    ['minecraft'] = {
        ['1'] = '<b>%s kullanıcı adını değiştirdi %s time</b>',
        ['2'] = '<b>%s  kullanıcı adını %s kere değiştirdi </b>',
        ['3'] = 'Önceki',
        ['4'] = 'Sonraki',
        ['5'] = 'Geri',
        ['6'] = 'UUID',
        ['7'] = 'Resim',
        ['8'] = 'Kullanıcı adı geçmişi',
        ['9'] = 'Lütfen özellik seçiniz:',
        ['10'] = 'Lütfen Minecraft oyuncusunun kullanıcı adını giriniz. (örnek: "By_Azade" By_Azade hakkında bilgi verecel).',
        ['11'] = 'Minecraft usernames are between 3 and 16 characters long.'
    },
    ['mute'] = {
        ['1'] = 'Hangi kullanıcıyı susturmak istersiniz? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Bu sohbette zaten sessiz oldukları için bu kullanıcıyı susturamıyorum',
        ['3'] = 'Bu sohbette bir moderatör ya da yönetici oldukları için bu kullanıcıyı susturamıyorum.',
        ['4'] = 'Bu kullanıcıyı zaten bu sohbetten ayrılmış (veya oradan atılmış) bu yüzden susturamıyorum.',
        ['5'] = 'Bu kullanıcıyı susturmak için admin izinlerine sahip olmam gerekiyor. Lütfen bu sorunu düzeltip tekrar deneyin.'
    },
    ['myspotify'] = {
        ['1'] = 'Profil',
        ['2'] = 'Takip Edilenler',
        ['3'] = 'Önceden Oynatılanlar',
        ['4'] = 'Şu Anda Oynatılıyor',
        ['5'] = 'En İyi Parçalarınız',
        ['6'] = 'En İyi Sanatçılarınız',
        ['7'] = 'Herhangi bir sanatçıyı takip ediyor gibi görünmüyorsun!',
        ['8'] = 'En İyi Sanatçılarınız',
        ['9'] = 'Kütüphanenizde herhangi bir parçanın bulunmadığı anlaşılıyor!',
        ['10'] = 'En İyi Parçalarınız',
        ['11'] = 'Herhangi bir sanatçıyı takip ediyor gibi görünmüyorsun!',
        ['12'] = 'Takip Edilen Sanatçılar',
        ['13'] = 'Yakın zamanda herhangi bir parça çalmış görünmüyorsun!',
        ['14'] = '<b>Son Oynatılan</b>\n%s %s\n%s %s\n%s Dinlendi %s:%s on %s/%s/%s.',
        ['15'] = 'İstek işleme için kabul edildi, ancak işlem tamamlanmadı.',
        ['16'] = 'Şu an bir şey dinliyor görünmüyorsun!',
        ['17'] = 'Şu Anda Oynatılıyor',
        ['18'] = 'Spotify hesabınızı yeniden yetkilendirirken bir hata oluştu.!',
        ['19'] = 'Spotify hesabınız başarılı bir şekilde yeniden yetkilendirildi! İsteğinizi işleme koyabilirsiniz....',
        ['20'] = 'Spotify hesabınızı yeniden yetkilendirilecek, lütfen bekleyin...',
        ['21'] = 'Spotify hesabınızı bağlamak için mattatayı yetkilendirmeniz gerekir. Tıklayın [buraya](https://accounts.spotify.com/en/authorize?client_id=%s&response_type=code&redirect_uri=%s&scope=user-library-read%%20playlist-read-private%%20playlist-read-collaborative%%20user-read-private%%20user-read-birthdate%%20user-read-email%%20user-follow-read%%20user-top-read%%20user-read-playback-state%%20user-read-recently-played%%20user-read-currently-playing%%20user-modify-playback-state) Mattatayı Spotify hesabınıza bağlamak için yeşil "Tamam" düğmesine basın. Bunu yaptıktan sonra, yönlendirilen bağlantıyı şu adrese gönderin: ("%s" ile başlamalı ve onu benzersiz bir kod takip etmelidir).',
        ['22'] = 'Çalma listeleri',
        ['23'] = 'Satıriçi Modu Kullan',
        ['24'] = 'Şarkı sözleri',
        ['25'] = 'Hiç aygıt bulunamadı.',
        ['26'] = 'Hiçbir çalma listenizin yokmuş gibi görünüyor.',
        ['27'] = 'Senin Oynatma Listen',
        ['28'] = '%s %s [%s parçalar]',
        ['29'] = '%s %s [%s]\nSpotify %s kullanıcı\n\n<b>aygıtları:</b>\n%s',
        ['30'] = 'Önceki parçayı çalınıyor...',
        ['31'] = 'Premium kullanıcı değilsiniz!',
        ['32'] = 'Herhangi bir cihaz bulamadım.',
        ['33'] = 'Bir sonraki parçayı çalınıyor...',
        ['34'] = 'Parça yeniden başlatılıyor...',
        ['35'] = 'Cihazınız geçici olarak kullanılamıyor...',
        ['36'] = 'Hiç aygıt bulunamadı!',
        ['37'] = 'Parçayı durduruyor...',
        ['38'] = 'Şimdi oynuyor',
        ['39'] = 'Shuffling your music...',
        ['40'] = 'Bu geçerli bir ses değil. Lütfen 0 ile 100 arasında bir sayı belirtin.',
        ['41'] = 'Ses seviyesi ayarlandı %s%%!',
        ['42'] = 'Bu ileti bu eklentinin eski bir sürümünü kullanıyor, lütfen /myspotify komutunu kullanarak yeni bir tane isteyin.!'
    },
    ['name'] = {
        ['1'] = 'Şu anda yanıtladığım isim "%s" - bunu değiştirmek için, /name <yazı> komutunu kullanın (Buradaki <yazı> bemin cevap vermemi istediğiniz şeydir).',
        ['2'] = 'Yeni adım 2 ila 32 karakter uzunluğunda olmalıdır!',
        ['3'] = 'İsmim yalnızca alfasayısal karakterler içerebilir!',
        ['4'] = 'Şimdi "% s" yerine "% s" ye yanıt vereceğim - bunu değiştirmek için, /name <yazı> komutunu kullanın (Buradaki <yazı> benim cevap vermemi istediğiniz şeydir).'
    },
    ['netflix'] = {
        ['1'] = 'Daha Fazla Bilgi Edinin'
    },
    ['news'] = {
        ['1'] = '"<code>%s</code>" Geçerli bir Lua kalıbı değil.',
        ['2'] = 'Bir kaynak listesi alınamadı..',
        ['3'] = '<b>Eşleşen haber kaynakları bulundu</b> "<code>%s</code>":\n\n%s',
        ['4'] = '<b>Aşağıdakilerle birlikte kullanabileceğiniz mevcut haber kaynakları</b> /news komutunu kullanarak./nsources komutunu <b>kullanın.</b> &lt;kaynak&gt; <b>daha spesifik bir sonuç kümesi için haber kaynakları listesinde arama yapmalısın. Aramalar Lua kalıpları kullanılarak eşleştirilir</b>\n\n%s',
        ['5'] = 'Tercih ettiğiniz bir haber kaynağınız yok. /setnews <kaynak> komutunu kullanarak bir tane ayarla. Kaynakların listesini görmek için /nsources komutunu kullan, veya kaynakları daraltmak için /nsources <kaynak> komutunu kullanabilirsin.',
        ['6'] = 'Tercih ettiğiniz mevcut haber kaynağı %s. /setnews <kaynak> komutunu kullanarak değiştirebilirsin. /nsources komutunu kullanarak kaynakları görüntüleyebilirsin, veya kaynakları daraltmak için /nsources <kaynak> komutunu kullanabilirsin.',
        ['7'] = 'Tercih ettiğiniz kaynak zaten %s! Geçerli hikayeyi görüntülemek için /news komutunu kullanın.',
        ['8'] = 'Bu geçerli bir haber kaynağı değil./nsources komutunu kullanarak bir kaynak listesi görüntüle, veya sonuçları daraltmak için /nsources <sorgu> komutunu kullan.',
        ['9'] = 'Tercih ettiğiniz haber kaynağı güncellendi %s! Geçerli hikayeyi görüntülemek için /news komutunu kullanın.',
        ['10'] = 'Bu geçerli bir kaynak değil, /nsources komutunu kullanarak aktif kaynakları görüntüleyin.Tercih ettiğiniz bir kaynağınız varsa,  /setnews <kaynak>  /news komutunu kullanarak gönderdiğinizde o kaynaktan gönderilen haberler otomatik olarak alınır, Herhangi bir argüman gerekmeden.',
        ['11'] = 'Daha Fazla Bilgi Edinin'
    },
    ['nick'] = {
        ['1'] = 'Takma adınız şimdi unutuldu!',
        ['2'] = 'Takma adınız "%s"!'
    },
    ['optout'] = {
        ['1'] = 'Toplanan verileri göndermeyi için seçtiniz! /optout komutunu kullanın.',
        ['2'] = 'Toplanan verileri göndermekten vazgeçtiniz! Etkinleştirmek için /optin komutunu kullanın.'
    },
    ['paste'] = {
        ['1'] = 'Lütfen yapıştırma dosyanızı yüklemek için bir hizmet seçin:'
    },
    ['pin'] = {
        ['1'] = 'Daha önce bir mesaj sabitlemediniz. /pin <yazı> komutunu kullanarak bir tane oluşturun.Yazı tipi türlerini destekler.',
        ['2'] = 'İşte son mesajı kullanarak üretilen /pin.',
        ['3'] = 'Veritabanında varolan bir pin buldum, Ancak gönderdiğim mesaj silindi gibi görünüyor, ve artık onu bulamıyorum. /pin <yazı> komutunu kullanrak yeni bir tane oluşturabilirsin. Yazı tipi türlerini destekler.',
        ['4'] = 'Mesajı sabitlerken bir hata oluştu. Girdiğiniz metnin geçersiz yazı tipi türü içerdiği için sabitlenen mesaj silindi. Şimdi, size aşağıda bulabileceğiniz yeni bir pin göndermeye çalışacağım - Onu değiştirmeniz gerekiyorsa, mesaj hala mevcut olduğundan emin olduktan sonra, /pin <yazı> komutunu kullanın.',
        ['5'] = 'Geçersiz yazı tipi formatı içerdiğinden bu metni gönderemedim.',
        ['6'] = 'Sabitlenen mesajı görüntüle, güncellenen mesajı görüntülemek için tıklayın.'
    },
    ['pokedex'] = {
        ['1'] = 'İsim: %s\nKimlik: %s\nTip: %s\nAçıklama: %s'
    },
    ['promote'] = {
        ['1'] = 'Admini veya moderatörü yetkilendiremezsin.',
        ['2'] = 'Bu kullanıcıyı yetkilendiremiyorum çünkü bu sohbetten ayrılmış durumda.',
        ['3'] = 'Bu kullanıcıyı yetkilendiremiyorum çünkü bu sohbetten çoktan atılmış durumda.'
    },
    ['quote'] = {
        ['1'] = 'Bu kullanıcı, veri saklama işlevini devre dışı bıraktı.',
        ['2'] = 'Bunun için kayıtlı söz yok! Onların gönderdikleri bir mesajı /save komutunu kullanarak kaydedebilirsiniz.'
    },
    ['report'] = {
        ['1'] = 'Lütfen grubun yöneticilerine bildirmek istediğiniz iletiyi yanıtlayın.',
        ['2'] = 'Kendi mesajlarınızı bildiremezsiniz, sadece komik olmaya mı çalışıyorsunuz?',
        ['3'] = '<b>%s nun %s! içinde yardıma ihtiyacı var! </b>',
        ['4'] = 'Bildirilen mesajı görüntülemek için burayı tıklayın.',
        ['5'] = 'Bu mesajı  %s admin(ler) e başarıyla rapor ettim.!'
    },
    ['save'] = {
        ['1'] = 'Bu kullanıcı, veri saklama işlevini devre dışı bıraktı.',
        ['2'] = 'Bu mesaj benim veritabanıma kaydedildi ve /quote cevabında kullanıldığında olası yanıtların listesine eklendi. %s%s!'
    },
    ['sed'] = {
        ['1'] = '%s\n\n<i>%s Bunu söylemek istememiştim!</i>',
        ['2'] = '%s\n\n<i>%s Yenilgiyi kabul etti.</i>',
        ['3'] = '%s\n\n<i>%s Yanılıyor mu bilmiyorlar mı ...</i>',
        ['4'] = 'Kahretsin, <i>Ne zamandır yanılıyorum?</i>',
        ['5'] = '"<code>%s</code>" Geçerli bir Lua kalıbı değil.',
        ['6'] = '<b>Merhaba, %s, bunu mu demek istedin:</b>\n<i>%s</i>',
        ['7'] = 'Evet',
        ['8'] = 'Hayır',
        ['9'] = 'Emin değilim'
    },
    ['setgrouplang'] = {
        ['1'] = 'Bu grubun dili şu şekilde ayarlandı: %s!',
        ['2'] = 'Bu grubun dili şu anda %s.\nLütfen bazı dizelerin henüz tercüme edilmediğine dikkat ediniz. Dilinizi değiştirmek isterseniz, aşağıdaki klavyeyi kullanarak birini seçin:',
        ['3'] = 'Kullanıcıları bu grupta aynı dili kullanmaya zorlama seçeneği şu anda devre dışı. Bu ayar /administrator den değiştirilmelidir, ancak işleri sizin için daha kolay hale getirmek için aşağıda bir düğme ekledim.',
        ['4'] = 'Etkin',
        ['5'] = 'Devre dışı'
    },
    ['setlang'] = {
        ['1'] = 'Diliniz ayarlandı %s!',
        ['2'] = 'Diliniz şuanda %s.\nLütfen bazı dizelerin henüz tercüme edilmediğine dikkat ediniz. Dilinizi değiştirmek isterseniz, aşağıdaki klavyeyi kullanarak birini seçin:'
    },
    ['setlink'] = {
        ['1'] = 'Doğru bir URL değil.',
        ['2'] = 'Link başarılı bir şekilde ayarlandı!'
    },
    ['setrules'] = {
        ['1'] = 'Bilinmeyen yazı tipi formatı.',
        ['2'] = 'Yeni kural başarılı bir şekilde kaydedildi!'
    },
    ['setwelcome'] = {
        ['1'] = 'Hoşgeldiniz mesajında ne yapmak istersiniz? Belirttiğiniz metin Markdown formatında olacak ve bir kullanıcı sohbete her katıldığında gönderilecektir (Hoş Geldiniz mesajı yönetim menüsünde devre dışı bırakılabilir,  /administration üzerinden erişilebilir). Her kullanıcı için hoş geldiniz mesajını otomatik olarak özelleştirmek için yer tutucularını kullanabilirsiniz. Kullanıcının sayısal kimliğini eklemek için $user_id kullanın,sohbetin sayısal kimliğini eklemek için $chat_id, kullanıcının adını eklemek için $name, grubun ismini eklemek için $title ve kullanıcının kullanıcı adını eklemek için $username (eğer kullanıcının kullanıcı adı (@kullanıcıadı) yoksa, bunun yerine isimleri kullanılacak, bu yüzden $name ile birlikte kullanılmamalıdır.).',
        ['2'] = 'Mesajınızı biçimlendirirken bir hata oluştu, lütfen yazı türünü kontrol edin ve tekrar deneyin.',
        ['3'] = 'Hoş geldin mesajı %s başarılı bir şekilde güncellendi!'
    },
    ['share'] = {
        ['1'] = 'Paylaş'
    },
    ['shorten'] = {
        ['1'] = 'Lütfen aşağıdaki butonları kullanarak bir URL kısaltıcı seçin:'
    },
    ['shsh'] = {
        ['1'] = 'ECID için herhangi bir SHSH blobunu getiremedim, Lütfen geçerli olduğundan ve bunları kullanarak kaydettiğinizden emin olun https://tsssaver.1conan.com.',
        ['2'] = 'SHSH Bu cihazın blobları, iOSun aşağıdaki sürümleri için kullanılabilir:\n',
        ['3'] = 'İndir .zip'
    },
    ['statistics'] = {
        ['1'] = 'Bu sohbette hiç mesaj gönderilmedi!',
        ['2'] = '<b>Statistics for:</b> %s\n\n%s\n<b>Total messages sent:</b> %s',
        ['3'] = 'Bu sohbet istatistikleri sıfırlandı!',
        ['4'] = 'Bu sohbetin istatistiklerini sıfırlayamadım. Belki daha önce resetlendi?'
    },
    ['steam'] = {
        ['1'] = 'Steam kullanıcı adın ayarlandı "%s".',
        ['2'] = '"%s" Steam kullanıcı adı değil.',
        ['3'] = '%s Steam kullanıcısı %s, açık %s. En son kapattılanlar %s, açık %s. Tıkla <a href="%s">here</a> Steam profilini görüntüle.',
        ['4'] = '%s, AKA "%s",'
    },
    ['trust'] = {
        ['1'] = 'Admini ve moderatörü güvenli olarak işaretleyemem.',
        ['2'] = 'Bu kullanıcıyı güvenli olarak işaretleyemem,kullanıcı gruptan ayrılmış.',
        ['3'] = 'Bu kullanıcıyı güvenli olarak işaretleyemem, kullanıcı gruptan atılmış'
    },
    ['unmute'] = {
        ['1'] = 'Hangi kullanıcının sesini açmak istiyorsun? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Bu kullanıcının sesini açamam, kullanıcının sesi kapanmamış.',
        ['3'] = 'Adminin veya moderatörün sesini kapatamam.',
        ['4'] = 'Bu kullanıcının sesini açamam, kullanıcı gruptan ayrılmış.'
    },
    ['untrust'] = {
        ['1'] = 'Hangi kullanıcıyı güvenilmeyen yapmak istiyorsun ? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Admin ve moderatörü güvenilmeyenler olarak ekleyemem.',
        ['3'] = 'Bu kullanıcıyı güvenilmeyenler listesine ekleyemem, kullanıcı gruptan ayrılmış.',
        ['4'] = 'Bu kullanıcıyı güvenilmeyenler listesine ekleyemem, kullanıcı gruptan atılmış.'
    },
    ['upload'] = {
        ['1'] = 'Please reply to the file you\'d like to download to the server. It must be <= 20 MB.',
        ['2'] = 'Dosya çok büyük boyutta. 20MBdan küçük olmalı <= 20 MB.',
        ['3'] = 'Bu dosyayı alamıyorum, muhtemelen çok eski.',
        ['4'] = 'Bu dosyayı alınırken bir hata meydana geldi.',
        ['5'] = 'Dosyayı sunucudan başarılı bir şekilde indirdiniz - bulunabilir <code>%s</code>!'
    },
    ['voteban'] = {
        ['1'] = 'Hangi kullanıcı için oyla-banla özelliği kullanmak istiyorsun? Bu kullanıcıyı @kulanıcıadı şeklinde veya kullanıcı IDsi ile belirtebilirsin.',
        ['2'] = 'Admin için oyla-banla özelliği kullanılmaz',
        ['3'] = 'Oyla-banla özelliğini kullanamıyorum, kullanıcı gruptan ayılmış veya banlanmış.',
        ['4'] = '[%s] Buradan banlanması gerekir mi %s? %s hemen yasaklanması için oylama gerekir, ve %s bunun için en az oylama kapalı olmalıdır',
        ['5'] = 'Evet [%s]',
        ['6'] = 'Hayır [%s]',
        ['7'] = '[%s] Buradan %s %s banlandı %s çünkü %s insanlar bunun için oy kullandılar.',
        ['8'] = 'En yüksek oy miktarına ulaşıldı, ancak, banlayamam %s - belki onlar oylama yapılmadan önce gruptan ayrılmışlardır? Bu eylemi gerçekleştirmek için yetkiniz yok',
        ['9'] = 'Onları %s [%s] banlayamam %s çünkü %s insanlar banlamak için karar vermemişler.',
        ['10'] = 'Banlamak için oy kullandın %s [%s]!',
        ['11'] = 'Oyun geri çekildi, butonu kullanarak tekrar oy kullanabilirsin.',
        ['12'] = 'Banlama kararı alındı %s [%s]!',
        ['13'] = 'A vote-ban has already been opened for this user!'
    },
    ['weather'] = {
        ['1'] = 'Konum ayarlamadın. /setloc <konum> komutunu kullanarak bir tane ayarla.',
        ['2'] = 'Şu anda %s (hissedilen sıcaklık  %s)  %s. %s'
    },
    ['welcome'] = {
        ['1'] = 'Grup Kuralları'
    },
    ['whitelist'] = {
        ['1'] = 'Hangi kullanıcıyı beyaz listeye almak istiyorsun? Bir kullanıcıyı özel olarak @kullanıcıadı şeklinde veya kullanıcı kimliği ile belirtebilirsin.',
        ['2'] = 'Admini veya moderatörü beyaz listeye alamam.',
        ['3'] = 'Bu kullanıcıyı beyaz listeye alamam, kullanıcı sohbetten ayrılmış.',
        ['4'] = 'Bu kullanıcıyı beyaz listeye alamam kullanıcı sohbetten banlanmış'
    },
    ['wikipedia'] = {
        ['1'] = 'Daha fazla bilgi edinin.'
    },
    ['youtube'] = {
        ['1'] = 'Önceki',
        ['2'] = 'Sonraki',
        ['3'] = '%s sayfanın %s sayfasındasın!'
    }
}
