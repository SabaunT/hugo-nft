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
            HugoNFT.new(
                "",
                versionOneAttributesAmount,
                "some python script",
                Array(versionOneAttributesAmount).fill(4),
                Array(versionOneAttributesAmount).fill(Array(4).fill("aaaa")),
                Array(versionOneAttributesAmount).fill(Array(4).fill(rarity.UNCOMMON)),
                Array(versionOneAttributesAmount).fill(exampleCID1),
                {from: owner})
        )
        // zero attributes amount
        await expectThrow(
            HugoNFT.new(
                tokenURI,
                0,
                "some python script",
                Array(versionOneAttributesAmount).fill(4),
                Array(versionOneAttributesAmount).fill(Array(4).fill("aaaa")),
                Array(versionOneAttributesAmount).fill(Array(4).fill(rarity.UNCOMMON)),
                Array(versionOneAttributesAmount).fill(exampleCID1),
                {from: owner})
        )
        // empty generator script
        await expectThrow(
            HugoNFT.new(
                tokenURI,
                versionOneAttributesAmount,
                "",
                Array(versionOneAttributesAmount).fill(4),
                Array(versionOneAttributesAmount).fill(Array(4).fill("aaaa")),
                Array(versionOneAttributesAmount).fill(Array(4).fill(rarity.UNCOMMON)),
                Array(versionOneAttributesAmount).fill(exampleCID1),
                {from: owner})
        )
        // disproportion in attributes and traits input data lengths
        await expectThrow(
            HugoNFT.new(
                tokenURI,
                versionOneAttributesAmount,
                "some python script",
                Array(2).fill(4),
                Array(versionOneAttributesAmount).fill(Array(4).fill("aaaa")),
                Array(versionOneAttributesAmount).fill(Array(4).fill(rarity.UNCOMMON)),
                Array(versionOneAttributesAmount).fill(exampleCID1),
                {from: owner})
        )
        await expectThrow(
            HugoNFT.new(
                tokenURI,
                versionOneAttributesAmount,
                "some python script",
                Array(versionOneAttributesAmount).fill(4),
                Array(6).fill(Array(4).fill("aaaa")),
                Array(versionOneAttributesAmount).fill(Array(4).fill(rarity.UNCOMMON)),
                Array(versionOneAttributesAmount).fill(exampleCID1),
                {from: owner})
        )

        nftContract = await HugoNFT.new(
            tokenURI,
            versionOneAttributesAmount,
            "some python script",
            Array(versionOneAttributesAmount).fill(3),
            [
                Array(3).fill("Head trait"),
                Array(3).fill("Glasses trait"),
                Array(3).fill("Body trait"),
                Array(3).fill("Shirt trait"),
                Array(3).fill("Scarf trait")
            ],
            Array(versionOneAttributesAmount).fill(Array(3).fill(rarity.UNCOMMON)),
            Array(versionOneAttributesAmount).fill(exampleCID1),
            {from: owner});

        // Granting roles
        await nftContract.grantRole(NFT_ADMIN_ROLE, nft_admin, {from: owner});
        await nftContract.grantRole(MINTER_ROLE, minter, {from: owner});
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
            let validCIDsArray = Array(versionOneAttributesAmount).fill(exampleCID2);
            // let attribute id 2 CID be empty
            validCIDsArray[2] = "";
            await nftContract.updateMultipleAttributesCIDs(validCIDsArray, {from: nft_admin})

            let CIDsOfAttrId1 = await nftContract.getCIDsOfAttribute(1);
            let CIDsOfAttrId2 = await nftContract.getCIDsOfAttribute(2);

            let lastCIDs = await nftContract.validCIDs();
            let validCIDAttr1 = lastCIDs[1];
            let validCIDAttr2 = lastCIDs[2];

            assert.equal(CIDsOfAttrId1.length, 2)
            assert.equal(CIDsOfAttrId2.length, 1)
            assert.equal(validCIDAttr1, exampleCID2)
            assert.equal(validCIDAttr2, exampleCID1)
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

            let CIDsOfAttrId2 = await nftContract.getCIDsOfAttribute(2);
            let validCIDAttr2 = CIDsOfAttrId2[CIDsOfAttrId2.length - 1];

            assert.equal(CIDsOfAttrId2.length, 2)
            assert.equal(validCIDAttr2, exampleCID2)
        })

        it("updating CIDs with an array of empty strings", async() => {
            let emptyCIDsData = Array(versionOneAttributesAmount).fill("");
            await nftContract.updateMultipleAttributesCIDs(emptyCIDsData, {from: nft_admin});

            // update shouldn't have brought changes
            let attr0CIDs = await nftContract.getCIDsOfAttribute(0);
            assert.equal(attr0CIDs.length, 2);
        })

        it("adding multiple traits", async() => {
            // invalid access
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    10,
                    Array(10).fill("ab"),
                    Array(10).fill(rarity.COMMON),
                    exampleCID1,
                    {from: account1}
                )
            )
            // invalid traits length (over maximum)
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    26,
                    Array(10).fill("ab"),
                    Array(10).fill(rarity.COMMON),
                    exampleCID1,
                    {from: nft_admin}
                )
            )
            // disproportion in trait data length (ids array != name array and e.t.c.)
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    25,
                    Array(10).fill("ab"),
                    Array(10).fill(rarity.COMMON),
                    exampleCID1,
                    {from: nft_admin}
                )
            )
            await expectThrow(
                nftContract.addTraits(
                    HEAD_ID,
                    10,
                    Array(10).fill("ab"),
                    Array(5).fill(rarity.COMMON),
                    exampleCID1,
                    {from: nft_admin}
                )
            )

            // Add multiple traits
            await nftContract.addTraits(
                HEAD_ID,
                3,
                Array(3).fill("Head trait"),
                Array(3).fill(rarity.UNCOMMON),
                exampleCID1,
                {from: nft_admin}
            )
            await nftContract.addTraits(
                GLASSES_ID,
                3,
                Array(3).fill("Glasses trait"),
                Array(3).fill(rarity.UNCOMMON),
                exampleCID1,
                {from: nft_admin}
            )
            await nftContract.addTraits(
                BODY_ID,
                3,
                Array(3).fill("Body trait"),
                Array(3).fill(rarity.UNCOMMON),
                exampleCID1,
                {from: nft_admin}
            )
            await nftContract.addTraits(
                SHIRT_ID,
                3,
                Array(3).fill("Shirt trait"),
                Array(3).fill(rarity.UNCOMMON),
                exampleCID1,
                {from: nft_admin}
            )
            await nftContract.addTraits(
                SCARF_ID,
                3,
                Array(3).fill("Scarf trait"),
                Array(3).fill(rarity.UNCOMMON),
                exampleCID1,
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
        })

        it("add traits by one", async() => {
            // invalid attribute id
            await expectThrow(
                nftContract.addTrait(5, 7, "TTT", rarity.LEGENDARY, exampleCID2, {from: nft_admin})
            )
            // trait id spoils sequence (1,2,3,4,5,6,8 )
            await expectThrow(
                nftContract.addTrait(HEAD_ID, 8, "TTT", rarity.LEGENDARY, exampleCID2, {from: nft_admin})
            )
            // empty name
            await expectThrow(
                nftContract.addTrait(HEAD_ID, 7, "", rarity.LEGENDARY, exampleCID2, {from: nft_admin})
            )
            // invalid access
            await expectThrow(
                nftContract.addTrait(HEAD_ID, 7, "Classical Hat", rarity.UNCOMMON, exampleCID2, {from: account1})
            )

            await nftContract.addTrait(HEAD_ID, 7, "Classical Hat", rarity.UNCOMMON, exampleCID2, {from: nft_admin});
            await nftContract.addTrait(GLASSES_ID, 7,  "RayBan", rarity.COMMON, exampleCID2, {from: nft_admin});
            await nftContract.addTrait(BODY_ID, 7, "Muscular", rarity.UNCOMMON, exampleCID2, {from: nft_admin});
            await nftContract.addTrait(SHIRT_ID, 7, "Tuxedo", rarity.UNCOMMON, exampleCID2, {from: nft_admin});
            await nftContract.addTrait(SCARF_ID, 7, "Gryffindor", rarity.RARE, exampleCID2, {from: nft_admin});

            let traitsOfAttribute0 = await nftContract.getTraitsOfAttribute(HEAD_ID);
            let traitsOfAttribute1 = await nftContract.getTraitsOfAttribute(GLASSES_ID);
            let traitsOfAttribute2 = await nftContract.getTraitsOfAttribute(BODY_ID);
            let traitsOfAttribute3 = await nftContract.getTraitsOfAttribute(SHIRT_ID);
            let traitsOfAttribute4 = await nftContract.getTraitsOfAttribute(SCARF_ID);

            assert.equal(traitsOfAttribute0.length, 7);
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
                nftContract.mint(zeroAddress, [5, 5, 5, 5, 5], "some name", "some descr", {from: minter})
            )
            // Seed is invalid: too short
            await expectThrow(
                nftContract.mint(account1, [1, 2, 1, 1], "some name", "some descr", {from: minter})
            )
            // Seed is invalid: too long
            await expectThrow(
                nftContract.mint(account1, [1, 2, 1, 1, 1, 2], "some name", "some descr", {from: minter})
            )
            // Seed is invalid: unexistent trait id
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 5, 8], "some name", "some descr", {from: minter})
            )
            // Seed is invalid: zero id for core attribute
            await expectThrow(
                nftContract.mint(account1, [5, 5, 5, 7, 0], "some name", "some descr", {from: minter})
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

            // Seed is invalid: minting with the same seed
            await expectThrow(
                nftContract.mint(account2, [1, 1, 1, 1, 1], "John Coffey copy", "Like John Coffey, but copy", {from: minter})
            )

            await nftContract.mint(account1, [2, 2, 2, 2, 2], "Albert", "Why do people think I'm Einstein?", {from: minter});
            await nftContract.mint(account1, [3, 3, 3, 3, 7], "Cristiano", "Yes, I'm CR-7", {from: minter});

            let totalSupply = await nftContract.totalSupply();
            let nftIdsOfAccount1 = await getTokenIdsOfAccount(account1);

            assert.equal(totalSupply.toNumber(), 3)
            assertEqArrays([0,1,2], nftIdsOfAccount1)
        })

        it("adding new attribute and minting", async() => {
            // invalid access
            await expectThrow(
                nftContract.addNewAttributeWithTraits(
                    3,
                    Array(3).fill("Eyes trait"),
                    Array(3).fill(rarity.UNCOMMON),
                    exampleCID2,
                    {from: minter}
                )
            )
            await nftContract.addNewAttributeWithTraits(
                3,
                Array(3).fill("Eyes trait"),
                [rarity.COMMON, rarity.UNCOMMON, rarity.RARE],
                exampleCID2,
                {from: nft_admin}
            )
            let traitsOfEyeAttribute = await nftContract.getTraitsOfAttribute(EYE_ID);
            let attributesAmount = await nftContract.attributesAmount();

            assert.equal(traitsOfEyeAttribute.length, 3);
            assert.equal(attributesAmount.toNumber(), versionTwoAttributesAmount);

            // can mint with an old type seed
            await nftContract.mint(account2, [1, 2, 3, 4, 5], "test", "test", {from: minter})
            // can't mint because hash for [1, 2, 3, 4, 5, 0] is a hash([1, 2, 3, 4, 5])
            await expectThrow(
                nftContract.mint(account2, [1, 2, 3, 4, 5, 0], "test", "test", {from: minter})
            )
            // can't mint because [1,1,1,1,1] was minted for account1
            await expectThrow(
                nftContract.mint(account2, [1, 1, 1, 1, 1, 0], "test", "test", {from: minter})
            )
            // can mint with 0 id for a new trait id
            await nftContract.mint(account2, [1, 2, 3, 4, 4, 0], "test", "test", {from: minter})
            // invalid trait id for an eye attribute
            await expectThrow(
                nftContract.mint(account2, [1, 2, 3, 4, 5, 4], "test", "test", {from: minter})
            )

            await nftContract.mint(account2, [1, 2, 3, 4, 5, 3], "test", "test", {from: minter})
            await nftContract.mint(account2, [2, 2, 3, 4, 5, 3], "test", "test", {from: minter})

            let totalSupply = await nftContract.totalSupply();
            let nftIdsOfAccount2 = await getTokenIdsOfAccount(account2);

            assert.equal(totalSupply.toNumber(), 7);
            assertEqArrays([3, 4, 5, 6], nftIdsOfAccount2);
        })

        it("minting with a one more attribute to test gaps in seed", async() => {
            await nftContract.addNewAttributeWithTraits(
                3,
                Array(3).fill("Background trait"),
                [rarity.COMMON, rarity.UNCOMMON, rarity.RARE],
                exampleCID1,
                {from: nft_admin}
            )

            await nftContract.mint(account1, [1,2,3,4,5,3,3], "test", "test", {from: minter})
            await nftContract.mint(account1, [3,3,1,2,1,0,0], "test", "test", {from: minter})
            // possible to have gaps
            await nftContract.mint(account1, [3,3,1,2,1,0,2], "test", "test", {from: minter})
            // Duplicates
            await expectThrow(
                nftContract.mint(account1, [3,3,1,2,1,0,2], "test", "test", {from: minter})
            )
            await expectThrow(
                nftContract.mint(account1, [3,3,1,2,1,0,2], "test", "test", {from: minter})
            )

            let totalSupply = await nftContract.totalSupply();
            let nftIdsOfAccount1 = await getTokenIdsOfAccount(account1);

            assert.equal(totalSupply.toNumber(), 10);
            assertEqArrays([0,1,2,7,8,9], nftIdsOfAccount1);
        })

        it("can mint exclusive", async() => {
            // invalid access
            await expectThrow(
                nftContract.mintExclusive(account1, "some name", "some descr", exampleCID1, {from: nft_admin})
            )
            // invalid name length (empty string)
            await expectThrow(
                nftContract.mintExclusive(account1, "", "some descr", exampleCID1, {from: minter})
            )
            // invalid descr length (empty string)
            await expectThrow(
                nftContract.mintExclusive(account1, "some name", "", exampleCID1, {from: minter})
            )
            // invalid name length (too long string). Array(77).join("a") gives 76 char string
            await expectThrow(
                nftContract.mintExclusive(account1, Array(77).join("a"), "some descr", exampleCID1, {from: minter})
            )
            // invalid descr length (too long string). Array(302).join("a") gives 301 char string
            await expectThrow(
                nftContract.mintExclusive(account1, "some name", Array(302).join("a"), exampleCID1, {from: minter})
            )
            // minting to zero address
            await expectThrow(
                nftContract.mintExclusive(zeroAddress, "some name", "some descr", exampleCID1, {from: minter})
            )
            // invalid CID length
            await expectThrow(
                nftContract.mintExclusive(account1, "some name", "some descr", "some invalid CID", {from: minter})
            )

            // mint 3 exclusive
            await nftContract.mintExclusive(account1, "some name", "some descr", exampleCID2, {from: minter})
            await nftContract.mintExclusive(account2, "some name", "some descr", exampleCID2, {from: minter})
            await nftContract.mintExclusive(account3, "some name", "some descr", exampleCID2, {from: minter})

            let totalSupply = await nftContract.totalSupply();
            let nftIdsOfAccount1 = await getTokenIdsOfAccount(account1);
            let nftIdsOfAccount2 = await getTokenIdsOfAccount(account2);
            let nftIdsOfAccount3 = await getTokenIdsOfAccount(account3);

            let exclusivelyMinted = await nftContract.exclusiveNFTsAmount();

            assert.equal(totalSupply.toNumber(), 13);
            assertEqArrays([0, 1, 2, 7, 8, 9, 10000], nftIdsOfAccount1);
            assertEqArrays([3, 4, 5, 6, 10001], nftIdsOfAccount2);
            assertEqArrays([10002], nftIdsOfAccount3);
            assert.equal(exclusivelyMinted.toNumber(), 3)
        })
    })

    describe("Change nft name/description tests", async() => {
        it("changes nft name", async() => {
            // invalid access
            await expectThrow(
                nftContract.changeNFTName(1, "new name", {from: account1})
            )
            // non existent token
            await expectThrow(
                nftContract.changeNFTName(10, "new name", {from: nft_admin})
            )
            // empty string
            await expectThrow(
                nftContract.changeNFTName(1, "", {from: nft_admin})
            )
            // too long string
            await expectThrow(
                nftContract.changeNFTName(1, Array(77).join("a"), {from: nft_admin})
            )

            await nftContract.changeNFTName(1, "Some new name", {from: nft_admin});
            await nftContract.changeNFTName(10000, "Some new name as well", {from: nft_admin});

            let nft1 = await nftContract.getNFT(1);
            let nft2 = await nftContract.getNFT(10000);

            assert.equal(nft1.name, "Some new name");
            assert.equal(nft2.name, "Some new name as well");
        })

        it("changes nft descriptions", async() => {
            // invalid access
            await expectThrow(
                nftContract.changeNFTDescription(1, "new description", {from: account1})
            )
            // non existent token
            await expectThrow(
                nftContract.changeNFTDescription(10, "new description", {from: nft_admin})
            )
            // empty string
            await expectThrow(
                nftContract.changeNFTDescription(1, "", {from: nft_admin})
            )
            // too long string
            await expectThrow(
                nftContract.changeNFTDescription(1, Array(302).join("a"), {from: nft_admin})
            )

            await nftContract.changeNFTDescription(1, "Some new description", {from: nft_admin});
            await nftContract.changeNFTDescription(10000, "Some new description as well", {from: nft_admin});

            let nft1 = await nftContract.getNFT(1);
            let nft2 = await nftContract.getNFT(10000);

            assert.equal(nft1.description, "Some new description");
            assert.equal(nft2.description, "Some new description as well");
        })
    })

    // // todo test throws
    // describe("Info fns tests", async() => {
    //     it("getting CIDs for an attribute", async() => {
    //         // invalid attribute id
    //         await expectThrow(
    //             nftContract.getCIDsOfAttribute(6)
    //         )
    //         // When trait for EYE attribute was added, we didn't update the CID
    //         let CIDsOfEye = await nftContract.getCIDsOfAttribute(5);
    //         let lastEyeCID = CIDsOfEye[CIDsOfEye.length - 1];
    //         let CIDsOfScarf = await nftContract.getCIDsOfAttribute(4);
    //         let lastScarfCID = CIDsOfScarf[CIDsOfScarf.length - 1];
    //
    //         assert.ok(!lastEyeCID.isValid);
    //         assert.ok(lastScarfCID.isValid);
    //     })
    //
    //     it("getting traits of an attribute", async() => {
    //         // invalid attribute id
    //         await expectThrow(
    //             nftContract.getTraitsOfAttribute(6)
    //         )
    //         let traitsOfEye = await nftContract.getTraitsOfAttribute(5);
    //         assert.equal(traitsOfEye.length, 4);
    //     })
    //
    //     it("checking seed is used", async() => {
    //         // Read fn docs to understand why it returns an error with such seeds
    //         await expectThrow(
    //             nftContract.isUsedSeed([1, 1, 1, 1, 1])
    //         )
    //         await expectThrow(
    //             nftContract.isUsedSeed([1, 1, 1, 1, 1, 5])
    //         )
    //         await expectThrow(
    //             nftContract.isUsedSeed([1, 1, 1, 1, 1, 0])
    //         )
    //         let isUsed1 = await nftContract.isUsedSeed([3, 1, 2, 1, 1,  4])
    //         let isUsed2 = await nftContract.isUsedSeed([1, 2, 3, 4, 5, 3])
    //
    //         // not used
    //         assert.ok(!isUsed1)
    //         // used
    //         assert.ok(isUsed2)
    //     })
    //
    //     it("generated token seeds minted with different amount of attributes have same sizes", async() => {
    //         let nft1 = await nftContract.getGeneratedToken(1);
    //         // was minted after attribute was added
    //         let nft2 = await nftContract.getGeneratedToken(3);
    //         assert.equal(nft1.length, nft2.length)
    //     })
    //     // todo test NFTs exlusive have empty seed, generated ones have empty cid
    //     it("get trait CID address", async() => {
    //         // invalid attribute id
    //         await expectThrow(
    //             nftContract.traitIpfsPath(6, 3)
    //         )
    //         // invalid trait id
    //         await expectThrow(
    //             nftContract.traitIpfsPath(HEAD_ID, 0)
    //         )
    //         await expectThrow(
    //             nftContract.traitIpfsPath(EYE_ID, 5)
    //         )
    //         let trait1Address = await nftContract.traitIpfsPath(HEAD_ID, 3);
    //         assert.equal("ipfs://".concat(exampleCID1, "/", "3"), trait1Address);
    //         // When trait for EYE attribute was added, we didn't update the CID
    //         let trait2Address = await nftContract.traitIpfsPath(EYE_ID, 1);
    //         assert.equal(trait2Address, "");
    //     })
    // })
})
