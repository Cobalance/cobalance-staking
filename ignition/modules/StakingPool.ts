import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakingPoolModule = buildModule("StakingPoolModule", (m) => {

  const stakingPool = m.contract("StakingPool");
  return { stakingPool };

});

export default StakingPoolModule;