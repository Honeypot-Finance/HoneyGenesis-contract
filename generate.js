const fs = require("fs");

const generateMetadata = (totalTokens) => {
  const metadataList = [];

  for (let i = 1; i <= totalTokens; i++) {
    const metadata = {
      name: `HoneyGenesis #${i}`,
      description:
        "HoneyGenesis is the Gen-0 series NFT from honeypot finance team which helps the owner gain unique honeypot finance perks.",
      image:
        "https://bafkreifj2vyb3s77yrafreyoupk4ghjoyqsxiqoot2wjzev5tfstpjeqlm.ipfs.nftstorage.link",
      attributes: [
        { trait_type: "bear", value: "pot the bera" },
        { trait_type: "generation", value: "zero" },
        { trait_type: "nickname", value: "HoneyPotOG" },
      ],
    };

    metadataList.push(metadata);
  }

  return metadataList;
};

const saveMetadataToFile = (metadataList) => {
  const directory = "./metadata";

  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory);
  }

  metadataList.forEach((metadata, index) => {
    fs.writeFile(
      `${directory}/${index + 1}`,
      JSON.stringify(metadata, null, 2),
      (err) => {
        if (err) {
          console.error("Error writing file:", err);
        } else {
          console.log(
            `Metadata for HoneyGenesis #${index + 1} written successfully`
          );
        }
      }
    );
  });
};

const main = () => {
  const totalTokens = 6000;
  const metadataList = generateMetadata(totalTokens);
  saveMetadataToFile(metadataList);
};

main();
