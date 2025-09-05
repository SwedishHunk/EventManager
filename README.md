
<h1>EventManager Contract</h1>
<i>“Utveckla ett kontrakt för att hantera anmälningar till ett evenemang. Användare kan registrera sig genom att betala en avgift, och registreringen ska stängas när en viss gräns är nådd, eller att en deadline har passerat. Kontraktet ska innehålla funktioner för att registrera ett nytt evenemang, öppna och stänga registreringen, anmälan till evenemanget, hantering av betalning, samt en lista över alla registrerade deltagare per evenemang.”</i>
<br />
<p>Vi har utvecklat ett <b>smart kontrakt</b> som vi valt att kalla <b>"EventManager"</b>, eftersom det låter organisatörer skapa evenemang där deltagare kan registrera sig genom att betala en biljettavgift. Varje evenemang har en deadline när biljettförsäljningen stängs, och dessutom kan biljetterna sälja slut för evenemangen har ett maxantal biljetter.

<br /> Organisatören kan öppna eller stänga registrering, och när event är klart kan organisatören ta ut de insamlade medlen. Kontraktet håller koll på deltagare, betalningar och loggar händelser för transparens.

<br /> Med <b>custom modifiers</b> såg vi till att ägaren måste va msg.sender, och att bara organiseraren får leta upp events. </p>

<br />Några viktiga funktioner vi behövde var att kunna <b>skapa evenemang</b>(med <b>require</b> att alla viktiga fält fylls i), <b>registrera dig</b> för evenemang (kontrollera så användaren inte redan finns, så att den betalat, så att den blir registrerad, stäng funktion automatiskt när det är fullbokat/passerat deadline), <b>öppna registrering</b> (endast om det ej är fullbokat/passerat deadline), <b>stäng registrering</b> (endast om du är organisatör), <b>lista deltagare</b> (assert för att säkerställa att antalet deltagare stämmer), <b>ta ut pengar som tjänats</b> (endast om det är fullbokat/passerat deadline), <b>hämta eventinformation</b>, <b>kolla om användare är registrerad</b>.

<br />


🔸 closeRegistration(uint256 eventId)

Stänger registreringen för ett specifikt event (identifierat med eventId).

Bara organisatören av eventet får anropa.

Efter detta kan inga fler anmälningar göras.

🔸 createEvent(string name_, uint256 ticketPrice_, uint256 userLimit_, uint256 deadline_)

Skapar ett nytt event.

Parametrar:

name_: namn på eventet (textsträng).

ticketPrice_: biljettpris i wei (t.ex. 1000000000000000 för 0.001 ETH).

userLimit_: max antal deltagare.

deadline_: unix-tid (sekunder) då registreringen stänger automatiskt.

Returnerar ett eventId (0, 1, 2 …) för att identifiera eventet.

Organisatören (msg.sender) blir den som skapar.

🔸 openRegistration(uint256 eventId)

Öppnar registreringen för ett event.

Måste anropas efter createEvent för att deltagare ska kunna registrera sig.

Bara organisatören får öppna.

🔸 register(uint256 eventId) (payable)

Låter en användare registrera sig för ett event.

Kräver att man skickar exakt ticketPrice i Value-fältet i Remix.

Villkor:

Eventet måste vara öppet.

Deadline får inte ha passerat.

Antalet deltagare får inte ha nått userLimit.

Samma adress kan inte registrera sig två gånger.

Lägger till användaren i deltagarlistan.

🔸 withdraw(uint256 eventId)

Organisatören kan ta ut eventets intäkter.

Kan bara göras när:

Registreringen är stängd och

Antingen deadline har passerat eller eventet är fullsatt.

Flyttar alla ETH från eventets kassa till organisatören.

🔸 getEventInfo(uint256 eventId) (view)

Returnerar info om eventet:

organisatörens adress

namn

biljettpris

userLimit

deadline

om det är öppet/stängt

antal sålda biljetter

balanserade ETH i eventet

🔸 getParticipants(uint256 eventId) (view)

Returnerar en lista över alla registrerade adresser för eventet.

🔸 isRegistered(uint256 eventId, address user) (view)

Kollar om en viss adress (user) är registrerad på eventet.

🔸 nextEventId (view, variabel)

Räknare som visar hur många event som hittills har skapats.

Används också för att veta vilket ID nästa event får.

Exempel: om nextEventId == 2, så finns event 0 och 1 redan.