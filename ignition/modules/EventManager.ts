import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("EventModule", (m) => {
  const eventManager = m.contract("EventManager");

  return { eventManager };
});
