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

#shows all acounts
npx hardhat node

#shows contract address
npx hardhat ignition deploy ignition/modules/RPSModule.js --network localhost
```

# to run script
```shell
#run this in 1 terminal
npx hardhat node

#then run this in a second terminal
npx hardhat run scripts/playRound.js --network localhost
```
# to run index.html
```shell
#first I downloaded live server extension. once downloaded I right click index.html and open with live Server. 
#then in the html page there are a few boxes to fill out. I have metamask installed and create 2 separate imported accounts using the accounts shown from npx hardhat node. first I connect metamask and make sure the account address shown is the account address i want to start with. then I copy the contract address from npx hardhat ignition deploy ignition/modules/RPSModule.js --network localhost copy the opponent address from account 2 in metamask. then i create the game and switch my metamask to account 2 and connect once more with metamask. then i go to join game. once there i am able to choose between rock, papaer, or scissors. then i have to switch again to account 1 and connect with metamask to choose again between rock, papaer, or scissors. then i click reveal move and switch and repeat with account 2. once both are revealed i can see the winner and wothdraw the transaction 
