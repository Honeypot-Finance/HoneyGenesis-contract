const ethers = require("ethers");
require("dotenv").config({ path: ".env" });

class VIPUtils {
  provider;
  wallet;
  contract_address;

  constructor() {
    this.provider = new ethers.JsonRpcProvider(process.env.ETH_RPC_URL);
    this.wallet = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
    this.contract_address = process.env.NFT_ADDRESS;
    // console.log(process.env.ETH_RPC_URL);
    // console.log(process.env.PRIVATE_KEY);
  }

  hi() {
    console.log("hi");
  }

  async addVIP(addVIPRequest) {
    const abi = [
      "function incrementVIPMintQuota(address[] calldata user,uint256[] calldata amount)",
    ];

    try {
      const contractHandle = new ethers.Contract(
        this.contract_address,
        abi,
        this.provider
      );
      let increseTx = await contractHandle
        .connect(this.wallet)
        .incrementVIPMintQuota(addVIPRequest.users, addVIPRequest.amounts);

      // wait comfirmations
      await increseTx.wait(10);

      // record tx hash
      const txHash = increseTx.hash;
      console.log(`req=>${addVIPRequest},txHash=>${txHash}`);
      return txHash;
    } catch (error) {
      console.error(`req=>${addVIPRequest},error=>${error}`);
    }
  }
}

module.exports = {
  VIPUtils,
};
