import { ethers } from 'hardhat';
import { expect } from 'chai';
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { BigNumber } from 'ethers';

function eth(value: string): BigNumber { return ethers.utils.parseEther(value); }
function sendEth (value: string): {value: BigNumber} { return {value: eth(value)}; }

describe("Multi-signature wallet", function() {

    async function deployMyContractFixture() {
        const REQUIRED_NUM_SIGNERS = 2;
        const MyContract = await ethers.getContractFactory("MyContract");
        const [owner, signer0, signer1, signer2, ...clients] = await ethers.getSigners();
        const addrClients = clients.map(client => client.address);
        const contract = await MyContract.deploy([signer0.address, signer1.address, signer2.address], REQUIRED_NUM_SIGNERS);

        return {owner, signer0, signer1, signer2, clients, addrClients, contract};
    }

    describe('Deployment', function() {
        it("Should have the right addresses set for signers", async function() {
            const { contract, signer0, signer1, signer2 } = await loadFixture(deployMyContractFixture);
            expect(await contract.getCompanySigners()).to.have.members([signer0.address, signer1.address, signer2.address]);
        });

        it("should not have the member of a signer after it's been removed", async function() {
            const { contract, signer0, signer1, signer2 } = await loadFixture(deployMyContractFixture);
            await contract.removeSigner(signer1.address);
            expect(await contract.getCompanySigners()).to.have.members([signer0.address, signer2.address])
            .and.not.include.members([signer1.address]);
        });
    });

    describe('Minting and transferring', function() {
        async function mintNftFixture() {
            const fixture = await loadFixture(deployMyContractFixture);
            await fixture.contract.safeMintWithApproved(fixture.clients[0].address, 111, eth('1'), fixture.signer1.address);
            return fixture;
        }

        it("Should mint an NFT", async function() {
            const {contract} = await loadFixture(mintNftFixture);
            expect(await contract.contains(111)).to.be.true;
        });

        it("Should send funds to an NFT", async function() {
            const {contract, signer0, clients} = await loadFixture(mintNftFixture);
            const [client] = clients; 
            await contract.connect(signer0).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await contract.connect(client).deposit(111, sendEth('1'));
            const amountPaid = await contract.amountPaidFor(111);
            expect(amountPaid).to.equal(eth('1'));
        });

        it("Should transfer an NFT", async function() {
            const {contract, signer0, clients} = await loadFixture(mintNftFixture);
            const [client] = clients; 
            // Each transaction requires validation
            await contract.connect(signer0).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await contract.connect(client).deposit(111, sendEth('1'));
            // second validation for transfer
            await contract.connect(signer0).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await contract.safeTransfer(111);

            expect(await contract.ownerOf(111)).to.equal(client.address);
        });
        
        it("Should transfer an NFT with approved signer", async function() {
            const {contract, signer1, clients} = await loadFixture(mintNftFixture);
            const [client] = clients; 
            // Each transaction requires validation
            await contract.connect(signer1).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await contract.connect(client).deposit(111, sendEth('1'));
            // second validation for transfer
            await contract.connect(signer1).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await contract.connect(signer1).safeTransfer(111);

            expect(await contract.ownerOf(111)).to.equal(client.address);
        });

        it("Should revert transfer of NFT with unapproved signer", async function() {
            const {contract, signer0, signer1, clients} = await loadFixture(mintNftFixture);
            const [client] = clients; 
            // Each transaction requires validation
            await contract.connect(signer1).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await contract.connect(client).deposit(111, sendEth('1'));
            // second validation for transfer
            await contract.connect(signer1).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await expect(contract.connect(signer0).safeTransfer(111)).to.be.revertedWith("ERC721: caller is not token owner nor approved");

        });

        it("Should revert transfer of NFT", async function() {
            const {contract, signer0, clients} = await loadFixture(mintNftFixture);
            const [client] = clients; 
            // Each transaction requires validation
            await contract.connect(signer0).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await contract.connect(client).deposit(111, sendEth('0.5'));
            // second validation for transfer
            await contract.connect(signer0).signTransaction(111);
            await contract.connect(client).signTransaction(111);
            await expect(contract.safeTransfer(111)).to.be.revertedWith("loan not paid off");

        });
        
    });
});