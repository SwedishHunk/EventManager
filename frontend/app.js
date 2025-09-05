// === Enkel dApp-klient för EventManager ===
// Kräver att sidan redan har laddat ethers via CDN (window.ethers)
// och att HTML:en innehåller inputs/knappar med rätt id:n.

(async function main() {
  if (!window.ethereum) {
    alert("Installera MetaMask för att använda dAppen.");
    return;
  }

  await ethereum.request({ method: "eth_requestAccounts" });

  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer   = await provider.getSigner();

  // Byt till din kontraktsadress
  const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

  // Minimal ABI för funktionerna vi använder
  const ABI = [
    "function createEvent(string name_, uint256 ticketPrice_, uint256 userLimit_, uint256 deadline_) external returns (uint256)",
    "function openRegistration(uint256 eventId) external",
    "function closeRegistration(uint256 eventId) external",
    "function register(uint256 eventId) external payable",
    "function withdraw(uint256 eventId) external",
    "function getEventInfo(uint256 eventId) external view returns (address,string,uint256,uint256,uint256,uint8,uint256,uint256)",
    "function getParticipants(uint256 eventId) external view returns (address[])",
    "function isRegistered(uint256 eventId, address user) external view returns (bool)"
  ];

  const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);

  // --- Hjälpare ---
  const $   = (id) => document.getElementById(id);
  const out = (msg) => {
    console.log(msg);
    const el = $("out");
    if (el) el.textContent = String(msg);
  };
  const nowSec = () => Math.floor(Date.now() / 1000);

  async function waitAndReport(tx) {
    out(`⏳ Skickade tx: ${tx.hash}`);
    const rc = await tx.wait();
    out(`✅ Klar i block ${rc.blockNumber} – tx: ${rc.hash}`);
    return rc;
  }

  async function getTicketPriceWei(eventId) {
    // getEventInfo returns: (organizer,name,ticketPrice,userLimit,deadline,state,sold,balance)
    const info = await contract.getEventInfo(eventId);
    return info[2]; // ticketPrice
  }

  // --- Event listeners (koppling till knapparna) ---

  // Create Event
  $("btnCreateEvent")?.addEventListener("click", async () => {
    try {
      const name     = $("eventName").value.trim();
      const priceWei = $("ticketPrice").value; // redan i wei (helsträng/nummer)
      const limit    = $("userLimit").value;
      const deadline = $("deadline").value || (nowSec() + 7 * 24 * 3600); // default +7d

      if (!name) return out("Ange ett namn.");

      const tx = await contract.createEvent(name, priceWei, limit, deadline);
      await waitAndReport(tx);
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

  // Open Registration
  $("btnOpenRegistration")?.addEventListener("click", async () => {
    try {
      const id = $("openEventId").value;
      const tx = await contract.openRegistration(id);
      await waitAndReport(tx);
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

  // Close Registration
  $("btnCloseRegistration")?.addEventListener("click", async () => {
    try {
      const id = $("closeEventId").value;
      const tx = await contract.closeRegistration(id);
      await waitAndReport(tx);
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

  // Buy Ticket (register) – skickar automatiskt korrekt value = ticketPrice
  $("btnBuyTicket")?.addEventListener("click", async () => {
    try {
      const id = $("buyEventId").value;
      const priceWei = await getTicketPriceWei(id);
      const tx = await contract.register(id, { value: priceWei });
      await waitAndReport(tx);
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

  // Get Event Info
  $("btnGetEventInfo")?.addEventListener("click", async () => {
    try {
      const id = $("infoEventId").value;
      const [organizer, name, ticketPrice, userLimit, deadline, state, sold, balance] =
        await contract.getEventInfo(id);

      out(
        [
          `Organizer: ${organizer}`,
          `Name: ${name}`,
          `Ticket price (wei): ${ticketPrice}`,
          `User limit: ${userLimit}`,
          `Deadline: ${deadline} (${new Date(Number(deadline) * 1000).toLocaleString()})`,
          `State: ${Number(state) === 1 ? "Open" : "Closed"}`,
          `Sold: ${sold}`,
          `Balance (wei): ${balance}`
        ].join("\n")
      );
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

  // Get Participants
  $("btnGetParticipants")?.addEventListener("click", async () => {
    try {
      const id = $("participantsEventId").value;
      const list = await contract.getParticipants(id);
      out(`Participants (${list.length}):\n${list.join("\n")}`);
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

  // Check Participant
  $("btnCheckParticipant")?.addEventListener("click", async () => {
    try {
      const id  = $("checkEventId").value;
      const adr = $("checkAddress").value.trim();
      const reg = await contract.isRegistered(id, adr);
      out(`${adr} registered: ${reg}`);
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

  // Withdraw
  $("btnWithdraw")?.addEventListener("click", async () => {
    try {
      const id = $("withdrawEventId").value;
      const tx = await contract.withdraw(id);
      await waitAndReport(tx);
    } catch (e) { out(`❌ ${e?.shortMessage || e?.message || e}`); }
  });

})();
