# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```

# use this to run i think
```shell

npx hardhat compile
npx hardhat node
npx hardhat ignition deploy ignition/modules/RPSModule.js --network localhost
```

# to run script
```shell
#run this in 1 terminal
npx hardhat node

#then run this in a second terminal
npx hardhat run scripts/playRound.js --network localhost
