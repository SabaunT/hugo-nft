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

    const rarity = {
        COMMON: 0,
        UNCOMMON: 1,
        RARE: 2,
        LEGENDARY: 3,
    }

    const versionOneTokenURI = "someURI";
    const versionOneAttributesAmount = 5;

    const zeroAddress = "0x0000000000000000000000000000000000000000";

    let nftContract;

    before("Deploying NFT contract", async() => {
        // todo check with throws
        nftContract = await HugoNFT.new(versionOneTokenURI, versionOneAttributesAmount, {from: owner});

        // adding some traits
        await nftContract.addTrait(HEAD_ID, "Classical Hat", rarity.UNCOMMON);
        await nftContract.addTrait(GLASSES_ID, "RayBan", rarity.COMMON);
        await nftContract.addTrait(BODY_ID, "Muscular", rarity.UNCOMMON);
        await nftContract.addTrait(SHIRT_ID, "Tuxedo", rarity.UNCOMMON);
        await nftContract.addTrait(SCARF_ID, "Gryffindor", rarity.RARE);

        await nftContract.addTrait(HEAD_ID, "Punk", rarity.UNCOMMON);
        await nftContract.addTrait(GLASSES_ID, "Polaroid", rarity.RARE);
        await nftContract.addTrait(BODY_ID, "Thin", rarity.COMMON);
        await nftContract.addTrait(SHIRT_ID, "Raped", rarity.COMMON);
        await nftContract.addTrait(SCARF_ID, "Slytherin", rarity.RARE);
    })

    it("Mints token for account1", async() => {
        // todo check with throws
        await nftContract.mint(account1, [0, 0, 1, 1, 0], "Cute Hugo", "Cute hugo minted for the test");
        let tokenInfo = await nftContract.getTokenInfo(0);
        console.log(tokenInfo.seed);
    })

    it("Mints exclusive token for account2", async() => {
        // todo check with throws
        await nftContract.mintExclusive(account2);
        let seedOfToken1 = await nftContract.getTokenSeed(1);
        console.log(seedOfToken1); //empty
    })




})
