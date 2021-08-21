const HugoNFT = artifacts.require("HugoNFT");

contract('HugoNFT', async(accounts) => {
    let expectThrow = async (promise) => {
        try {
            await promise;
        } catch (error) {
            const invalidOpcode = error.message.search('invalid opcode') >= 0;
            const outOfGas = error.message.search('out of gas') >= 0;
            const revert = error.message.search('revert') >= 0;
            assert(
                invalidOpcode || outOfGas || revert,
                "Expected throw, got '" + error + "' instead",
            );
          return;
        }
        assert.fail('Expected throw not received');
    };

    let takeSnapshot = () => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_snapshot',
            id: new Date().getTime()
          }, (err, snapshotId) => {
            if (err) { return reject(err) }
            return resolve(snapshotId)
          })
        })
    };

    let revertToSnapShot = (id) => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send({
            jsonrpc: '2.0',
            method: 'evm_revert',
            params: [id],
            id: new Date().getTime()
          }, (err, result) => {
            if (err) { return reject(err) }
            return resolve(result)
          })
        })
    }

    const account1 = accounts[0];
    const account2 = accounts[1];
    const account3 = accounts[2];
    const account4 = accounts[3];
    const owner = accounts[4];

    const HEAD_ID = 0;
    const GLASSES_ID = 1;
    const BODY_ID = 2;
    const SHIRT_ID = 3;
    const SCARF_ID = 4;

    const versionOneTokenURI = "someURI";
    const versionOneAttributesAmount = 5;

    const zeroAddress = "0x0000000000000000000000000000000000000000";

    let nftContract;

    before("Deploying NFT contract", async() => {
        // todo check with throws
        nftContract = await HugoNFT.new(versionOneTokenURI, versionOneAttributesAmount, {from: owner});

        // adding some traits
        await nftContract.addTrait(HEAD_ID, "Classical Hat", 10);
        await nftContract.addTrait(GLASSES_ID, "RayBan", 10);
        await nftContract.addTrait(BODY_ID, "Muscular", 10);
        await nftContract.addTrait(SHIRT_ID, "Tuxedo", 10);
        await nftContract.addTrait(SCARF_ID, "Gryffindor", 10);

        await nftContract.addTrait(HEAD_ID, "Punk", 10);
        await nftContract.addTrait(GLASSES_ID, "Polaroid", 10);
        await nftContract.addTrait(BODY_ID, "Thin", 10);
        await nftContract.addTrait(SHIRT_ID, "Raped", 10);
        await nftContract.addTrait(SCARF_ID, "Slytherin", 10);
    })

    it("Mints token for account1", async() => {
        // todo check with throws
        await nftContract.mint(account1, [0, 0, 1, 1, 0]);
        let seedOfToken0 = await nftContract.getTokenSeed(0);
        console.log(seedOfToken0);
    })

})
