import { BigNumber } from "ethers";
import { ethers } from "hardhat";

/**Converts string value as ether into amount in wei. */
export function eth(value: string): BigNumber { return ethers.utils.parseEther(value); }

/**Returns an object for sending payment to the smart contract. */
export function sendEth(value: string): {value: BigNumber} { return {value: eth(value)} }
