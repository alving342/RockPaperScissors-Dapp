const hre = require("hardhat");

async function main() {
  const ethers = hre.ethers;

  const [p1, p2] = await ethers.getSigners();

  console.log("P1:", p1.address);
  console.log("P2:", p2.address);

  const RPS = await ethers.getContractFactory("RockPaperScissors");
  const rps = await RPS.deploy();
  await rps.waitForDeployment();
  console.log("Deployed at:", rps.target);

  const bet = ethers.parseEther("1");
  await (await rps.connect(p1).createGame(p2.address, { value: bet })).wait();
  await (await rps.connect(p2).joinGame(0, { value: bet })).wait();

  console.log("Game created + joined.");

  const move1 = 3;
  const salt1 = ethers.encodeBytes32String("s1");
  const commit1 = ethers.keccak256(ethers.solidityPacked(["uint8", "bytes32"], [move1, salt1]));

  const move2 = 2;
  const salt2 = ethers.encodeBytes32String("s2");
  const commit2 = ethers.keccak256(ethers.solidityPacked(["uint8", "bytes32"], [move2, salt2]));

  await (await rps.connect(p1).commitMove(0, commit1)).wait();
  await (await rps.connect(p2).commitMove(0, commit2)).wait();
  console.log("Moves committed.");

  await (await rps.connect(p1).revealMove(0, move1, salt1)).wait();
  await (await rps.connect(p2).revealMove(0, move2, salt2)).wait();
  console.log("Moves revealed.");

  console.log("Balances:");
  console.log("  p1 balance:", ethers.formatEther(await rps.balances(p1.address)));
  console.log("  p2 balance:", ethers.formatEther(await rps.balances(p2.address)));

  await (await rps.connect(p1).withdraw()).wait();
  console.log("P1 withdrew winnings.");

  console.log("Final P1 ETH:", ethers.formatEther(await ethers.provider.getBalance(p1.address)));
  console.log("\nDone (v3).");
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
