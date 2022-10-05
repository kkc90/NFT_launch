async function main() {
    const vrf = await ethers.getContractAt("VRFTest", "0x7fe144ed7929DD5ee112293bA38A309921a44619");
    console.log("Last Request Id:", await vrf.lastRequestId());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
