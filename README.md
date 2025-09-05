
<h1>EventPlanner Contract</h1>
<i>“Utveckla ett kontrakt för att hantera anmälningar till ett evenemang. Användare kan registrera sig genom att betala en avgift, och registreringen ska stängas när en viss gräns är nådd, eller att en deadline har passerat. Kontraktet ska innehålla funktioner för att registrera ett nytt evenemang, öppna och stänga registreringen, anmälan till evenemanget, hantering av betalning, samt en lista över alla registrerade deltagare per evenemang.”</i>

<p>Vi har utvecklat ett <b>smart kontrakt</b> som vi valt att kalla <b>"EventPlanner"</b>, eftersom det låter organisatörer skapa evenemang där deltagare kan registrera sig genom att betala en biljettavgift. Varje evenemang har en deadline när biljettförsäljningen stängs, och dessutom kan biljetterna sälja slut för evenemangen har ett maxantal biljetter. Så Eventet kan ha status Open (for sale), Closed (not for sale) och Finished (sold out). Deltagare registreras så länge eventet är öppet, inte fullt och inom tidsgränsen.

<br /> Organisatören kan öppna eller stänga registrering, och när event är klart kan organisatören ta ut de insamlade medlen. Kontraktet håller koll på deltagare, betalningar och loggar händelser för transparens.

<br /> Med <b>custom modifiers</b> såg vi till att ägaren måste va msg.sender, bara organiseraren får leta upp events, eventet måste existera, biljettköp måste vara öppet. </p>

<br />Några viktiga funktioner vi behövde var att kunna <b>skapa evenemang</b>(med <b>require</b> att alla viktiga fält fylls i), <b>registrera dig</b> för evenemang (kontrollera så användaren inte redan finns, så att den betalat, så att den blir registrerad, stäng funktion automatiskt när det är fullbokat/passerat deadline), <b>öppna registrering</b> (endast om det ej är fullbokat/passerat deadline), <b>stäng registrering</b> (endast om du är organisatör), <b>lista deltagare</b> (assert för att säkerställa att antalet deltagare stämmer), <b>ta ut pengar som tjänats</b> (endast om det är fullbokat/passerat deadline), <b>hämta eventinformation</b>, <b>kolla om användare är registrerad</b>.

<br />