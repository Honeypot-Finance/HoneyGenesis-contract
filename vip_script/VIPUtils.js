const ethers = require("ethers");
require("dotenv").config({ path: ".env" });

class VIPUtils {
  provider;
  wallet;

  constructor() {
    this.provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    this.wallet = new ethers.Wallet(process.env.PRIVATE_KEY, this.provider);
  }

  hi() {
    console.log("hi");
  }

  async addVIP(contractAddress, addVIPRequest) {
    const abi = [
      "function incrementVIPMintQuota(address[] calldata user,uint256[] calldata amount)",
    ];
    try {
      const contractHandle = new ethers.Contract(
        contractAddress,
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
