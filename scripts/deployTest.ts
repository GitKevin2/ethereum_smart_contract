import {ethers} from 'hardhat'
import {eth} from './helpers/currency'

/** compare operations of contract */
async function main() {
    const NodeListContract1 = await ethers.getContractFactory("NodeListContract1");
    const NodeListContract2 = await ethers.getContractFactory("NodeListContract2");
    const signers = await ethers.getSigners();
    const addrs = signers.map(signer => signer.address); //length: 20
    const usedAddrs = [addrs[0], addrs[1], addrs[2]]; //length: 3
    const contract1 = await NodeListContract1.deploy(addrs);
    const contract2 = await NodeListContract2.deploy(addrs);
    const gasPrice = (await contract1.gasPrice()).toNumber();
    let c1Gas: number, c2Gas: number;
    await contract1.deployed();
    await contract2.deployed();

    console.log("number of owners:", addrs.length);
    console.log("Compare gas started with:");
    console.log("contract 1:", (await contract1.gasInit()).toNumber());
    console.log("contract 2:", (await contract2.gasInit()).toNumber());

    console.log("Compare gas used:");
    console.log("contract 1:", c1Gas = (await contract1.gasUsed()).toNumber());
    console.log("contract 2:", c2Gas = (await contract2.gasUsed()).toNumber());
    console.log("Difference:", Math.abs(c1Gas - c2Gas));

    console.log("Compare gas left:");
    console.log("contract 1:", (await contract1.gasLeft()).toNumber());
    console.log("contract 2:", (await contract2.gasLeft()).toNumber());

    console.log("Compare gas price:");
    console.log("contract 1:", c1Gas * gasPrice);
    console.log("contract 2:", c2Gas * gasPrice);
}

main()
.then(() => process.exit(0))
.catch(err => {
    console.error(err);
    process.exit(1);
});


