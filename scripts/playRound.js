// script: deploys the contract, plays one full round with commit+reveal,
// and logs game state + balances.

const hre = require("hardhat");

async function main() {
  const ethers = hre.ethers;

  const [p1, p2] = await ethers.getSigners();
  console.log("Player 1:", p1.address);
  console.log("Player 2:", p2.address);

  const RPS = await ethers.getContractFactory("RockPaperScissors");
  const rps = await RPS.deploy();
  await rps.waitForDeployment();
  console.log("RockPaperScissors deployed at:", rps.target);

  const initialP1 = await ethers.provider.getBalance(p1.address);
  const initialP2 = await ethers.provider.getBalance(p2.address);
  console.log("\nInitial balances:");
  console.log("  P1:", ethers.formatEther(initialP1), "ETH");
  console.log("  P2:", ethers.formatEther(initialP2), "ETH");

  const bet = ethers.parseEther("1");
  let tx = await rps.connect(p1).createGame(p2.address, { value: bet });
  await tx.wait();
  console.log("\nGame 0 created by P1 with bet 1 ETH");

  tx = await rps.connect(p2).joinGame(0, { value: bet });
  await tx.wait();
  console.log("P2 joined game 0 and matched bet");

  const move1 = 1;
  const salt1 = ethers.encodeBytes32String("p1-secret");
  const commit1 = ethers.keccak256(
    ethers.solidityPacked(["uint8", "bytes32"], [move1, salt1])
  );

  const move2 = 2; 
  const salt2 = ethers.encodeBytes32String("p2-secret");
  const commit2 = ethers.keccak256(
    ethers.solidityPacked(["uint8", "bytes32"], [move2, salt2])
  );

  tx = await rps.connect(p1).commitMove(0, commit1);
  await tx.wait();
  console.log("\nP1 committed move");

  tx = await rps.connect(p2).commitMove(0, commit2);
  await tx.wait();
  console.log("P2 committed move");

  tx = await rps.connect(p1).revealMove(0, move1, salt1);
  await tx.wait();
  console.log("\nP1 revealed move:", move1, "(Rock)");

  tx = await rps.connect(p2).revealMove(0, move2, salt2);
  await tx.wait();
  console.log("P2 revealed move:", move2, "(Paper)");

  const g = await rps.games(0);
  console.log("\nFinal game[0] state:");
  console.log("  player1:", g.player1);
  console.log("  player2:", g.player2);
  console.log("  bet:", ethers.formatEther(g.bet), "ETH");
  console.log("  p1Move:", g.p1Move.toString()); // 1
  console.log("  p2Move:", g.p2Move.toString()); // 2
  console.log("  state (enum):", g.state.toString()); // 3 = Finished
  console.log("  p1Revealed:", g.p1Revealed);
  console.log("  p2Revealed:", g.p2Revealed);

  const finalP1 = await ethers.provider.getBalance(p1.address);
  const finalP2 = await ethers.provider.getBalance(p2.address);

  console.log("\nFinal balances (after game resolution):");
  console.log("  P1:", ethers.formatEther(finalP1), "ETH");
  console.log("  P2:", ethers.formatEther(finalP2), "ETH");

  console.log("\nNote: P2 should have gained ~1 ETH (pot = 2 * bet),");
  console.log("minus gas fees. P1 should be down 1 ETH plus gas.");
  console.log("\n script finished.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
