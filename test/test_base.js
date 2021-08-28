const HugoNFT = artifacts.require("HugoNFT");
const { BN } = require('@openzeppelin/test-helpers');

// todo check cap reached
contract('HugoNFT', async(accounts) => {
    function range(size, startAt = 0) {
        return [...Array(size).keys()].map(i => i + startAt);
    }

    async function getTokenIdsOfAccount(account) {
        let retIds = [];
        let idsBN = await nftContract.tokenIdsOfOwner.call(account);
        idsBN.forEach(bnNum => retIds.push(bnNum.toNumber()));
        return retIds;
    }

    function assertEqArrays(expected, actual) {
        expect(expected).to.deep.eq(actual)
    }

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
    const nft_admin = accounts[3];
    const minter = accounts[4];
    const owner = accounts[5];

    const HEAD_ID = 0;
    const GLASSES_ID = 1;
    const BODY_ID = 2;
    const SHIRT_ID = 3;
    const SCARF_ID = 4;
    const EYE_ID = 5;

    const rarity = {
        COMMON: 0,
        UNCOMMON: 1,
        RARE: 2,
        LEGENDARY: 3,
    }

    const tokenURI = "someURI";
    const versionOneAttributesAmount = 5;
    const versionTwoAttributesAmount = 6;

    const zeroAddress = "0x0000000000000000000000000000000000000000";
    const exampleCID1 = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
    const exampleCID2 = "QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco";

    const NFT_ADMIN_ROLE = "0xd4dd364b99254967de7b77fa79c0f7835d1d5ebdb779edee0c386bda7d2cc482";
    const MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6"

    let nftContract;

    before("Deploying and configurating NFT contract", async() => {
        // empty URI string
        await expectThrow(
            HugoNFT.new("", versionOneAttributesAmount, "some python script", {from: owner})
        )
        // zero attributes amount
        await expectThrow(
            HugoNFT.new(tokenURI, 0, "some python script", {from: owner})
        )
        // empty generator script
        await expectThrow(
            HugoNFT.new(tokenURI, versionOneAttributesAmount, "", {from: owner})
        )
        nftContract = await HugoNFT.new(tokenURI, versionOneAttributesAmount, "some python script", {from: owner});

        // Granting roles
        await nftContract.grantRole(NFT_ADMIN_ROLE, nft_admin, {from: owner});
        await nftContract.grantRole(MINTER_ROLE, minter, {from: owner});
    })

    it("Mints token for account1 fails - paused state", async() => {
        // Contract is in paused state, so you can't call mint fns.
        await expectThrow(
            nftContract.mint(account1, [1, 1, 1, 1, 1], "Cute Hugo", "Cute hugo minted for the test", {from: minter})
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
                nftContract.updateMultipleAttributesCIDs(["1", "2", "3", "4", "5", "6"], {from: nft_admin})
            )
            // invalid length of CID itself
            await expectThrow(
                nftContract.updateMultipleAttributesCIDs(invalidCIDLenData, {from: nft_admin})
            )
            let validCIDsArray = Array(versionOneAttributesAmount).fill(exampleCID1);
            // let attribute id 2 CID be empty
            validCIDsArray[2] = "";
            await nftContract.updateMultipleAttributesCIDs(validCIDsArray, {from: nft_admin})

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
                nftContract.updateAttributeCID(5, exampleCID2, {from: nft_admin})
            )
            // invalid CID length
            await expectThrow(
                nftContract.updateAttributeCID(2, "someInvalidSeed", {from: nft_admin})
            )
            await nftContract.updateAttributeCID(2, exampleCID2, {from: nft_admin})

            let isPaused = await nftContract.isPaused();
            assert.ok(!isPaused);
        })

        it("updating CIDs with an array of empty strings", async() => {
            let emptyCIDsData = Array(versionOneAttributesAmount).fill("");
            await nftContract.updateMultipleAttributesCIDs(emptyCIDsData, {from: nft_admin});

            // update shouldn't have brought changes
            let attr0CIDs = await nftContract.getCIDsOfAttribute(0);
            assert.equal(attr0CIDs.length, 1);
        })

        it("adding multiple traits", async() => {
            // invalid access
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    range(10, 1),
                    Array(10).fill("ab"),
                    Array(10).fill(rarity.COMMON),
                    {from: account1}
                )
            )
            // invalid traits length (over maximum)
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    range(26, 1),
                    Array(10).fill("ab"),
                    Array(10).fill(rarity.COMMON),
                    {from: nft_admin}
                )
            )
            // disproportion in trait data length (ids array != name array and e.t.c.)
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    range(25, 1),
                    Array(10).fill("ab"),
                    Array(10).fill(rarity.COMMON),
                    {from: nft_admin}
                )
            )
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    range(10, 1),
                    Array(10).fill("ab"),
                    Array(5).fill(rarity.COMMON),
                    {from: nft_admin}
                )
            )
            // adding trait with a reserved id = 0
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    range(10, 0),
                    Array(10).fill("ab"),
                    Array(10).fill(rarity.COMMON),
                    {from: nft_admin}
                )
            )

            // Add multiple traits
            await nftContract.addTraits(
                HEAD_ID,
                range(3, 1),
                Array(3).fill("Head trait"),
                Array(3).fill(rarity.UNCOMMON),
                {from: nft_admin}
            )
            await nftContract.addTraits(
                GLASSES_ID,
                range(3, 1),
                Array(3).fill("Glasses trait"),
                Array(3).fill(rarity.UNCOMMON),
                {from: nft_admin}
            )
            await nftContract.addTraits(
                BODY_ID,
                range(3, 1),
                Array(3).fill("Body trait"),
                Array(3).fill(rarity.UNCOMMON),
                {from: nft_admin}
            )
            await nftContract.addTraits(
                SHIRT_ID,
                range(3, 1),
                Array(3).fill("Shirt trait"),
                Array(3).fill(rarity.UNCOMMON),
                {from: nft_admin}
            )
            await nftContract.addTraits(
                SCARF_ID,
                range(3, 1),
                Array(3).fill("Scarf trait"),
                Array(3).fill(rarity.UNCOMMON),
                {from: nft_admin}
            )

            let traitsOfAttribute0 = await nftContract.getTraitsOfAttribute(HEAD_ID);
            let traitsOfAttribute1 = await nftContract.getTraitsOfAttribute(GLASSES_ID);
            let traitsOfAttribute2 = await nftContract.getTraitsOfAttribute(SHIRT_ID);
            let traitsOfAttribute3 = await nftContract.getTraitsOfAttribute(BODY_ID);
            let traitsOfAttribute4 = await nftContract.getTraitsOfAttribute(SCARF_ID);

            let equalLength =
                !!traitsOfAttribute0.length &&
                !!traitsOfAttribute1.length &&
                !!traitsOfAttribute2.length &&
                !!traitsOfAttribute3.length &&
                !!traitsOfAttribute4.length;

            assert.ok(equalLength);

            let isPause = await nftContract.isPaused();
            assert.ok(isPause);
        })

        it("add traits by one", async() => {
            // invalid attribute id
            await expectThrow(
                nftContract.addTrait(5, 4, "TTT", rarity.LEGENDARY, {from: nft_admin})
            )
            // trait id spoils sequence (1,2,3, 5 )
            await expectThrow(
                nftContract.addTrait(HEAD_ID, 5, "TTT", rarity.LEGENDARY, {from: nft_admin})
            )
            // empty name
            await expectThrow(
                nftContract.addTrait(HEAD_ID, 4, "", rarity.LEGENDARY, {from: nft_admin})
            )
            // invalid access
            await expectThrow(
                nftContract.addTrait(HEAD_ID, 4, "Classical Hat", rarity.UNCOMMON, {from: account1})
            )

            await nftContract.addTrait(HEAD_ID, 4, "Classical Hat", rarity.UNCOMMON, {from: nft_admin});
            await nftContract.addTrait(GLASSES_ID, 4,  "RayBan", rarity.COMMON, {from: nft_admin});
            await nftContract.addTrait(BODY_ID, 4, "Muscular", rarity.UNCOMMON, {from: nft_admin});
            await nftContract.addTrait(SHIRT_ID, 4, "Tuxedo", rarity.UNCOMMON, {from: nft_admin});
            await nftContract.addTrait(SCARF_ID, 4, "Gryffindor", rarity.RARE, {from: nft_admin});

            let traitsOfAttribute0 = await nftContract.getTraitsOfAttribute(HEAD_ID);
            assert.equal(traitsOfAttribute0.length, 4);

            let isPause = await nftContract.isPaused();
            assert.ok(isPause);
        })

        it("update CIDs after adding traits", async() => {
            let validCIDsArray = Array(versionOneAttributesAmount).fill(exampleCID2);
            await nftContract.updateMultipleAttributesCIDs(validCIDsArray, {from: nft_admin})

            let isPause = await nftContract.isPaused();
            // is not paused
            assert.ok(!isPause);
        })

        it("updating CIDs for 4 of 5 changed attributes still leaves a pause", async() => {
            await nftContract.addTrait(HEAD_ID, 5, "Punk", rarity.UNCOMMON, {from: nft_admin});
            await nftContract.addTrait(GLASSES_ID, 5, "Polaroid", rarity.RARE, {from: nft_admin});
            await nftContract.addTrait(BODY_ID, 5, "Thin", rarity.COMMON, {from: nft_admin});
            await nftContract.addTrait(SHIRT_ID, 5, "Raped", rarity.COMMON, {from: nft_admin});
            await nftContract.addTrait(SCARF_ID, 5, "Slytherin", rarity.RARE, {from: nft_admin});

            let isPause = await nftContract.isPaused();
            assert.ok(isPause);

            let validCIDsArray = Array(versionOneAttributesAmount).fill(exampleCID1);
            // let attribute id 4 CID be empty
            validCIDsArray[4] = "";
            await nftContract.updateMultipleAttributesCIDs(validCIDsArray, {from: nft_admin})

            isPause = await nftContract.isPaused();
            assert.ok(isPause);
        })

        it("updating the last CID unpauses contract", async() => {
            await nftContract.updateAttributeCID(4, exampleCID1, {from: nft_admin});
            let isPause = await nftContract.isPaused();
            // is not paused
            assert.ok(!isPause);
        })
    })

    describe("Minting tests", async() => {
        it("mint new generative nft", async() => {
            // test for minting in a pause state was done previously
            // invalid access
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 5, 5], "some name", "some descr", {from: account1})
            )
            // mint to address 0
            await expectThrow(
                nftContract.mint(zeroAddress, [5, 5, 5, 5, 5], "some name", "some descr", {from: account1})
            )
            // Seed is invalid: wrong length
            await expectThrow(
                nftContract.mint(account1, [1, 2, 1, 1], "some name", "some descr", {from: minter})
            )
            // Seed is invalid: invalid trait id
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 5, 6], "some name", "some descr", {from: minter})
            )
            // invalid name length (empty string)
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 5, 5], "", "some descr", {from: minter})
            )
            // invalid descr length (empty string)
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 5, 5], "some name", "", {from: minter})
            )
            // invalid name length (too long string). Array(77).join("a") gives 76 char string
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 5, 5], Array(77).join("a"), "some descr", {from: minter})
            )
            // invalid descr length (too long string). Array(302).join("a") gives 301 char string
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 5, 5], "some name", Array(302).join("a"), {from: minter})
            )

            // Mint 3 tokens
            await nftContract.mint(account1, [1, 1, 1, 1, 1], "John Coffey", "Like a drink, but it is written differently", {from: minter});

            // Seed is invalid: mintint with the same seed
            await expectThrow(
                nftContract.mint(account2, [1, 1, 1, 1, 1], "John Coffey copy", "Like John Coffey, but copy", {from: minter})
            )

            await nftContract.mint(account1, [2, 2, 2, 2, 2], "Albert", "Why do people think I'm Einstein?", {from: minter});
            await nftContract.mint(account1, [3, 3, 3, 3, 3], "Cristiano", "Yes, I'm CR-7", {from: minter});

            let totalSupply = await nftContract.totalSupply();
            let nftIdsOfAccount1 = await getTokenIdsOfAccount(account1);

            assert.equal(totalSupply.toNumber(), 3)
            assertEqArrays([0,1,2], nftIdsOfAccount1)
        })

        // todo test adding a new attribute within minting process
        it("adding new attribute and minting", async() => {
            // invalid access
            await expectThrow(
                nftContract.addNewAttributeWithTraits(
                    range(3, 1),
                    Array(3).fill("Eyes trait"),
                    Array(3).fill(rarity.UNCOMMON),
                    {from: minter}
                )
            )
            // using reserved trait id
            await expectThrow(
                nftContract.addNewAttributeWithTraits(
                    range(3, 0),
                    Array(3).fill("Eyes trait"),
                    Array(3).fill(rarity.UNCOMMON),
                    {from: nft_admin}
                )
            )
            await nftContract.addNewAttributeWithTraits(
                range(3, 1),
                Array(3).fill("Eyes trait"),
                [rarity.COMMON, rarity.UNCOMMON, rarity.RARE],
                {from: nft_admin}
            )
            let traitsOfEyeAttribute = await nftContract.getTraitsOfAttribute(EYE_ID);
            let isPause = await nftContract.isPaused();
            let attributesAmount = await nftContract.amountOfAttributes();

            assert.equal(traitsOfEyeAttribute.length, 3);
            assert.ok(isPause);
            assert.equal(attributesAmount.toNumber(), versionTwoAttributesAmount);

            // Can't, because is paused
            await expectThrow(
                nftContract.mint(account1, [1, 2, 3, 4, 5, 1], "test", "test", {from: minter})
            )

            await nftContract.updateAttributeCID(EYE_ID, exampleCID1, {from: nft_admin});
            isPause = await nftContract.isPaused();

            // old type seed
            await expectThrow(
                nftContract.mint(account1, [1, 2, 3, 4, 5], "test", "test", {from: minter})
            )
            // invalid trait id
            await expectThrow(
                nftContract.mint(account1, [1, 2, 3, 4, 5, 4], "test", "test", {from: minter})
            )
            await expectThrow(
                nftContract.mint(account1, [1, 2, 3, 4, 5, 0], "test", "test", {from: minter})
            )

            await nftContract.mint(account2, [1, 2, 3, 4, 5, 3], "test", "test", {from: minter})

            let totalSupply = await nftContract.totalSupply();
            let nftIdsOfAccount2 = await getTokenIdsOfAccount(account2);

            // isn't paused
            assert.ok(!isPause);
            assert.equal(totalSupply.toNumber(), 4);
            assertEqArrays([3], nftIdsOfAccount2);
        })
    })

    describe("Minting exclusive tests", async() => {
        it("can mint exclusive when paused", async() => {
            await nftContract.addTrait(EYE_ID, 4, "New trait", rarity.LEGENDARY, {from: nft_admin});
            let isPause = await nftContract.isPaused();

            // invalid access
            await expectThrow(
                nftContract.mintExclusive(account1, "some name", "some descr", {from: nft_admin})
            )
            // invalid name length (empty string)
            await expectThrow(
                nftContract.mintExclusive(account1, "", "some descr", {from: minter})
            )
            // invalid descr length (empty string)
            await expectThrow(
                nftContract.mintExclusive(account1, "some name", "", {from: minter})
            )
            // invalid name length (too long string). Array(77).join("a") gives 76 char string
            await expectThrow(
                nftContract.mintExclusive(account1, Array(77).join("a"), "some descr", {from: minter})
            )
            // invalid descr length (too long string). Array(302).join("a") gives 301 char string
            await expectThrow(
                nftContract.mintExclusive(account1, "some name", Array(302).join("a"), {from: minter})
            )
            await expectThrow(
                nftContract.mintExclusive(zeroAddress, "some name", "some descr", {from: minter})
            )

            // mint 3 exclusive
            await nftContract.mintExclusive(account1, "some name", "some descr", {from: minter})
            await nftContract.mintExclusive(account2, "some name", "some descr", {from: minter})
            await nftContract.mintExclusive(account3, "some name", "some descr", {from: minter})

            let totalSupply = await nftContract.totalSupply();
            let nftIdsOfAccount1 = await getTokenIdsOfAccount(account1);
            let nftIdsOfAccount2 = await getTokenIdsOfAccount(account2);
            let nftIdsOfAccount3 = await getTokenIdsOfAccount(account3);

            let exclusivelyMinted = await nftContract.exclusiveNFTsAmount();

            assert.ok(isPause);
            assert.equal(totalSupply.toNumber(), 7);
            assertEqArrays([0, 1, 2, 10000], nftIdsOfAccount1);
            assertEqArrays([3, 10001], nftIdsOfAccount2);
            assertEqArrays([10002], nftIdsOfAccount3);
            assert.equal(exclusivelyMinted.toNumber(), 3)
        })
    })

    describe("Change nft name/description tests", async() => {
        it("changes generated and exclusive tokens names", async() => {
            // not owned token
            await expectThrow(
                nftContract.changeNFTName(10, "new name", {from: account1})
            )
            // empty string
            await expectThrow(
                nftContract.changeNFTName(1, "", {from: account1})
            )
            // too long string
            await expectThrow(
                nftContract.changeNFTName(1, Array(77).join("a"), {from: account1})
            )

            await nftContract.changeNFTName(1, "Some new name", {from: account1});
            await nftContract.changeNFTName(10000, "Some new name as well", {from: account1});

            let nft1 = await nftContract.getGeneratedToken(1);
            let nft2 = await nftContract.getExclusiveToken(10000);

            assert.equal(nft1.name, "Some new name");
            assert.equal(nft2.name, "Some new name as well");
        })

        it("changes generated and exclusive tokens descriptions", async() => {
            // not owned token
            await expectThrow(
                nftContract.changeNFTDescription(10, "new description", {from: account1})
            )
            // empty string
            await expectThrow(
                nftContract.changeNFTDescription(1, "", {from: account1})
            )
            // too long string
            await expectThrow(
                nftContract.changeNFTDescription(1, Array(302).join("a"), {from: account1})
            )

            await nftContract.changeNFTDescription(1, "Some new description", {from: account1});
            await nftContract.changeNFTDescription(10000, "Some new description as well", {from: account1});

            let nft1 = await nftContract.getGeneratedToken(1);
            let nft2 = await nftContract.getExclusiveToken(10000);

            assert.equal(nft1.description, "Some new description");
            assert.equal(nft2.description, "Some new description as well");
        })
    })

    describe("Info fns tests", async() => {
        it("generated token seeds minted with different amount of attributes have same sizes", async() => {
            let nft1 = await nftContract.getGeneratedToken(1);
            // was minted after attribute was added
            let nft2 = await nftContract.getGeneratedToken(3);
            assert.equal(nft1.length, nft2.length)
        })
    })
})
