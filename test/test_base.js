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

    const account1 = accounts[0];
    const account2 = accounts[1];
    const account3 = accounts[2];
    const NFT_ADMIN = accounts[3];
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
    const exampleCID1 = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
    const exampleCID2 = "QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco";

    const NFT_ADMIN_ROLE = "0xd4dd364b99254967de7b77fa79c0f7835d1d5ebdb779edee0c386bda7d2cc482";

    let nftContract;

    before("Deploying and configurating NFT contract", async() => {
        // empty URI string
        await expectThrow(
            HugoNFT.new("", versionOneAttributesAmount, "some python script", {from: owner})
        )
        // zero attributes amount
        await expectThrow(
            HugoNFT.new(versionOneTokenURI, 0, "some python script", {from: owner})
        )
        // empty generator script
        await expectThrow(
            HugoNFT.new(versionOneTokenURI, versionOneAttributesAmount, "", {from: owner})
        )
        nftContract = await HugoNFT.new(versionOneTokenURI, versionOneAttributesAmount, "some python script", {from: owner});

        // Granting roles
        await nftContract.grantRole(NFT_ADMIN_ROLE, NFT_ADMIN, {from: owner});

        // // adding some traits
        // await nftContract.addTrait(HEAD_ID, "Classical Hat", rarity.UNCOMMON);
        // await nftContract.addTrait(GLASSES_ID, "RayBan", rarity.COMMON);
        // await nftContract.addTrait(BODY_ID, "Muscular", rarity.UNCOMMON);
        // await nftContract.addTrait(SHIRT_ID, "Tuxedo", rarity.UNCOMMON);
        // await nftContract.addTrait(SCARF_ID, "Gryffindor", rarity.RARE);
        //
        // await nftContract.addTrait(HEAD_ID, "Punk", rarity.UNCOMMON);
        // await nftContract.addTrait(GLASSES_ID, "Polaroid", rarity.RARE);
        // await nftContract.addTrait(BODY_ID, "Thin", rarity.COMMON);
        // await nftContract.addTrait(SHIRT_ID, "Raped", rarity.COMMON);
        // await nftContract.addTrait(SCARF_ID, "Slytherin", rarity.RARE);
    })

    it("Mints token for account1 fails - paused state", async() => {
        // Contract is in paused state, so you can't call mint fns.
        await expectThrow(
            nftContract.mint(account1, [0, 0, 1, 1, 0], "Cute Hugo", "Cute hugo minted for the test")
        )
        let isPaused = await nftContract.isPaused();
        assert.ok(isPaused);
    })

    describe("Managing attributes, traits and attributes CIDs", async() => {
        it("updating attributes ipfs CID", async() => {
            let emptyCIDsData = Array(versionOneAttributesAmount).fill("");
            let invalidCIDLenData = Array(versionOneAttributesAmount).fill("12");
            // invalid access
            await expectThrow(
                nftContract.updateMultipleAttributesCIDs(emptyCIDsData, {from: account3})
            )
            // invalid CIDs data length
            await expectThrow(
                nftContract.updateMultipleAttributesCIDs(["1", "2", "3", "4", "5", "6"], {from: NFT_ADMIN})
            )
            // invalid length of CID itself
            await expectThrow(
                nftContract.updateMultipleAttributesCIDs(invalidCIDLenData, {from: NFT_ADMIN})
            )
            let validCIDsArray = Array(versionOneAttributesAmount).fill(exampleCID1);
            // let attribute id 2 CID be empty
            validCIDsArray[2] = "";
            await nftContract.updateMultipleAttributesCIDs(validCIDsArray, {from: NFT_ADMIN})

            let isPaused = await nftContract.isPaused();
            // paused
            assert.ok(isPaused);
        })

        it("changing CID for an attributeId 2", async() => {
            // invalid access
            await expectThrow(
                nftContract.updateAttributeCID(2, exampleCID2, {from: account3})
            )
            // invalid id
            await expectThrow(
                nftContract.updateAttributeCID(5, exampleCID2, {from: NFT_ADMIN})
            )
            // invalid CID length
            await expectThrow(
                nftContract.updateAttributeCID(2, "someInvalidSeed", {from: NFT_ADMIN})
            )
            await nftContract.updateAttributeCID(2, exampleCID2, {from: NFT_ADMIN})

            let isPaused = await nftContract.isPaused();
            assert.ok(!isPaused);
        })

        it("updating CIDs with an array of empty strings", async() => {
            let emptyCIDsData = Array(versionOneAttributesAmount).fill("");
            await nftContract.updateMultipleAttributesCIDs(emptyCIDsData, {from: NFT_ADMIN});

            // update shouldn't have brought changes
            let attr0CIDs = await nftContract.getCIDsOfAttribute(0);
            assert.equal(attr0CIDs.length, 1);
        })
    })
})
