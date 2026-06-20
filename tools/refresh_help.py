#!/usr/bin/env python3
# Refresh the in-game help strings across all 26 translation files.
# Fixes the stale UI description (sidebar -> springboard home screen),
# the wrong Workshop distance (25 -> 35 m) and the bogus console command.
# Key names are unchanged, so modDesc.xml helpLines need no edit.
import re, sys
from pathlib import Path

TRANS = Path(__file__).resolve().parent.parent / "translations"

# Keys that get a full, translated rewrite. "&" must be written as &amp;.
KEYS = ["ft_help_p1_nav_title", "ft_help_p1_nav_text",
        "ft_help_m1_income_text", "ft_help_s1_settings_text",
        "ft_help_s2_console_text"]

# Mechanical fix: in this key's existing (already-translated) value, the
# Workshop range digits "25" become "35". Language independent.
DISTANCE_KEY = "ft_help_a3_workshop_text"

L = {}

L["en"] = {
 "ft_help_p1_nav_title": "Home Screen &amp; Apps",
 "ft_help_p1_nav_text": "Farm Tablet works like a phone. Slide to unlock, then tap an app icon on the home screen to open it. Tap HOME in the top bar to go back to the grid. The dock along the bottom holds your favourites, and the mouse wheel moves between pages. The App Store app lists every app you have.",
 "ft_help_m1_income_text": "When FS25_IncomeMod is active, the Income app appears on the home screen. It shows the payment mode and amount, and lets you enable or disable the mod without leaving the tablet. Changes take effect immediately.",
 "ft_help_s1_settings_text": "Open the Settings app to manage the tablet: position and scale (or Edit Mode), background colour, your own home image, the lock screen, the startup app, sounds, and notifications. Everything saves automatically.",
 "ft_help_s2_console_text": "Open the developer console with the tilde key and type tablet to list every command. For example TabletKeybind H changes the open key, TabletSetStartupApp weather sets the first app, and TabletResetSettings restores defaults.",
}

L["de"] = {
 "ft_help_p1_nav_title": "Startbildschirm &amp; Apps",
 "ft_help_p1_nav_text": "Das Farm-Tablet funktioniert wie ein Smartphone. Zum Entsperren wischen, danach auf dem Startbildschirm ein App-Symbol antippen, um es zu oeffnen. Tippe oben auf HOME, um zum Raster zurueckzukehren. Das Dock am unteren Rand enthaelt deine Favoriten, mit dem Mausrad wechselst du die Seiten. Die App-Store-App zeigt alle vorhandenen Apps.",
 "ft_help_m1_income_text": "Wenn FS25_IncomeMod aktiv ist, erscheint die Einkommen-App auf dem Startbildschirm. Sie zeigt Zahlungsmodus und Betrag und erlaubt das Ein- oder Ausschalten des Mods, ohne das Tablet zu verlassen. Aenderungen wirken sofort.",
 "ft_help_s1_settings_text": "Oeffne die Einstellungen-App, um das Tablet zu verwalten: Position und Groesse (oder Bearbeitungsmodus), Hintergrundfarbe, eigenes Startbild, den Sperrbildschirm, die Start-App, Toene und Benachrichtigungen. Alles wird automatisch gespeichert.",
 "ft_help_s2_console_text": "Oeffne die Entwicklerkonsole mit der Tilde-Taste und tippe tablet, um alle Befehle zu sehen. Beispiel: TabletKeybind H aendert die Oeffnen-Taste, TabletSetStartupApp weather setzt die Start-App, und TabletResetSettings stellt die Standardwerte wieder her.",
}

L["fr"] = {
 "ft_help_p1_nav_title": "Ecran d'accueil &amp; applis",
 "ft_help_p1_nav_text": "La Tablette de Ferme fonctionne comme un telephone. Glissez pour deverrouiller, puis touchez une icone sur l'ecran d'accueil pour ouvrir une appli. Touchez HOME dans la barre du haut pour revenir a la grille. Le dock en bas regroupe vos favoris, et la molette change de page. L'appli App Store liste toutes vos applis.",
 "ft_help_m1_income_text": "Quand FS25_IncomeMod est actif, l'appli Revenus apparait sur l'ecran d'accueil. Elle affiche le mode et le montant de paiement, et permet d'activer ou desactiver le mod sans quitter la tablette. Les changements sont immediats.",
 "ft_help_s1_settings_text": "Ouvrez l'appli Reglages pour gerer la tablette : position et taille (ou Mode Edition), couleur de fond, votre propre image d'accueil, l'ecran de verrouillage, l'appli de demarrage, les sons et les notifications. Tout est enregistre automatiquement.",
 "ft_help_s2_console_text": "Ouvrez la console developpeur avec la touche tilde et tapez tablet pour lister toutes les commandes. Par exemple TabletKeybind H change la touche d'ouverture, TabletSetStartupApp weather definit la premiere appli, et TabletResetSettings restaure les valeurs par defaut.",
}

L["nl"] = {
 "ft_help_p1_nav_title": "Startscherm &amp; apps",
 "ft_help_p1_nav_text": "De Farm Tablet werkt als een telefoon. Veeg om te ontgrendelen, tik dan op een app-icoon op het startscherm om het te openen. Tik op HOME in de bovenbalk om terug te keren naar het raster. Het dock onderaan bevat je favorieten, en met het muiswiel wissel je van pagina. De App Store-app toont al je apps.",
 "ft_help_m1_income_text": "Wanneer FS25_IncomeMod actief is, verschijnt de Inkomen-app op het startscherm. Hij toont de betaalmodus en het bedrag, en je kunt de mod aan- of uitzetten zonder de tablet te verlaten. Wijzigingen werken direct.",
 "ft_help_s1_settings_text": "Open de Instellingen-app om de tablet te beheren: positie en schaal (of Bewerkmodus), achtergrondkleur, je eigen startafbeelding, het vergrendelscherm, de start-app, geluiden en meldingen. Alles wordt automatisch opgeslagen.",
 "ft_help_s2_console_text": "Open de ontwikkelaarsconsole met de tilde-toets en typ tablet om alle commando's te zien. Bijvoorbeeld TabletKeybind H wijzigt de openingstoets, TabletSetStartupApp weather stelt de eerste app in, en TabletResetSettings herstelt de standaardwaarden.",
}

L["it"] = {
 "ft_help_p1_nav_title": "Schermata Home &amp; app",
 "ft_help_p1_nav_text": "Il Tablet Agricolo funziona come un telefono. Scorri per sbloccare, poi tocca l'icona di un'app nella schermata Home per aprirla. Tocca HOME nella barra in alto per tornare alla griglia. Il dock in basso contiene i preferiti e la rotellina del mouse cambia pagina. L'app App Store elenca tutte le tue app.",
 "ft_help_m1_income_text": "Quando FS25_IncomeMod e attivo, l'app Reddito appare nella schermata Home. Mostra la modalita e l'importo del pagamento e permette di attivare o disattivare la mod senza lasciare il tablet. Le modifiche sono immediate.",
 "ft_help_s1_settings_text": "Apri l'app Impostazioni per gestire il tablet: posizione e scala (o Modalita Modifica), colore di sfondo, la tua immagine Home, la schermata di blocco, l'app iniziale, suoni e notifiche. Tutto viene salvato automaticamente.",
 "ft_help_s2_console_text": "Apri la console sviluppatore con il tasto tilde e digita tablet per elencare tutti i comandi. Ad esempio TabletKeybind H cambia il tasto di apertura, TabletSetStartupApp weather imposta la prima app e TabletResetSettings ripristina i valori predefiniti.",
}

L["es"] = {
 "ft_help_p1_nav_title": "Pantalla de inicio &amp; apps",
 "ft_help_p1_nav_text": "La Tablet Agricola funciona como un telefono. Desliza para desbloquear y luego toca el icono de una app en la pantalla de inicio para abrirla. Toca HOME en la barra superior para volver a la cuadricula. El dock inferior contiene tus favoritas y la rueda del raton cambia de pagina. La app App Store muestra todas tus apps.",
 "ft_help_m1_income_text": "Cuando FS25_IncomeMod esta activo, la app Ingresos aparece en la pantalla de inicio. Muestra el modo y el importe del pago y permite activar o desactivar el mod sin salir de la tablet. Los cambios son inmediatos.",
 "ft_help_s1_settings_text": "Abre la app Ajustes para gestionar la tablet: posicion y escala (o Modo Edicion), color de fondo, tu propia imagen de inicio, la pantalla de bloqueo, la app inicial, sonidos y notificaciones. Todo se guarda automaticamente.",
 "ft_help_s2_console_text": "Abre la consola de desarrollador con la tecla tilde y escribe tablet para ver todos los comandos. Por ejemplo TabletKeybind H cambia la tecla de apertura, TabletSetStartupApp weather fija la primera app y TabletResetSettings restaura los valores por defecto.",
}

L["ea"] = dict(L["es"])  # Latin American Spanish: same base text

L["pt"] = {
 "ft_help_p1_nav_title": "Ecra principal &amp; apps",
 "ft_help_p1_nav_text": "O Tablet Agricola funciona como um telemovel. Deslize para desbloquear e toque no icone de uma app no ecra principal para a abrir. Toque em HOME na barra superior para voltar a grelha. A dock em baixo guarda os favoritos e a roda do rato muda de pagina. A app App Store lista todas as suas apps.",
 "ft_help_m1_income_text": "Quando o FS25_IncomeMod esta ativo, a app Rendimento aparece no ecra principal. Mostra o modo e o valor do pagamento e permite ativar ou desativar o mod sem sair do tablet. As alteracoes sao imediatas.",
 "ft_help_s1_settings_text": "Abra a app Definicoes para gerir o tablet: posicao e escala (ou Modo de Edicao), cor de fundo, a sua propria imagem principal, o ecra de bloqueio, a app inicial, sons e notificacoes. Tudo e guardado automaticamente.",
 "ft_help_s2_console_text": "Abra a consola de programador com a tecla til e escreva tablet para listar todos os comandos. Por exemplo TabletKeybind H muda a tecla de abertura, TabletSetStartupApp weather define a primeira app e TabletResetSettings repoe os valores predefinidos.",
}

L["br"] = {
 "ft_help_p1_nav_title": "Tela inicial &amp; apps",
 "ft_help_p1_nav_text": "O Tablet Agricola funciona como um celular. Deslize para desbloquear e toque no icone de um app na tela inicial para abri-lo. Toque em HOME na barra superior para voltar a grade. A dock embaixo guarda seus favoritos e a roda do mouse muda de pagina. O app App Store lista todos os seus apps.",
 "ft_help_m1_income_text": "Quando o FS25_IncomeMod esta ativo, o app Renda aparece na tela inicial. Ele mostra o modo e o valor do pagamento e permite ativar ou desativar o mod sem sair do tablet. As alteracoes sao imediatas.",
 "ft_help_s1_settings_text": "Abra o app Configuracoes para gerenciar o tablet: posicao e escala (ou Modo de Edicao), cor de fundo, sua propria imagem inicial, a tela de bloqueio, o app inicial, sons e notificacoes. Tudo e salvo automaticamente.",
 "ft_help_s2_console_text": "Abra o console do desenvolvedor com a tecla til e digite tablet para listar todos os comandos. Por exemplo TabletKeybind H muda a tecla de abertura, TabletSetStartupApp weather define o primeiro app e TabletResetSettings restaura os padroes.",
}

L["pl"] = {
 "ft_help_p1_nav_title": "Ekran glowny &amp; aplikacje",
 "ft_help_p1_nav_text": "Tablet Farmowy dziala jak telefon. Przesun, aby odblokowac, a nastepnie dotknij ikony aplikacji na ekranie glownym, aby ja otworzyc. Dotknij HOME na gornym pasku, aby wrocic do siatki. Dok na dole zawiera ulubione, a kolko myszy zmienia strony. Aplikacja App Store pokazuje wszystkie twoje aplikacje.",
 "ft_help_m1_income_text": "Gdy FS25_IncomeMod jest aktywny, aplikacja Dochod pojawia sie na ekranie glownym. Pokazuje tryb i kwote platnosci oraz pozwala wlaczyc lub wylaczyc moda bez opuszczania tabletu. Zmiany dzialaja natychmiast.",
 "ft_help_s1_settings_text": "Otworz aplikacje Ustawienia, aby zarzadzac tabletem: pozycja i skala (lub Tryb Edycji), kolor tla, wlasny obraz ekranu glownego, ekran blokady, aplikacja startowa, dzwieki i powiadomienia. Wszystko jest zapisywane automatycznie.",
 "ft_help_s2_console_text": "Otworz konsole deweloperska klawiszem tyldy i wpisz tablet, aby wyswietlic wszystkie komendy. Na przyklad TabletKeybind H zmienia klawisz otwierania, TabletSetStartupApp weather ustawia pierwsza aplikacje, a TabletResetSettings przywraca domyslne ustawienia.",
}

L["cz"] = {
 "ft_help_p1_nav_title": "Domovska obrazovka &amp; aplikace",
 "ft_help_p1_nav_text": "Farmarsky Tablet funguje jako telefon. Posunutim odemknete, pak klepnete na ikonu aplikace na domovske obrazovce a otevrete ji. Klepnutim na HOME v hornim panelu se vratite na mrizku. Dok dole obsahuje oblibene a kolecko mysi prepina stranky. Aplikace App Store zobrazuje vsechny vase aplikace.",
 "ft_help_m1_income_text": "Kdyz je FS25_IncomeMod aktivni, aplikace Prijem se objevi na domovske obrazovce. Zobrazuje rezim a castku platby a umoznuje mod zapnout nebo vypnout bez opusteni tabletu. Zmeny plati okamzite.",
 "ft_help_s1_settings_text": "Otevrete aplikaci Nastaveni pro spravu tabletu: poloha a velikost (nebo Rezim upravy), barva pozadi, vlastni domovsky obrazek, zamykaci obrazovka, uvodni aplikace, zvuky a oznameni. Vse se uklada automaticky.",
 "ft_help_s2_console_text": "Otevrete vyvojarskou konzoli klavesou tilda a napiste tablet pro vypis vsech prikazu. Napriklad TabletKeybind H meni klavesu otevreni, TabletSetStartupApp weather nastavi prvni aplikaci a TabletResetSettings obnovi vychozi nastaveni.",
}

L["hu"] = {
 "ft_help_p1_nav_title": "Kezdokepernyo &amp; alkalmazasok",
 "ft_help_p1_nav_text": "A Farm Tablet ugy mukodik, mint egy telefon. Huzd el a feloldashoz, majd erintsd meg egy alkalmazas ikonjat a kezdokepernyon a megnyitashoz. Erintsd meg a HOME gombot a felso savon a racshoz valo visszateteshez. Az also dokk a kedvenceket tartalmazza, az egergorgo pedig lapoz. Az App Store alkalmazas felsorolja az osszes alkalmazasodat.",
 "ft_help_m1_income_text": "Ha a FS25_IncomeMod aktiv, a Jovedelem alkalmazas megjelenik a kezdokepernyon. Mutatja a fizetesi modot es osszeget, es a tablet elhagyasa nelkul be- vagy kikapcsolhatod a modot. A valtozasok azonnal ervenyesek.",
 "ft_help_s1_settings_text": "Nyisd meg a Beallitasok alkalmazast a tablet kezelesehez: pozicio es meret (vagy Szerkesztes mod), hatterszin, sajat kezdokep, zarolasi kepernyo, indito alkalmazas, hangok es ertesitesek. Minden automatikusan mentodik.",
 "ft_help_s2_console_text": "Nyisd meg a fejlesztoi konzolt a tilde billentyuvel, es ird be a tablet szot az osszes parancs listazasahoz. Pelda: TabletKeybind H megvaltoztatja a nyito billentyut, TabletSetStartupApp weather beallitja az elso alkalmazast, a TabletResetSettings pedig visszaallitja az alapertelmezeseket.",
}

L["ro"] = {
 "ft_help_p1_nav_title": "Ecran principal &amp; aplicatii",
 "ft_help_p1_nav_text": "Farm Tablet functioneaza ca un telefon. Gliseaza pentru deblocare, apoi atinge o pictograma de aplicatie pe ecranul principal pentru a o deschide. Atinge HOME din bara de sus pentru a reveni la grila. Dock-ul de jos contine favoritele, iar rotita mouse-ului schimba paginile. Aplicatia App Store listeaza toate aplicatiile tale.",
 "ft_help_m1_income_text": "Cand FS25_IncomeMod este activ, aplicatia Venit apare pe ecranul principal. Afiseaza modul si suma platii si permite activarea sau dezactivarea modului fara a parasi tableta. Modificarile au efect imediat.",
 "ft_help_s1_settings_text": "Deschide aplicatia Setari pentru a gestiona tableta: pozitie si scala (sau Mod Editare), culoarea fundalului, propria imagine de pornire, ecranul de blocare, aplicatia de start, sunete si notificari. Totul se salveaza automat.",
 "ft_help_s2_console_text": "Deschide consola de dezvoltare cu tasta tilda si scrie tablet pentru a lista toate comenzile. De exemplu TabletKeybind H schimba tasta de deschidere, TabletSetStartupApp weather seteaza prima aplicatie, iar TabletResetSettings restaureaza valorile implicite.",
}

L["ru"] = {
 "ft_help_p1_nav_title": "Главный экран и приложения",
 "ft_help_p1_nav_text": "Фермерский планшет работает как телефон. Проведите, чтобы разблокировать, затем коснитесь значка приложения на главном экране, чтобы открыть его. Нажмите HOME на верхней панели, чтобы вернуться к сетке. Док внизу хранит избранное, а колесо мыши перелистывает страницы. Приложение App Store показывает все ваши приложения.",
 "ft_help_m1_income_text": "Когда FS25_IncomeMod активен, приложение Доход появляется на главном экране. Оно показывает режим и сумму выплаты и позволяет включать или выключать мод, не выходя из планшета. Изменения вступают в силу сразу.",
 "ft_help_s1_settings_text": "Откройте приложение Настройки для управления планшетом: положение и масштаб (или Режим редактирования), цвет фона, собственное фоновое изображение, экран блокировки, стартовое приложение, звуки и уведомления. Всё сохраняется автоматически.",
 "ft_help_s2_console_text": "Откройте консоль разработчика клавишей тильды и введите tablet, чтобы увидеть все команды. Например, TabletKeybind H меняет клавишу открытия, TabletSetStartupApp weather задаёт первое приложение, а TabletResetSettings восстанавливает значения по умолчанию.",
}

L["uk"] = {
 "ft_help_p1_nav_title": "Головний екран і застосунки",
 "ft_help_p1_nav_text": "Фермерський планшет працює як телефон. Проведіть, щоб розблокувати, потім торкніться значка застосунку на головному екрані, щоб відкрити його. Натисніть HOME на верхній панелі, щоб повернутися до сітки. Док унизу містить улюблені, а коліщатко миші гортає сторінки. Застосунок App Store показує всі ваші застосунки.",
 "ft_help_m1_income_text": "Коли FS25_IncomeMod активний, застосунок Дохід зявляється на головному екрані. Він показує режим і суму виплати та дозволяє вмикати чи вимикати мод, не виходячи з планшета. Зміни діють одразу.",
 "ft_help_s1_settings_text": "Відкрийте застосунок Налаштування для керування планшетом: положення і масштаб (або Режим редагування), колір фону, власне зображення головного екрана, екран блокування, стартовий застосунок, звуки та сповіщення. Усе зберігається автоматично.",
 "ft_help_s2_console_text": "Відкрийте консоль розробника клавішею тильди та введіть tablet, щоб переглянути всі команди. Наприклад, TabletKeybind H змінює клавішу відкриття, TabletSetStartupApp weather задає перший застосунок, а TabletResetSettings відновлює типові значення.",
}

L["tr"] = {
 "ft_help_p1_nav_title": "Ana ekran &amp; uygulamalar",
 "ft_help_p1_nav_text": "Farm Tablet bir telefon gibi calisir. Kilidi acmak icin kaydirin, ardindan ana ekranda bir uygulama simgesine dokunarak acin. Izgaraya donmek icin ust cubuktaki HOME dugmesine dokunun. Alttaki dok favorilerinizi tutar, fare tekerleği sayfalar arasinda gecer. App Store uygulamasi tum uygulamalarinizi listeler.",
 "ft_help_m1_income_text": "FS25_IncomeMod etkin oldugunda Gelir uygulamasi ana ekranda gorunur. Odeme modunu ve tutarini gosterir ve tableti birakmadan modu acip kapatmaniza izin verir. Degisiklikler aninda etkili olur.",
 "ft_help_s1_settings_text": "Tableti yonetmek icin Ayarlar uygulamasini acin: konum ve olcek (veya Duzenleme Modu), arka plan rengi, kendi ana ekran goseliniz, kilit ekrani, baslangic uygulamasi, sesler ve bildirimler. Her sey otomatik olarak kaydedilir.",
 "ft_help_s2_console_text": "Gelistirici konsolunu tilde tusuyla acin ve tum komutlari listelemek icin tablet yazin. Ornegin TabletKeybind H acma tusunu degistirir, TabletSetStartupApp weather ilk uygulamayi ayarlar ve TabletResetSettings varsayilanlari geri yukler.",
}

L["fi"] = {
 "ft_help_p1_nav_title": "Aloitusnaytto &amp; sovellukset",
 "ft_help_p1_nav_text": "Farm Tablet toimii kuin puhelin. Avaa lukitus pyyhkaisemalla ja avaa sovellus napauttamalla sen kuvaketta aloitusnaytolla. Palaa ruudukkoon napauttamalla HOME ylapalkista. Alareunan telakka sisaltaa suosikit ja hiiren rulla vaihtaa sivuja. App Store -sovellus luettelee kaikki sovelluksesi.",
 "ft_help_m1_income_text": "Kun FS25_IncomeMod on kaytossa, Tulot-sovellus ilmestyy aloitusnaytolle. Se nayttaa maksutavan ja summan ja antaa ottaa modin kayttoon tai pois kayttosta poistumatta tabletista. Muutokset tulevat voimaan heti.",
 "ft_help_s1_settings_text": "Avaa Asetukset-sovellus hallitaksesi tablettia: sijainti ja koko (tai Muokkaustila), taustavari, oma aloituskuva, lukitusnaytto, aloitussovellus, aanet ja ilmoitukset. Kaikki tallennetaan automaattisesti.",
 "ft_help_s2_console_text": "Avaa kehittajakonsoli tilde-nappaimella ja kirjoita tablet nahdaksesi kaikki komennot. Esimerkiksi TabletKeybind H vaihtaa avausnappaimen, TabletSetStartupApp weather asettaa ensimmaisen sovelluksen ja TabletResetSettings palauttaa oletukset.",
}

L["sv"] = {
 "ft_help_p1_nav_title": "Startskarm &amp; appar",
 "ft_help_p1_nav_text": "Farm Tablet fungerar som en telefon. Svep for att lasa upp och tryck sedan pa en appikon pa startskarmen for att oppna den. Tryck pa HOME i den ovre listen for att ga tillbaka till rutnatet. Dockan langst ner innehaller dina favoriter och mushjulet byter sida. App Store-appen listar alla dina appar.",
 "ft_help_m1_income_text": "Nar FS25_IncomeMod ar aktiv visas Inkomst-appen pa startskarmen. Den visar betalningslage och belopp och later dig sla pa eller av modden utan att lamna surfplattan. Andringar gäller direkt.",
 "ft_help_s1_settings_text": "Oppna Installningar-appen for att hantera surfplattan: position och skala (eller Redigeringslage), bakgrundsfarg, din egen startbild, lasskarmen, startappen, ljud och aviseringar. Allt sparas automatiskt.",
 "ft_help_s2_console_text": "Oppna utvecklarkonsolen med tilde-tangenten och skriv tablet for att lista alla kommandon. Till exempel andrar TabletKeybind H oppningstangenten, TabletSetStartupApp weather satter forsta appen och TabletResetSettings aterstaller standardvarden.",
}

L["no"] = {
 "ft_help_p1_nav_title": "Startskjerm &amp; apper",
 "ft_help_p1_nav_text": "Farm Tablet fungerer som en telefon. Sveip for a lase opp, og trykk deretter pa et appikon pa startskjermen for a apne det. Trykk pa HOME i den ovre linjen for a ga tilbake til rutenettet. Dokken nederst inneholder favorittene dine, og musehjulet bytter side. App Store-appen viser alle appene dine.",
 "ft_help_m1_income_text": "Nar FS25_IncomeMod er aktiv, vises Inntekt-appen pa startskjermen. Den viser betalingsmodus og belop og lar deg sla modden av eller pa uten a forlate nettbrettet. Endringer trer i kraft umiddelbart.",
 "ft_help_s1_settings_text": "Apne Innstillinger-appen for a administrere nettbrettet: posisjon og skala (eller Redigeringsmodus), bakgrunnsfarge, ditt eget startbilde, laseskjermen, oppstartsappen, lyder og varsler. Alt lagres automatisk.",
 "ft_help_s2_console_text": "Apne utviklerkonsollen med tilde-tasten og skriv tablet for a liste alle kommandoer. For eksempel endrer TabletKeybind H apnetasten, TabletSetStartupApp weather setter forste app, og TabletResetSettings gjenoppretter standardverdiene.",
}

L["da"] = {
 "ft_help_p1_nav_title": "Startskaerm &amp; apps",
 "ft_help_p1_nav_text": "Farm Tablet fungerer som en telefon. Stryg for at lase op, og tryk derefter pa et app-ikon pa startskaermen for at abne det. Tryk pa HOME i den overste bjaelke for at ga tilbage til gitteret. Dokken nederst indeholder dine favoritter, og musehjulet skifter side. App Store-appen viser alle dine apps.",
 "ft_help_m1_income_text": "Nar FS25_IncomeMod er aktiv, vises Indkomst-appen pa startskaermen. Den viser betalingstilstand og belob og lader dig sla modden til eller fra uden at forlade tabletten. AEndringer traeder i kraft med det samme.",
 "ft_help_s1_settings_text": "Abn Indstillinger-appen for at administrere tabletten: position og skala (eller Redigeringstilstand), baggrundsfarve, dit eget startbillede, laseskaermen, startappen, lyde og notifikationer. Alt gemmes automatisk.",
 "ft_help_s2_console_text": "Abn udviklerkonsollen med tilde-tasten, og skriv tablet for at vise alle kommandoer. For eksempel aendrer TabletKeybind H abningstasten, TabletSetStartupApp weather saetter den forste app, og TabletResetSettings gendanner standardvaerdierne.",
}

L["id"] = {
 "ft_help_p1_nav_title": "Layar utama &amp; aplikasi",
 "ft_help_p1_nav_text": "Farm Tablet bekerja seperti ponsel. Geser untuk membuka kunci, lalu ketuk ikon aplikasi di layar utama untuk membukanya. Ketuk HOME di bilah atas untuk kembali ke kisi. Dok di bagian bawah menyimpan favorit Anda, dan roda mouse mengganti halaman. Aplikasi App Store menampilkan semua aplikasi Anda.",
 "ft_help_m1_income_text": "Ketika FS25_IncomeMod aktif, aplikasi Pendapatan muncul di layar utama. Aplikasi ini menampilkan mode dan jumlah pembayaran serta memungkinkan Anda mengaktifkan atau menonaktifkan mod tanpa meninggalkan tablet. Perubahan berlaku seketika.",
 "ft_help_s1_settings_text": "Buka aplikasi Pengaturan untuk mengelola tablet: posisi dan skala (atau Mode Edit), warna latar, gambar layar utama Anda sendiri, layar kunci, aplikasi awal, suara, dan notifikasi. Semua disimpan otomatis.",
 "ft_help_s2_console_text": "Buka konsol pengembang dengan tombol tilde dan ketik tablet untuk menampilkan semua perintah. Misalnya TabletKeybind H mengubah tombol pembuka, TabletSetStartupApp weather mengatur aplikasi pertama, dan TabletResetSettings memulihkan setelan bawaan.",
}

L["vi"] = {
 "ft_help_p1_nav_title": "Man hinh chinh &amp; ung dung",
 "ft_help_p1_nav_text": "Farm Tablet hoat dong nhu mot dien thoai. Vuot de mo khoa, sau do cham vao bieu tuong ung dung tren man hinh chinh de mo. Cham HOME tren thanh tren cung de quay lai luoi. Thanh dock o duoi cung chua cac muc yeu thich va con lan chuot de chuyen trang. Ung dung App Store liet ke tat ca ung dung cua ban.",
 "ft_help_m1_income_text": "Khi FS25_IncomeMod hoat dong, ung dung Thu Nhap xuat hien tren man hinh chinh. No hien thi che do va so tien thanh toan, va cho phep bat hoac tat mod ma khong roi khoi may tinh bang. Thay doi co hieu luc ngay lap tuc.",
 "ft_help_s1_settings_text": "Mo ung dung Cai Dat de quan ly may tinh bang: vi tri va ty le (hoac Che do Chinh sua), mau nen, hinh nen man hinh chinh cua rieng ban, man hinh khoa, ung dung khoi dong, am thanh va thong bao. Moi thu duoc luu tu dong.",
 "ft_help_s2_console_text": "Mo bang dieu khien nha phat trien bang phim dau ngã va go tablet de liet ke moi lenh. Vi du TabletKeybind H doi phim mo, TabletSetStartupApp weather dat ung dung dau tien, va TabletResetSettings khoi phuc mac dinh.",
}

L["jp"] = {
 "ft_help_p1_nav_title": "ホーム画面とアプリ",
 "ft_help_p1_nav_text": "Farm Tabletはスマートフォンのように動作します。スワイプしてロックを解除し、ホーム画面でアプリのアイコンをタップして開きます。上部バーのHOMEをタップするとグリッドに戻ります。下部のドックにはお気に入りが並び、マウスホイールでページを切り替えます。App Storeアプリにすべてのアプリが一覧表示されます。",
 "ft_help_m1_income_text": "FS25_IncomeModが有効な場合、収入アプリがホーム画面に表示されます。支払いモードと金額を表示し、タブレットを離れずにModのオンとオフを切り替えられます。変更はすぐに反映されます。",
 "ft_help_s1_settings_text": "設定アプリを開いてタブレットを管理します。位置とサイズ（または編集モード）、背景色、独自のホーム画像、ロック画面、起動アプリ、サウンド、通知。すべて自動的に保存されます。",
 "ft_help_s2_console_text": "チルダキーで開発者コンソールを開き、tablet と入力するとすべてのコマンドが表示されます。例えば TabletKeybind H は開くキーを変更し、TabletSetStartupApp weather は最初のアプリを設定し、TabletResetSettings は既定値に戻します。",
}

L["kr"] = {
 "ft_help_p1_nav_title": "홈 화면 및 앱",
 "ft_help_p1_nav_text": "Farm Tablet은 휴대폰처럼 작동합니다. 밀어서 잠금을 해제한 다음 홈 화면에서 앱 아이콘을 눌러 엽니다. 상단 바의 HOME을 누르면 그리드로 돌아갑니다. 하단의 독에는 즐겨찾기가 있고 마우스 휠로 페이지를 넘깁니다. App Store 앱에 모든 앱이 표시됩니다.",
 "ft_help_m1_income_text": "FS25_IncomeMod가 활성화되면 수입 앱이 홈 화면에 나타납니다. 지급 방식과 금액을 표시하며 태블릿을 벗어나지 않고 모드를 켜거나 끌 수 있습니다. 변경 사항은 즉시 적용됩니다.",
 "ft_help_s1_settings_text": "설정 앱을 열어 태블릿을 관리하세요. 위치와 크기(또는 편집 모드), 배경색, 나만의 홈 이미지, 잠금 화면, 시작 앱, 소리, 알림. 모든 것이 자동으로 저장됩니다.",
 "ft_help_s2_console_text": "물결표 키로 개발자 콘솔을 열고 tablet을 입력하면 모든 명령을 볼 수 있습니다. 예를 들어 TabletKeybind H는 여는 키를 바꾸고, TabletSetStartupApp weather는 첫 앱을 설정하며, TabletResetSettings는 기본값으로 되돌립니다.",
}

L["ct"] = {
 "ft_help_p1_nav_title": "主畫面與應用程式",
 "ft_help_p1_nav_text": "Farm Tablet 的操作就像手機。滑動以解鎖，然後在主畫面點按應用程式圖示即可開啟。點按上方列的 HOME 可返回圖示格。底部的 Dock 放置常用程式，滑鼠滾輪可切換頁面。App Store 應用程式會列出你所有的應用程式。",
 "ft_help_m1_income_text": "當 FS25_IncomeMod 啟用時，收入應用程式會出現在主畫面。它顯示付款模式與金額，並可讓你在不離開平板的情況下啟用或停用該模組。變更會立即生效。",
 "ft_help_s1_settings_text": "開啟設定應用程式來管理平板：位置與縮放（或編輯模式）、背景顏色、你自己的主畫面圖片、鎖定畫面、啟動應用程式、音效與通知。所有設定會自動儲存。",
 "ft_help_s2_console_text": "用波浪鍵開啟開發者主控台，輸入 tablet 即可列出所有指令。例如 TabletKeybind H 變更開啟鍵，TabletSetStartupApp weather 設定第一個應用程式，TabletResetSettings 還原預設值。",
}

L["fc"] = {
 "ft_help_p1_nav_title": "主屏幕与应用",
 "ft_help_p1_nav_text": "Farm Tablet 的操作就像手机。滑动以解锁，然后在主屏幕点按应用图标即可打开。点按顶部栏的 HOME 可返回图标网格。底部的 Dock 放置常用应用，鼠标滚轮可切换页面。App Store 应用会列出你的所有应用。",
 "ft_help_m1_income_text": "当 FS25_IncomeMod 启用时，收入应用会出现在主屏幕。它显示付款方式和金额，并可让你在不离开平板的情况下启用或禁用该模组。更改会立即生效。",
 "ft_help_s1_settings_text": "打开设置应用来管理平板：位置和缩放（或编辑模式）、背景颜色、你自己的主屏幕图片、锁屏、启动应用、音效和通知。所有设置会自动保存。",
 "ft_help_s2_console_text": "用波浪键打开开发者控制台，输入 tablet 即可列出所有命令。例如 TabletKeybind H 更改打开键，TabletSetStartupApp weather 设置第一个应用，TabletResetSettings 还原默认值。",
}


def apply_file(code, mapping):
    fp = TRANS / f"translation_{code}.xml"
    if not fp.exists():
        print(f"  SKIP (missing): {fp.name}")
        return 0
    text = fp.read_text(encoding="utf-8")
    changed = 0
    for key, val in mapping.items():
        pat = re.compile(r'(<text name="' + re.escape(key) + r'" text=")(.*?)("\s*/>)')
        new, n = pat.subn(lambda m: m.group(1) + val + m.group(3), text)
        if n == 0:
            print(f"  WARN: key not found in {code}: {key}")
        else:
            text = new
            changed += n
    # Mechanical distance fix: 25 -> 35 inside the Workshop help value only.
    dp = re.compile(r'(<text name="' + re.escape(DISTANCE_KEY) + r'" text=")(.*?)("\s*/>)')
    def fix_dist(m):
        return m.group(1) + m.group(2).replace("25", "35", 1) + m.group(3)
    text2, nd = dp.subn(fix_dist, text)
    if nd:
        text = text2
        changed += 1
    fp.write_text(text, encoding="utf-8")
    return changed

total = 0
for code, mapping in L.items():
    c = apply_file(code, mapping)
    total += c
    print(f"  {code}: {c} strings updated")
print(f"Done. {total} strings updated across {len(L)} languages.")
