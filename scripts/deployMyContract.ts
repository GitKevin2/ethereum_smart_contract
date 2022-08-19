import { ethers } from "hardhat";
import { eth, sendEth } from "./helpers/currency";

async function start() {
    const REQUIRED_NUM_SIGNERS = 2;
    const MyContract = await ethers.getContractFactory('MyContract');
    const [_, signer0, signer1, ...clients] = await ethers.getSigners();
    const clientAddrs = clients.map(client => client.address);
    const [client] = clients;
    const signerAddrs = [signer0.address, signer1.address];
    const contract = await MyContract.deploy(signerAddrs, REQUIRED_NUM_SIGNERS);
    await contract.deployed();
    await contract.safeMint(clientAddrs[0], 111, eth('1'));
    console.log("owner: ", await contract.ownerOf(111));
    await contract.connect(signer0).signTransaction(111);
    await contract.connect(client).signTransaction(111);
    await contract.connect(client).deposit(111, sendEth('1'));
    await contract.connect(signer0).signTransaction(111);
    await contract.connect(client).signTransaction(111);
    await contract.safeTransfer(111);
    console.log("owner: ", await contract.ownerOf(111));
}

start()
.then(() => process.exit(0))
.catch(err => {
    console.error(err)
    process.exit(1);
});