const hre = require("hardhat");

async function main() {
  const [p1, p2] = await hre.ethers.getSigners();
  console.log("Player 1:", p1.address);
  console.log("Player 2:", p2.address);

  const RPS = await hre.ethers.getContractFactory("RockPaperScissors");
  const rps = await RPS.deploy();
  await rps.waitForDeployment();
  console.log("RockPaperScissors deployed at:", rps.target);

  const bet = hre.ethers.parseEther("1");
  let tx = await rps.connect(p1).createGame(p2.address, { value: bet });
  await tx.wait();
  console.log("Game 0 created by P1 with bet 1 ETH");

  tx = await rps.connect(p2).joinGame(0, { value: bet });
  await tx.wait();
  console.log("P2 joined game 0 and matched bet");

  const g = await rps.games(0);
  console.log("\nStored game[0]:");
  console.log("  player1:", g.player1);
  console.log("  player2:", g.player2);
  console.log("  bet:", hre.ethers.formatEther(g.bet), "ETH");
  console.log("  state (enum):", g.state); // 0=WaitingForPlayer2,1=Committing,2=Revealing,3=Finished

  console.log("\nV1 test script finished successfully.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
