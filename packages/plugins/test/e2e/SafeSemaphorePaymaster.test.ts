import { expect } from "chai";
import { ethers } from "hardhat";
import {
  SafeECDSAFactory__factory,
  SafeECDSAPlugin__factory,
  SemaphoreVerifier__factory,
  SemaphorePaymaster__factory,
  PoapSemaphoreGatekeeper__factory,
  EntryPoint__factory,
  PoseidonT3__factory,
  Semaphore__factory,
} from "../../typechain-types";
import receiptOf from "./utils/receiptOf";
import { setupTests } from "./utils/setupTests";
import { createAndSendUserOpWithEcdsaSig } from "./utils/createUserOp";
import { Identity } from "@semaphore-protocol/identity"
import { SemaphoreEthers } from "@semaphore-protocol/data"
import { Group } from "@semaphore-protocol/group"
import { generateProof } from "@semaphore-protocol/proof"
import { getSigners } from "./utils/getSigners";

const oneEther = ethers.parseEther("1");

describe.only("SafeSemaphorePaymaster", () => {
  it("should pass the ERC4337 validation", async () => {
    const {
      bundlerProvider,
      provider,
      admin,
      owner,
      entryPointAddress,
      deployer,
      safeSingleton,
    } = await setupTests();

    // Deploy semaphore.
    const semaphoreVerifier = await new SemaphoreVerifier__factory(admin).deploy()
    await semaphoreVerifier.waitForDeployment()
    const semaphoreVerifierAddress = await semaphoreVerifier.getAddress()

    const poseidonT3 = await new PoseidonT3__factory(admin).deploy()
    await poseidonT3.waitForDeployment()
    const poseidonT3Address = await poseidonT3.getAddress()

    const semaphore = await new Semaphore__factory({
      "poseidon-solidity/PoseidonT3.sol:PoseidonT3": poseidonT3Address,
    }, admin).deploy(semaphoreVerifierAddress)
    await semaphore.waitForDeployment()
    const semaphoreAddress = await semaphore.getAddress()

    // Deploy paymaster.
    const paymaster = await new SemaphorePaymaster__factory(admin).deploy(entryPointAddress, semaphoreAddress, 0)
    await paymaster.waitForDeployment();
    const paymasterAddress = await paymaster.getAddress();
    
    // Paymaster deposits.
    await paymaster.deposit({ value: oneEther })
    
    // Paymaster stakes.
    await paymaster.connect(admin).addStake(1, { value: oneEther })

    // Deploy Semaphore gatekeeper.
    const gatekeeper = await new PoapSemaphoreGatekeeper__factory(admin).deploy(semaphoreAddress)
    await gatekeeper.waitForDeployment()
    const gatekeeperAddress = await gatekeeper.getAddress()

    // Create Semaphore group.
    await gatekeeper.init()
    
    // Create Semaphore identity.
    const identity1 = new Identity()
    const identity2 = new Identity()

    // Join Semaphore group with the identity.
    await gatekeeper.enter(0, identity1.commitment);
    await gatekeeper.enter(0, identity2.commitment);

    // Mimic the Semaphore group and generate proof.
    const group = new Group()
    group.addMember(identity1.commitment)
    group.addMember(identity2.commitment)
    
    const proof = await generateProof(identity1, group, "msg", "scope") // `message` and `scope` are not used.

    // Deploy ecdsa plugin
    const safeECDSAFactory = await deployer.connectOrDeploy(
      SafeECDSAFactory__factory,
      [],
    );

    const createArgs = [
      safeSingleton,
      entryPointAddress,
      await owner.getAddress(),
      0,
    ] satisfies Parameters<typeof safeECDSAFactory.create.staticCall>;

    const accountAddress = await safeECDSAFactory.create.staticCall(
      ...createArgs,
    );

    await receiptOf(safeECDSAFactory.create(...createArgs));

    const safeEcdsaPlugin = SafeECDSAPlugin__factory.connect(
      accountAddress,
      owner,
    );
    
    // Native tokens for the pre-fund
    await receiptOf(
      admin.sendTransaction({
        to: accountAddress,
        value: oneEther,
      }),
    );

    // Construct userOp
    const recipient = ethers.Wallet.createRandom();
    const transferAmount = oneEther;
    const userOpCallData = safeEcdsaPlugin.interface.encodeFunctionData(
      "execTransaction",
      [recipient.address, transferAmount, "0x00"],
    );
    const dummySignature = await owner.signMessage("dummy sig");

    // Note: factoryParams is not used because we need to create both the safe
    // proxy and the plugin, and 4337 currently only allows one contract
    // creation in this step. Since we need an extra step anyway, it's simpler
    // to do the whole create outside of 4337.
    const factoryParams = {
      factory: "0x",
      factoryData: "0x",
    };

    // Check paymaster balances before and after sending UserOp.
    const entrypoint = EntryPoint__factory.connect(entryPointAddress, provider)
    const paymasterBalanceBefore = await entrypoint.balanceOf(paymasterAddress)

    // Send userOp
    const validUntil = 0;
    const validAfter = 0;
    const signature = ethers.AbiCoder.defaultAbiCoder().encode(
      ['uint48', 'uint48', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256[8]'],
      [validUntil, validAfter, proof.merkleTreeDepth, proof.merkleTreeRoot, proof.nullifier, proof.message, proof.scope, proof.points]
    )
    console.log(signature)
    
    /*
    */

    await createAndSendUserOpWithEcdsaSig(
      provider,
      bundlerProvider,
      owner,
      accountAddress,
      factoryParams,
      userOpCallData,
      entryPointAddress,
      dummySignature,
      paymasterAddress,
      3e5,
      signature
    );

    const paymasterBalanceAfter = await entrypoint.balanceOf(paymasterAddress)

    expect(paymasterBalanceBefore).greaterThan(paymasterBalanceAfter)
    expect(await provider.getBalance(recipient.address)).to.equal(oneEther);
  });
});
