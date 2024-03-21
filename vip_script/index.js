const { VIPUtils } = require("./VIPUtils");

async function main() {
  const utils = new VIPUtils();
  const users = []; // user list
  const amounts = []; // amount list
  await utils.addVIP({ users: users, amounts: amounts });
}

main().catch((err) => {
  console.log(err);
});
